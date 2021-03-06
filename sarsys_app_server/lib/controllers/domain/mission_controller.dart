import 'package:sarsys_domain/sarsys_domain.dart' hide Operation;
import 'package:sarsys_app_server/sarsys_app_server.dart';

/// A ResourceController that handles
/// [/api/incidents/{uuid}/personnels](http://localhost/api/client.html#/Mission) requests
class MissionController extends AggregateController<MissionCommand, Mission> {
  MissionController(MissionRepository repository, JsonValidation validation)
      : super(
          repository,
          validation: validation,
          readOnly: const [
            'operation',
            'parts',
            'results',
            'assignedTo',
            'transitions',
            'messages',
          ],
          tag: 'Missions',
        );

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
    return super.update(uuid, data);
  }

  @override
  @Operation('DELETE', 'uuid')
  Future<Response> delete(
    @Bind.path('uuid') String uuid, {
    @Bind.body() Map<String, dynamic> data,
  }) async {
    return await withResponseWaitForRuleResult<MissionRemovedFromOperation>(
      await super.delete(uuid, data: data),
    );
  }

  @override
  MissionCommand onCreate(Map<String, dynamic> data) => CreateMission(data);

  @override
  Iterable<MissionCommand> onUpdate(Map<String, dynamic> data) => [
        UpdateMissionInformation(data),
      ];

  @override
  MissionCommand onDelete(Map<String, dynamic> data) => DeleteMission(data);

  //////////////////////////////////
  // Documentation
  //////////////////////////////////

  @override
  APISchemaObject documentAggregateRoot(APIDocumentContext context) => APISchemaObject.object(
        {
          "uuid": context.schema['UUID']..description = "Unique mission id",
          "operation": APISchemaObject.object({
            "uuid": context.schema['UUID']..description = "Operation uuid which this mission belongs to",
          })
            ..isReadOnly = true
            ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed,
          "description": APISchemaObject.string()..description = "Mission description",
          "type": documentType(),
          "status": documentStatus(),
          "priority": documentPriority(),
          "resolution": documentResolution(),
          "transitions": APISchemaObject.array(ofSchema: documentTransition())
            ..description = "State transitions (read only)"
            ..isReadOnly = true,
          "parts": APISchemaObject.array(ofSchema: context.schema["MissionPart"])
            ..description = "Points, linestrings, rectangles and circles describing mission parts"
            ..isReadOnly = true,
          "results": APISchemaObject.array(ofSchema: context.schema["MissionResult"])
            ..description = "Points, linestrings, rectangles and circles describing the results"
            ..isReadOnly = true,
          "assignedTo": documentAggregateRef(
            context,
            description: "Unit assigned to this mission",
            defaultType: 'Unit',
          ),
          "messages": APISchemaObject.array(ofSchema: context.schema['Message'])
            ..isReadOnly = true
            ..description = "List of messages added to Mission",
        },
      )
        ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
        ..required = [
          'uuid',
          'type',
        ];

  APISchemaObject documentTransition() => APISchemaObject.array(ofType: APIType.object)
    ..items = APISchemaObject.object({
      "status": documentStatus(),
      "resolution": documentResolution(),
      "timestamp": APISchemaObject.string()
        ..description = "When transition occurred"
        ..format = 'date-time',
    })
    ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed;

  APISchemaObject documentType() => APISchemaObject.string()
    ..description = "Mission type"
    ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
    ..enumerated = [
      'search',
      'rescue',
      'other',
    ];

  /// Mission Status - Value Object
  APISchemaObject documentStatus() => APISchemaObject.string()
    ..description = "Mission status"
    ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
    ..defaultValue = "created"
    ..enumerated = [
      'created',
      'planned',
      'assigned',
      'inprogress',
      'completed',
    ];

  /// Mission Priority - Value Object
  APISchemaObject documentPriority() => APISchemaObject.string()
    ..description = "Mission priority"
    ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
    ..defaultValue = "medium"
    ..enumerated = [
      'highest',
      'high',
      'medium',
      'low',
      'lowest',
    ];

  /// Mission Resolution - Value Object
  APISchemaObject documentResolution() => APISchemaObject.string()
    ..description = "Mission status"
    ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
    ..defaultValue = "unresolved"
    ..enumerated = [
      'unresolved',
      'cancelled',
      'duplicate',
      'resolved',
    ];
}
