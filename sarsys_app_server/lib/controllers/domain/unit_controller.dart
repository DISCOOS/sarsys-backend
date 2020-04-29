import 'package:sarsys_app_server/controllers/event_source/aggregate_controller.dart';
import 'package:sarsys_domain/sarsys_domain.dart' hide Operation;
import 'package:sarsys_app_server/sarsys_app_server.dart';
import 'package:sarsys_app_server/validation/validation.dart';
import 'package:event_source/event_source.dart';

/// A ResourceController that handles
/// [/api/incidents/{uuid}/units](http://localhost/api/client.html#/Unit) requests
class UnitController extends AggregateController<UnitCommand, Unit> {
  UnitController(UnitRepository repository, JsonValidation validation)
      : super(
          repository,
          validation: validation,
          readOnly: const [
            'operation',
            'messages',
            'transitions',
          ],
          tag: 'Units',
        );

  @override
  @Operation.get()
  Future<Response> getAll({
    @Bind.query('offset') int offset = 0,
    @Bind.query('limit') int limit = 20,
  }) {
    return super.getAll(offset: offset, limit: limit);
  }

  @override
  @Operation.get('uuid')
  Future<Response> getByUuid(@Bind.path('uuid') String uuid) {
    return super.getByUuid(uuid);
  }

  @override
  @Operation.post()
  Future<Response> create(@Bind.body() Map<String, dynamic> data) async {
    final hasTracking = data?.elementAt('tracking/uuid') != null;
    final response = await super.create(data);
    if (hasTracking) {
      return await waitForRuleResult<TrackingCreated>(
        response,
        fail: true,
        timeout: const Duration(milliseconds: 10000),
      );
    }
    return response;
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
    final hasTracking = repository.get(uuid, createNew: false)?.data?.elementAt('tracking/uuid') != null;
    final response = await super.delete(uuid, data: data);
    if (hasTracking) {
      return await waitForRuleResults(response, expected: [
        UnitRemovedFromOperation,
        TrackingDeleted,
      ]);
    }
    return await waitForRuleResult<UnitRemovedFromOperation>(
      response,
    );
  }

  @override
  UnitCommand onCreate(Map<String, dynamic> data) => CreateUnit(data);

  @override
  UnitCommand onUpdate(Map<String, dynamic> data) => UpdateUnitInformation(data);

  @override
  UnitCommand onDelete(Map<String, dynamic> data) => DeleteUnit(data);

  //////////////////////////////////
  // Documentation
  //////////////////////////////////

  @override
  APISchemaObject documentAggregateRoot(APIDocumentContext context) => APISchemaObject.object(
        {
          "uuid": context.schema['UUID']..description = "Unique unit id",
          "operation": APISchemaObject.object({
            "uuid": context.schema['UUID'],
          })
            ..isReadOnly = true
            ..description = "Operation which this unit belongs to"
            ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed,
          "type": documentType(),
          "number": APISchemaObject.integer()..description = "Unit number",
          "affiliation": context.schema["Affiliation"],
          "phone": APISchemaObject.string()..description = "Unit phone number",
          "callsign": APISchemaObject.string()..description = "Unit callsign",
          "status": documentStatus(),
          "tracking": APISchemaObject.object({
            "uuid": context.schema['UUID'],
          })
            ..description = "Unique id of tracking object "
                "created for this unit. Only writable on creation.",
          "transitions": APISchemaObject.array(ofSchema: documentTransition())
            ..isReadOnly = true
            ..description = "State transitions (read only)",
          "personnels": APISchemaObject.array(ofSchema: context.schema['UUID'])
            ..description = "List of uuid of Personnels assigned to this unit",
          "messages": APISchemaObject.array(ofSchema: context.schema['Message'])
            ..isReadOnly = true
            ..description = "List of messages added to Incident",
        },
      )
        ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
        ..required = [
          'uuid',
          'type',
          'status',
          'number',
          'callsign',
        ];

  APISchemaObject documentTransition() => APISchemaObject.object({
        "status": documentStatus(),
        "timestamp": APISchemaObject.string()
          ..description = "When transition occured"
          ..format = 'date-time',
      })
        ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed;

  /// Unit type - Value Object
  APISchemaObject documentType() => APISchemaObject.string()
    ..description = "Unit type"
    ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
    ..enumerated = [
      'team',
      'k9',
      'boat',
      'vehicle',
      'snowmobile',
      'atv',
      'commandpost',
      'other',
    ];

  /// Unit Status - Value Object
  APISchemaObject documentStatus() => APISchemaObject.string()
    ..description = "Unit status"
    ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
    ..defaultValue = "mobilized"
    ..enumerated = [
      'mobilized',
      'deployed',
      'retired',
    ];
}
