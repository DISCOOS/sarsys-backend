import 'package:sarsys_app_server/controllers/entity_controller.dart';
import 'package:sarsys_app_server/domain/mission/mission.dart';
import 'package:sarsys_app_server/sarsys_app_server.dart';
import 'package:sarsys_app_server/validation/validation.dart';

/// A ResourceController that handles
/// [/api/incidents/{uuid}/MissionResults](http://localhost/api/client.html#/MissionResult) requests
class MissionResultController extends EntityController<MissionCommand, Mission> {
  MissionResultController(MissionRepository repository, RequestValidator validator)
      : super(repository, "MissionResult", "parts", validator: validator);

  @override
  MissionCommand onCreate(String uuid, String type, Map<String, dynamic> data) => AddMissionResult(uuid, data);

  @override
  MissionCommand onUpdate(String uuid, String type, Map<String, dynamic> data) => UpdateMissionResult(uuid, data);

  @override
  MissionCommand onDelete(String uuid, String type, Map<String, dynamic> data) => RemoveMissionResult(uuid, data);

  //////////////////////////////////
  // Documentation
  //////////////////////////////////

  /// MissionResult - Entity object
  @override
  APISchemaObject documentEntityObject(APIDocumentContext context) => APISchemaObject.object(
        {
          "id": APISchemaObject.integer()..description = "Mission result id (unique in Mission only)",
          "name": APISchemaObject.string()..description = "Mission result name",
          "description": APISchemaObject.string()..description = "Mission result description",
          "data": context.schema["GeometryBag"],
        },
      )
        ..description = "MissionResult Schema"
        ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
        ..required = [
          'id',
        ];
}