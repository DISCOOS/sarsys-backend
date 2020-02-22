import 'package:sarsys_app_server/controllers/eventsource/aggregate_controller.dart';
import 'package:sarsys_domain/sarsys_domain.dart';
import 'package:sarsys_app_server/sarsys_app_server.dart';
import 'package:sarsys_app_server/validation/validation.dart';

/// A ResourceController that handles
/// [/api/incidents/{uuid}/Trackings](http://localhost/api/client.html#/Tracking) requests
class TrackingController extends AggregateController<TrackingCommand, Tracking> {
  TrackingController(TrackingRepository repository, JsonValidation validation)
      : super(
          repository,
          validation: validation,
          readOnly: const [
            'devices',
            'aggregates',
            'history',
            'tracks',
          ],
          validators: [
            ValueValidator(
              '/position/properties/type',
              ['manual'],
            )
          ],
          tag: "Tracking",
        );

  @override
  TrackingCommand onCreate(Map<String, dynamic> data) => CreateTracking(data);

  @override
  TrackingCommand onUpdate(Map<String, dynamic> data) => UpdateTracking(data);

  @override
  TrackingCommand onDelete(Map<String, dynamic> data) => DeleteTracking(data);

  //////////////////////////////////
  // Documentation
  //////////////////////////////////

  @override
  APISchemaObject documentAggregateRoot(APIDocumentContext context) => APISchemaObject.object({
        "uuid": context.schema['UUID']..description = "Unique tracking id",
        "status": documentTrackingStatus(),
        "position": context.schema['Position']..description = "Current position",
        "distance": APISchemaObject.number()
          ..description = "Total distance in meter"
          ..isReadOnly = true,
        "speed": APISchemaObject.number()
          ..description = "Average speed in m/s"
          ..isReadOnly = true,
        "effort": APISchemaObject.number()
          ..description = "Total effort in milliseconds"
          ..isReadOnly = true,
        "devices": APISchemaObject.array(ofSchema: context.schema['UUID'])
          ..description = "List of uuids of tracked devices"
          ..isReadOnly = true,
        "aggregates": APISchemaObject.array(ofSchema: context.schema['UUID'])
          ..description = "List of uuids of tracking objects being aggregated by this tracking object"
          ..isReadOnly = true,
        "history": APISchemaObject.array(ofSchema: context.schema['Position'])
          ..description = "List of historical positions"
          ..isReadOnly = true,
        "tracks": APISchemaObject.map(ofSchema: context.schema['Track'])
          ..description = "Map of device or aggregate uuid to Track objects"
          ..isReadOnly = true
      })
        ..description = "Tracking Schema (aggregate root)"
        ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
        ..required = [
          'uuid',
        ];

  /// TrackingStatus - Value Object
  APISchemaObject documentTrackingStatus() => APISchemaObject.string()
    ..description = "Tracking status"
    ..defaultValue = "none"
    ..isReadOnly = true
    ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
    ..enumerated = [
      'none',
      'created',
      'tracking',
      'paused',
      'closed',
    ];

  /// TrackType - Value Object
  APISchemaObject documentTrackType() => APISchemaObject.string()
    ..description = "Track type"
    ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
    ..enumerated = [
      'device',
      'aggregated',
    ];

  @override
  Map<String, APISchemaObject> documentValues(APIDocumentContext context) => {
        'Track': documentTrack(context),
      };

  APISchemaObject documentTrack(APIDocumentContext context) => APISchemaObject.object({
        "source": context.schema['UUID']..description = "Uuid of position source",
        "type": documentTrackType()..description = "Track type",
        "positions": APISchemaObject.array(ofSchema: context.schema['Position'])..description = "Sourced positions",
      })
        ..description = "Tracking Schema (aggregate root)"
        ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
        ..required = [
          'uuid',
        ];
}
