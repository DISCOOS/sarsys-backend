import 'package:collection_x/collection_x.dart';
import 'package:sarsys_domain/sarsys_domain.dart' hide Operation;
import 'package:sarsys_app_server/sarsys_app_server.dart';

/// A ResourceController that handles
/// [/api/personnels](http://localhost/api/client.html#/Personnel) requests
class PersonnelController extends AggregateController<PersonnelCommand, Personnel> {
  PersonnelController(
    this.persons,
    this.trackings,
    this.affiliations,
    PersonnelRepository repository,
    JsonValidation validation,
  )   : _trackingController = TrackingController(trackings, validation),
        super(
          repository,
          validation: validation,
          readOnly: const [
            'unit',
            'messages',
            'operation',
            'affiliation',
            'transitions',
          ],
          tag: 'Personnels',
        );

  final PersonRepository persons;
  final TrackingRepository trackings;
  final AffiliationRepository affiliations;
  final TrackingController _trackingController;

  @override
  @Operation.get()
  Future<Response> getAll({
    @Bind.query('limit') int limit = 20,
    @Bind.query('offset') int offset = 0,
    @Bind.query('deleted') bool deleted = false,
    @Bind.query('expand') String expand,
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
          aggregates.map(
            _shouldExpand(expand) ? merge : toAggregateData,
          ),
        ),
      );
    } on InvalidOperation catch (e) {
      return Response.badRequest(body: e.message);
    } catch (e, stackTrace) {
      return toServerError(e, stackTrace);
    }
  }

  @override
  @Operation.get('uuid')
  Future<Response> getByUuid(
    @Bind.path('uuid') String uuid, {
    @Bind.query('expand') String expand,
  }) async {
    try {
      if (!await exists(uuid)) {
        return Response.notFound(body: '$aggregateType $uuid not found');
      }
      final aggregate = repository.get(uuid);
      return Response.ok(
        _shouldExpand(expand) ? merge(aggregate) : toAggregateData(aggregate),
      );
    } on InvalidOperation catch (e) {
      return Response.badRequest(body: e.message);
    } catch (e, stackTrace) {
      return toServerError(e, stackTrace);
    }
  }

  final skipped = const ['affiliation'];

  @override
  @Operation('PATCH', 'uuid')
  Future<Response> update(
    @Bind.path('uuid') String uuid,
    @Bind.body() Map<String, dynamic> data,
  ) async {
    final tuuid = data.elementAt<String>('tracking/uuid');
    if (tuuid != null) {
      final personnel = repository.peek(uuid);
      if (personnel == null) {
        return Response.notFound(
          body: '$aggregateType $uuid not found',
        );
      }
      // Ensure only one tracking object per personnel
      final existing = personnel.elementAt<String>('tracking/uuid');
      if (existing != null && tuuid != existing) {
        return conflict(
          ConflictType.exists,
          '$aggregateType $uuid is already tracked by $existing',
          base: personnel.data,
          code: 'duplicate_tracking_uuid',
        );
      }
      // Create tracking if not exists
      if (!await exists(tuuid, repo: trackings)) {
        _trackingController.request = request;
        final result = await _trackingController.create({
          'uuid': tuuid,
          'sources': [
            {'uuid': uuid, 'type': 'trackable'},
          ],
        });
        if (result.statusCode >= 400) {
          return result;
        }
      }
    }

    return super.update(
      uuid,
      data..removeWhere((key, _) => skipped.contains(key)),
    );
  }

  @override
  @Operation('DELETE', 'uuid')
  Future<Response> delete(
    @Bind.path('uuid') String uuid, {
    @Bind.body() Map<String, dynamic> data,
  }) async {
    final isAssigned = repository.peek(uuid)?.data?.elementAt('unit/uuid') != null;
    final hasTracking = repository.peek(uuid)?.data?.elementAt('tracking/uuid') != null;
    final response = await super.delete(uuid, data: data);
    return await withResponseWaitForRuleResults(response, expected: {
      PersonnelRemovedFromOperation: 1,
      TrackingDeleted: hasTracking ? 1 : 0,
      PersonnelRemovedFromUnit: isAssigned ? 1 : 0,
    });
  }

  bool _shouldExpand(String expand) {
    final elements = expand?.split(',') ?? <String>[];
    if (elements.any((element) => element.toLowerCase() == 'person')) {
      return true;
    }
    if (elements.isNotEmpty) {
      throw "Invalid query parameter 'expand' values: $expand";
    }
    return false;
  }

  /// Merge [Personnel] with [Person]
  Map<String, dynamic> merge(Personnel aggregate) {
    final entry = toAggregateData(aggregate);
    final personnel = entry.mapAt<String, dynamic>('data');
    final auuid = personnel.elementAt<String>('affiliation/uuid');
    if (auuid != null) {
      final affiliation = affiliations.peek(auuid);
      if (affiliation != null) {
        final puuid = affiliation.elementAt<String>('person/uuid');
        if (puuid != null) {
          final person = persons.peek(puuid);
          if (person != null) {
            // Do not overwrite personnel.uuid
            personnel.addAll({
              'affiliation': Map<String, dynamic>.from(affiliation.data)
                ..addAll({
                  'person': person.data,
                })
            });
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
  Iterable<PersonnelCommand> onUpdate(Map<String, dynamic> data) => [
        UpdatePersonnelInformation(data),
      ];

  @override
  PersonnelCommand onDelete(Map<String, dynamic> data) => DeletePersonnel(data);

  //////////////////////////////////
  // Documentation
  //////////////////////////////////

  @override
  APISchemaObject documentAggregateRoot(APIDocumentContext context) => APISchemaObject.object(
        {
          'uuid': context.schema['UUID']..description = 'Unique Personnel id',
          'status': documentStatus(),
          'function': documentFunction(),
          'affiliation': APISchemaObject()
            ..anyOf = [
              context.schema['Affiliation'],
              documentAggregateRef(
                context,
                readOnly: false,
                defaultType: 'Affiliation',
                description: "Affiliation reference for PII lookup",
              ),
            ],
          'operation': documentAggregateRef(
            context,
            defaultType: 'Operation',
            description: 'Operation which this personnel is allocated to',
          ),
          'unit': documentAggregateRef(
            context,
            defaultType: 'Unit',
            description: 'Unit which this personnel is assigned to',
          ),
          'tracking': documentAggregateRef(
            context,
            readOnly: false,
            defaultType: 'Tracking',
            description: 'Unique id of tracking object created for this personnel.',
          ),
          'transitions': APISchemaObject.array(ofSchema: documentTransition())
            ..isReadOnly = true
            ..description = 'State transitions (read only)',
          'messages': APISchemaObject.array(ofSchema: context.schema['Message'])
            ..isReadOnly = true
            ..description = 'List of messages added to Personnel',
        },
      )
        ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
        ..required = [
          'uuid',
          'affiliation',
        ];

  APISchemaObject documentTransition() => APISchemaObject.object({
        'status': documentStatus(),
        'timestamp': APISchemaObject.string()
          ..description = 'When transition occurred'
          ..format = 'date-time',
      })
        ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed;

  /// Personnel Status - Value Object
  APISchemaObject documentStatus() => APISchemaObject.string()
    ..description = 'Personnel status'
    ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
    ..defaultValue = 'alerted'
    ..enumerated = [
      'none',
      'alerted',
      'enroute',
      'onscene',
      'leaving',
      'retired',
    ];

  /// Personnel function - Value Object
  APISchemaObject documentFunction() => APISchemaObject.string()
    ..description = 'Personnel function'
    ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
    ..defaultValue = 'personnel'
    ..enumerated = [
      'personnel',
      'commander',
      'unit_leader',
      'planning_chief',
      'operations_chief',
    ];

  @override
  List<APIParameter> documentOperationParameters(APIDocumentContext context, Operation operation) {
    final parameters = super.documentOperationParameters(context, operation);
    switch (operation.method) {
      case 'GET':
        parameters.add(
          APIParameter.query('expand')
            ..description = "Expand response with information from references. Legal values are: 'person'",
        );
        break;
    }
    return parameters;
  }
}
