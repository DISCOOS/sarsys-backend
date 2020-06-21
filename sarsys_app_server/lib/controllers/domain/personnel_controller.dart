import 'package:sarsys_app_server/controllers/domain/schemas.dart';
import 'package:sarsys_app_server/controllers/event_source/aggregate_controller.dart';
import 'package:sarsys_domain/sarsys_domain.dart' hide Operation;
import 'package:sarsys_app_server/sarsys_app_server.dart';
import 'package:sarsys_app_server/validation/validation.dart';
import 'package:event_source/event_source.dart';

/// A ResourceController that handles
/// [/api/personnels](http://localhost/api/client.html#/Personnel) requests
class PersonnelController extends AggregateController<PersonnelCommand, Personnel> {
  PersonnelController(PersonnelRepository repository, JsonValidation validation)
      : super(repository,
            validation: validation,
            readOnly: const [
              'unit',
              'messages',
              'operation',
              'transitions',
            ],
            tag: 'Personnels');

  @override
  @Operation.get()
  Future<Response> getAll({
    @Bind.query('offset') int offset = 0,
    @Bind.query('limit') int limit = 20,
    @Bind.query('deleted') bool deleted = false,
  }) {
    return super.getAll(
      offset: offset,
      limit: limit,
      deleted: deleted,
    );
  }

  @override
  @Operation.get('uuid')
  Future<Response> getByUuid(@Bind.path('uuid') String uuid) {
    return super.getByUuid(uuid);
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
}
