import 'package:sarsys_app_server/controllers/aggregate_controller.dart';
import 'package:sarsys_app_server/domain/mission/mission.dart';
import 'package:sarsys_app_server/domain/personnel/personnel.dart';
import 'package:sarsys_app_server/sarsys_app_server.dart';
import 'package:sarsys_app_server/validation/validation.dart';

/// A ResourceController that handles
/// [/api/incidents/{uuid}/personnels](http://localhost/api/client.html#/Mission) requests
class MissionController extends AggregateController<MissionCommand, Mission> {
  MissionController(MissionRepository repository, RequestValidator validator) : super(repository, validator: validator);

  @override
  MissionCommand onCreate(Map<String, dynamic> data) => CreateMission(data);

  @override
  MissionCommand onUpdate(Map<String, dynamic> data) => UpdateMissionInformation(data);

  @override
  MissionCommand onDelete(Map<String, dynamic> data) => DeleteMission(data);

  //////////////////////////////////
  // Documentation
  //////////////////////////////////

  @override
  APISchemaObject documentAggregateRoot(APIDocumentContext context) => APISchemaObject.object(
        {
          "uuid": APISchemaObject.string()
            ..format = 'uuid'
            ..description = "Unique Mission id",
          "description": APISchemaObject.string()..description = "Mission description",
          "type": documentType(),
          "status": documentStatus(),
          "priority": documentPriority(),
          "resolution": documentResolution(),
          "transitions": APISchemaObject.array(ofType: APIType.object)
            ..items = APISchemaObject.object({
              "status": documentStatus(),
              "resolution": documentResolution(),
              "timestamp": APISchemaObject.string()
                ..description = "When transition occured"
                ..format = 'date-time',
            })
            ..isReadOnly = true
            ..description = "State transitions (read only)"
            ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed,
          "assignedTo": APISchemaObject.string()
            ..format = 'uuid'
            ..description = "Uuid of unit assigned to mission",
        },
      )
        ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
        ..required = [
          'uuid',
          'type',
        ];

  APISchemaObject documentType() {
    return APISchemaObject.string()
      ..description = "Mission type"
      ..enumerated = [
        'search',
        'rescue',
        'other',
      ];
  }

  /// Mission Status - Value Object
  APISchemaObject documentStatus() => APISchemaObject.string()
    ..description = "Mission status"
    ..defaultValue = "created"
    ..enumerated = [
      'created',
      'planned',
      'assigned',
      'executed',
    ];

  /// Mission Priority - Value Object
  APISchemaObject documentPriority() => APISchemaObject.string()
    ..description = "Mission priority"
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
    ..defaultValue = "unresolved"
    ..enumerated = [
      'unresolved',
      'cancelled',
      'duplicate',
      'resolved',
    ];
}
