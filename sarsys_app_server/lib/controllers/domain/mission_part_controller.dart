import 'package:sarsys_domain/sarsys_domain.dart' hide Operation;
import 'package:sarsys_app_server/sarsys_app_server.dart';

/// A ResourceController that handles
/// [/api/incidents/{uuid}/MissionParts](http://localhost/api/client.html#/MissionPart) requests
class MissionPartController extends EntityController<MissionCommand, Mission> {
  MissionPartController(MissionRepository repository, JsonValidation validation)
      : super(repository, "MissionPart", "parts", validation: validation, tag: 'Missions > Parts');

  @override
  @Operation.get('uuid')
  Future<Response> getAll(@Bind.path('uuid') String uuid) {
    return super.getAll(uuid);
  }

  @override
  @Operation.get('uuid', 'id')
  Future<Response> getById(
    @Bind.path('uuid') String uuid,
    @Bind.path('id') String id,
  ) {
    return super.getById(uuid, id);
  }

  @override
  @Operation.post('uuid')
  Future<Response> create(
    @Bind.path('uuid') String uuid,
    @Bind.body() Map<String, dynamic> data,
  ) {
    return super.create(uuid, data);
  }

  @override
  @Operation('PATCH', 'uuid', 'id')
  Future<Response> update(
    @Bind.path('uuid') String uuid,
    @Bind.path('id') String id,
    @Bind.body() Map<String, dynamic> data,
  ) {
    return super.update(uuid, id, data);
  }

  @override
  @Operation('DELETE', 'uuid', 'id')
  Future<Response> delete(
    @Bind.path('uuid') String uuid,
    @Bind.path('id') String id, {
    @Bind.body() Map<String, dynamic> data,
  }) {
    return super.delete(uuid, id, data: data);
  }

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
