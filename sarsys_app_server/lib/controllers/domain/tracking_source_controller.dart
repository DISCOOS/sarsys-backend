import 'package:sarsys_domain/sarsys_domain.dart' hide Operation;
import 'package:sarsys_app_server/sarsys_app_server.dart';

/// A ResourceController that handles Tracking Source requests
class TrackingSourceController extends EntityController<TrackingCommand, Tracking> {
  TrackingSourceController(TrackingRepository repository, JsonValidation validation)
      : super(
          repository,
          "Source",
          "sources",
          readOnly: [
            'exists',
          ],
          validation: validation,
          entityIdFieldName: 'uuid',
          tag: "Trackings > Sources",
        );

  @override
  @Operation.post('tuuid')
  Future<Response> create(
    @Bind.path('tuuid') String uuid,
    @Bind.body() Map<String, dynamic> data,
  ) {
    return super.create(uuid, data);
  }

  @override
  @Operation.get('tuuid')
  Future<Response> getAll(@Bind.path('tuuid') String uuid) {
    return super.getAll(uuid);
  }

  @override
  @Operation.get('tuuid', 'suuid')
  Future<Response> getById(
    @Bind.path('tuuid') String uuid,
    @Bind.path('suuid') String id,
  ) {
    return super.getById(uuid, id);
  }

  @override
  @Operation('DELETE', 'tuuid', 'suuid')
  Future<Response> delete(
    @Bind.path('tuuid') String uuid,
    @Bind.path('suuid') String id, {
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
        "uuid": documentUUID()..description = "Foreign key to unique source identifier.",
        "type": documentSourceType(),
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
      'trackable',
    ];
}
