import 'package:sarsys_app_server/controllers/eventsource/controllers.dart';
import 'package:sarsys_domain/sarsys_domain.dart' hide Operation;
import 'package:sarsys_app_server/sarsys_app_server.dart';
import 'package:sarsys_app_server/validation/validation.dart';

/// A ResourceController that handles
/// [/api/incidents/{uuid}/Tracks](http://localhost/api/client.html#/Track) requests
class TrackController extends EntityController<TrackingCommand, Tracking> {
  TrackController(TrackingRepository repository, JsonValidation validation)
      : super(repository, "Track", "sources", readOnly: ['positions'], validation: validation, tag: "Tracking > Track");

  @override
  TrackingCommand onCreate(String uuid, String type, Map<String, dynamic> data) => AddSourceToTracking(uuid, data);

  @override
  TrackingCommand onUpdate(String uuid, String type, Map<String, dynamic> data) => UpdateTrackingSource(uuid, data);

  @override
  TrackingCommand onDelete(String uuid, String type, Map<String, dynamic> data) => RemoveSourceFromTracking(uuid, data);

  //////////////////////////////////
  // Documentation
  //////////////////////////////////

  @override
  APISchemaObject documentEntityObject(APIDocumentContext context) => APISchemaObject.object({
        "id": context.schema['ID']..description = "Track id (unique in Tracking only)",
        "source": APISchemaObject.object({
          "uuid": context.schema['UUID'],
          "type": documentSourceType(),
          "exists": APISchemaObject.boolean()
            ..description = "Flag is true if source exists"
            ..isReadOnly = true,
        })
          ..description = "Uuid of position source",
        "status": documentTrackStatus()..isReadOnly = true,
        "positions": APISchemaObject.array(ofSchema: context.schema['Position'])
          ..description = "Sourced positions"
          ..isReadOnly = true,
      })
        ..description = "Tracking Schema (aggregate root)"
        ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
        ..required = [
          'id',
          'source',
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

  /// TrackStatus - Value Object
  APISchemaObject documentTrackStatus() => APISchemaObject.string()
    ..description = "Track status"
    ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
    ..enumerated = [
      'attached',
      'detached',
    ];

  @override
  Map<String, APISchemaObject> documentEntities(APIDocumentContext context) => {};
}
