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
        "history": APISchemaObject.array(ofSchema: context.schema['Position'])
          ..description = "List of historical positions"
          ..isReadOnly = true,
        "sources": APISchemaObject.array(ofSchema: context.schema['Track'])
          ..description = "Array of Track objects"
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
}
