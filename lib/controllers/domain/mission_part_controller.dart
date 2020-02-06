import 'package:sarsys_app_server/controllers/eventsource/entity_controller.dart';
import 'package:sarsys_app_server/domain/mission/mission.dart';
import 'package:sarsys_app_server/sarsys_app_server.dart';
import 'package:sarsys_app_server/validation/validation.dart';

/// A ResourceController that handles
/// [/api/incidents/{uuid}/MissionParts](http://localhost/api/client.html#/MissionPart) requests
class MissionPartController extends EntityController<MissionCommand, Mission> {
  MissionPartController(MissionRepository repository, RequestValidator validator)
      : super(repository, "MissionPart", "parts", validator: validator, tag: 'Missions');

  @override
  MissionCommand onCreate(String uuid, String type, Map<String, dynamic> data) => AddMissionPart(uuid, data);

  @override
  MissionCommand onUpdate(String uuid, String type, Map<String, dynamic> data) => UpdateMissionPart(uuid, data);

  @override
  MissionCommand onDelete(String uuid, String type, Map<String, dynamic> data) => RemoveMissionPart(uuid, data);

  //////////////////////////////////
  // Documentation
  //////////////////////////////////

  /// MissionPart - Entity object
  @override
  APISchemaObject documentEntityObject(APIDocumentContext context) => APISchemaObject.object(
        {
          "id": context.schema['ID']..description = "Mission part id (unique in Mission only)",
          "name": APISchemaObject.string()..description = "Mission part name",
          "description": APISchemaObject.string()..description = "Mission part description",
          "data": context.schema["FeatureCollection"],
        },
      )
        ..description = "MissionPart Schema"
        ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
        ..required = [
          'id',
        ];
}
