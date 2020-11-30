import 'package:aqueduct/aqueduct.dart';
import 'package:sarsys_app_server/controllers/domain/schemas.dart';

import 'package:sarsys_app_server/controllers/event_source/controllers.dart';
import 'package:sarsys_app_server/validation/validation.dart';
import 'package:sarsys_domain/sarsys_domain.dart' hide Operation;

class TrackingStatusController extends ValueController<TrackingCommand, Tracking> {
  TrackingStatusController(TrackingRepository repository, JsonValidation validation)
      : super(
          repository,
          "TrackingStatusRequest",
          "status",
          tag: "Trackings",
          validation: validation.copyWith([
            ValueValidator(path: 'status', allowed: allowed),
          ]),
        );

  static const allowed = ['tracking', 'paused'];

  @Scope(['roles:commander'])
  @Operation('PATCH', 'uuid')
  Future<Response> transition(
    @Bind.path('uuid') String uuid,
    @Bind.body() Map<String, dynamic> data,
  ) async {
    try {
      if (!await exists(uuid)) {
        return Response.notFound(
          body: "$aggregateType $uuid not found",
        );
      }
      // Assert legal transition
      final tracking = repository.get(uuid);
      switch (tracking.elementAt<String>('status') ?? 'none') {
        case 'none':
        case 'ready':
          return Response.badRequest(
            body: "Tracking is empty",
          );
        case 'closed':
          return Response.badRequest(
            body: "Tracking is closed",
          );
      }
      return super.update(uuid, data);
    } catch (e, stackTrace) {
      return toServerError(e, stackTrace);
    }
  }

  @override
  TrackingCommand onUpdate(String uuid, String type, Map<String, dynamic> data) => UpdateTrackingStatus(data);

  //////////////////////////////////
  // Documentation
  //////////////////////////////////

  /// TrackingStatusRequest - Value object
  @override
  APISchemaObject documentValueObject(APIDocumentContext context) =>
      APISchemaObject.object({'status': documentTrackingStatus(values: allowed)})
        ..description = "Tracking transition request"
        ..isReadOnly = true
        ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed;
}
