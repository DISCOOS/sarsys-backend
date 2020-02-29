import 'package:sarsys_app_server/controllers/event_source/aggregate_controller.dart';
import 'package:sarsys_domain/sarsys_domain.dart';
import 'package:sarsys_app_server/sarsys_app_server.dart';
import 'package:sarsys_app_server/validation/validation.dart';

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
          "assignedTo": APISchemaObject.object({
            "uuid": context.schema['UUID'],
          })
            ..description = "Unit assigned to this mission"
            ..isReadOnly = true,
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
        ..description = "When transition occured"
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
