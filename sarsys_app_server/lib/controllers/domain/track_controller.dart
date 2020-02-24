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
          "type": documentTrackType(),
          "exists": APISchemaObject.boolean()
            ..description = "Flag is true if source exists"
            ..isReadOnly = true,
        })
          ..description = "Uuid of position source",
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

  /// TrackType - Value Object
  APISchemaObject documentTrackType() => APISchemaObject.string()
    ..description = "Track type"
    ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
    ..enumerated = [
      'device',
      'personnel',
    ];

  @override
  Map<String, APISchemaObject> documentEntities(APIDocumentContext context) => {};
}
