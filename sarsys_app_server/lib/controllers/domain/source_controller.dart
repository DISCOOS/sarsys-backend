import 'package:sarsys_app_server/controllers/domain/schemas.dart';
import 'package:sarsys_app_server/controllers/event_source/controllers.dart';
import 'package:sarsys_domain/sarsys_domain.dart' hide Operation;
import 'package:sarsys_app_server/sarsys_app_server.dart';
import 'package:sarsys_app_server/validation/validation.dart';

/// A ResourceController that handles Tracking Source requests
class SourceController extends EntityController<TrackingCommand, Tracking> {
  SourceController(TrackingRepository repository, JsonValidation validation)
      : super(
          repository,
          "Source",
          "sources",
          readOnly: [
            'exists',
          ],
          validation: validation,
          tag: "Trackings > Sources",
        );

  @override
  @Operation.get('uuid')
  Future<Response> getAll(@Bind.path('uuid') String uuid) {
    return super.getAll(uuid);
  }

  @override
  @Operation.get('uuid', 'uuid')
  Future<Response> getById(
    @Bind.path('uuid') String uuid,
    @Bind.path('uuid') String id,
  ) {
    return super.getById(uuid, id);
  }

  @override
  @Operation('DELETE', 'uuid', 'uuid')
  Future<Response> delete(
    @Bind.path('uuid') String uuid,
    @Bind.path('uuid') String id, {
    @Bind.body() Map<String, dynamic> data,
  }) {
    return super.delete(uuid, id, data: data);
  }

  @override
  TrackingCommand onCreate(String uuid, String type, Map<String, dynamic> data) => AddSourceToTracking(uuid, data);

  @override
  TrackingCommand onDelete(String uuid, String type, Map<String, dynamic> data) => RemoveSourceFromTracking(uuid, data);

  //////////////////////////////////
  // Documentation
  //////////////////////////////////

  @override
  APISchemaObject documentEntityObject(APIDocumentContext context) => APISchemaObject.object({
        "uuid": documentUUID()..description = "Unique Source identifier",
        "type": documentSourceType(),
        "exists": APISchemaObject.boolean()
          ..description = "Flag is true if source exists"
          ..isReadOnly = true,
      })
        ..required = [
          'uuid',
          'type',
        ];

  /// SourceType - Value Object
  APISchemaObject documentSourceType() => APISchemaObject.string()
    ..description = "Source type"
    ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
    ..enumerated = [
      'device',
      'tracking',
    ];
}
