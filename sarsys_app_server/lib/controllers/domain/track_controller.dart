import 'package:sarsys_app_server/controllers/domain/schemas.dart';
import 'package:sarsys_app_server/controllers/event_source/controllers.dart';
import 'package:sarsys_domain/sarsys_domain.dart' hide Operation;
import 'package:sarsys_app_server/sarsys_app_server.dart';
import 'package:sarsys_app_server/validation/validation.dart';

/// A ResourceController that handles Track requests
class TrackController extends EntityController<TrackingCommand, Tracking> {
  TrackController(TrackingRepository repository, JsonValidation validation)
      : super(
          repository,
          "Track",
          "tracks",
          readOnly: [
            'status',
            'positions',
          ],
          validation: validation,
          tag: "Trackings > Tracks",
        );

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

  //////////////////////////////////
  // Documentation
  //////////////////////////////////

  @override
  APISchemaObject documentEntityObject(APIDocumentContext context) => APISchemaObject.object({
        "id": documentID()
          ..description = "Track id (unique in Tracking only)"
          ..isReadOnly = true,
        "source": context.schema['Source'],
        "status": documentTrackStatus()..isReadOnly = true,
        "positions": APISchemaObject.array(ofSchema: context.schema['Position'])
          ..description = "Sourced positions"
          ..isReadOnly = true,
      })
        ..description = "Tracking Schema (aggregate root)"
        ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
        ..required = [
          'source',
        ];

  /// SourceType - Value Object
  APISchemaObject documentSourceType() => APISchemaObject.string()
    ..description = "Source type"
    ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
    ..enumerated = [
      'device',
      'tracking',
    ];

  /// TrackStatus - Value Object
  APISchemaObject documentTrackStatus() => APISchemaObject.string()
    ..description = "Track status"
    ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
    ..enumerated = [
      'attached',
      'detached',
    ];

  APISchemaObject documentSource(APIDocumentContext context) => APISchemaObject.object({
        "uuid": context.schema['UUID'],
        "type": documentSourceType(),
        "exists": APISchemaObject.boolean()
          ..description = "Flag is true if source exists"
          ..isReadOnly = true,
      })
        ..required = [
          'uuid',
          'type',
        ];

  @override
  Map<String, APISchemaObject> documentEntities(APIDocumentContext context) => {
        'Source': documentSource(context),
      };
}
