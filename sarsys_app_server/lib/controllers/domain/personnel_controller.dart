import 'package:sarsys_app_server/controllers/domain/schemas.dart';
import 'package:sarsys_app_server/controllers/event_source/aggregate_controller.dart';
import 'package:sarsys_domain/sarsys_domain.dart' hide Operation;
import 'package:sarsys_app_server/sarsys_app_server.dart';
import 'package:sarsys_app_server/validation/validation.dart';
import 'package:event_source/event_source.dart';

/// A ResourceController that handles
/// [/api/personnels](http://localhost/api/client.html#/Personnel) requests
class PersonnelController extends AggregateController<PersonnelCommand, Personnel> {
  PersonnelController(
    this.persons,
    this.affiliations,
    PersonnelRepository repository,
    JsonValidation validation,
  ) : super(repository,
            validation: validation,
            readOnly: const [
              'unit',
              'messages',
              'operation',
              'transitions',
            ],
            tag: 'Personnels');

  final PersonRepository persons;
  final AffiliationRepository affiliations;

  @override
  @Operation.get()
  Future<Response> getAll({
    @Bind.query('limit') int limit = 20,
    @Bind.query('offset') int offset = 0,
    @Bind.query('deleted') bool deleted = false,
    @Bind.query('expand') List<String> expand = const [],
  }) async {
    try {
      final aggregates = repository.getAll(
        offset: offset,
        limit: limit,
        deleted: deleted,
      );
      // Merge personnel with person
      return Response.ok(
        toDataPaged(
          repository.count(deleted: deleted),
          offset,
          limit,
          aggregates.map(_shouldExpand(expand) ? merge : toAggregateData).toList(),
        ),
      );
    } on InvalidOperation catch (e) {
      return Response.badRequest(body: e.message);
    } catch (e) {
      return Response.serverError(body: e);
    }
  }

  @override
  @Operation.get('uuid')
  Future<Response> getByUuid(
    @Bind.path('uuid') String uuid, {
    @Bind.query('expand') List<String> expand = const [],
  }) async {
    try {
      if (!await exists(uuid)) {
        return Response.notFound(body: "$aggregateType $uuid not found");
      }
      final aggregate = repository.get(uuid);
      return Response.ok(
        _shouldExpand(expand) ? merge(aggregate) : toAggregateData(aggregate),
      );
    } on InvalidOperation catch (e) {
      return Response.badRequest(body: e.message);
    } catch (e) {
      return Response.serverError(body: e);
    }
  }

  @override
  @Operation('PATCH', 'uuid')
  Future<Response> update(
    @Bind.path('uuid') String uuid,
    @Bind.body() Map<String, dynamic> data,
  ) {
    return super.update(uuid, data..remove('tracking'));
  }

  @override
  @Operation('DELETE', 'uuid')
  Future<Response> delete(
    @Bind.path('uuid') String uuid, {
    @Bind.body() Map<String, dynamic> data,
  }) async {
    final isAssigned = repository.get(uuid, createNew: false)?.data?.elementAt('unit/uuid') != null;
    final hasTracking = repository.get(uuid, createNew: false)?.data?.elementAt('tracking/uuid') != null;
    final response = await super.delete(uuid, data: data);
    return await withResponseWaitForRuleResults(response, expected: {
      PersonnelRemovedFromOperation: 1,
      TrackingDeleted: hasTracking ? 1 : 0,
      PersonnelRemovedFromUnit: isAssigned ? 1 : 0,
    });
  }

  bool _shouldExpand(List<String> expand) {
    if (expand.any((element) => element.toLowerCase() == 'person')) {
      return true;
    }
    if (expand.isNotEmpty) {
      throw "Invalid query parameter 'expand' values: $expand";
    }
    return false;
  }

  /// Merge [Personnel] with [Person]
  Map<String, dynamic> merge(Personnel aggregate) {
    final entry = toAggregateData(aggregate);
    final personnel = entry.elementAt<Map<String, dynamic>>('data');
    final auuid = personnel.elementAt<String>('affiliation/uuid');
    if (auuid != null) {
      final affiliation = affiliations.get(auuid, createNew: false);
      if (affiliation != null) {
        final puuid = affiliation.elementAt<String>('person/uuid');
        if (puuid != null) {
          final person = persons.get(puuid, createNew: false);
          if (person != null) {
            // Do not overwrite personnel.uuid
            personnel.addAll({'person': person.data});
          }
        }
      }
    }
    entry.update('data', (value) => personnel);
    return entry;
  }

  @override
  PersonnelCommand onCreate(Map<String, dynamic> data) => MobilizePersonnel(data);

  @override
  PersonnelCommand onUpdate(Map<String, dynamic> data) => UpdatePersonnelInformation(data);

  @override
  PersonnelCommand onDelete(Map<String, dynamic> data) => DeletePersonnel(data);

  //////////////////////////////////
  // Documentation
  //////////////////////////////////

  @override
  APISchemaObject documentAggregateRoot(APIDocumentContext context) => APISchemaObject.object(
        {
          "uuid": context.schema['UUID']..description = "Unique Personnel id",
          "status": documentStatus(),
          "operation": documentAggregateRef(
            context,
            description: "Operation which this personnel is allocated to",
            defaultType: 'Operation',
          ),
          "unit": documentAggregateRef(
            context,
            description: "Unit which this personnel is assigned to",
            defaultType: 'Unit',
          ),
          "affiliation": documentAggregateRef(
            context,
            description: "Affiliation reference for PII lookup",
            defaultType: 'Affiliation',
          ),
          "tracking": documentAggregateRef(
            context,
            description: "Unique id of tracking object created "
                "for this personnel. Only writable on creation.",
            defaultType: 'Tracking',
          ),
          "transitions": APISchemaObject.array(ofSchema: documentTransition())
            ..isReadOnly = true
            ..description = "State transitions (read only)",
          "messages": APISchemaObject.array(ofSchema: context.schema['Message'])
            ..isReadOnly = true
            ..description = "List of messages added to Personnel",
        },
      )
        ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
        ..required = [
          'uuid',
          'affiliation',
        ];

  APISchemaObject documentTransition() => APISchemaObject.object({
        "status": documentStatus(),
        "timestamp": APISchemaObject.string()
          ..description = "When transition occurred"
          ..format = 'date-time',
      })
        ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed;

  /// Personnel Status - Value Object
  APISchemaObject documentStatus() => APISchemaObject.string()
    ..description = "Personnel status"
    ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
    ..defaultValue = "alerted"
    ..enumerated = [
      'none',
      'alerted',
      'enroute',
      'onscene',
      'leaving',
      'retired',
    ];

  @override
  List<APIParameter> documentOperationParameters(APIDocumentContext context, Operation operation) {
    final parameters = super.documentOperationParameters(context, operation);
    switch (operation.method) {
      case "GET":
        parameters.add(
          APIParameter.query('expand')
            ..description = "Expand response with information from references. Legal values are: 'person'",
        );
        break;
    }
    return parameters;
  }
}
