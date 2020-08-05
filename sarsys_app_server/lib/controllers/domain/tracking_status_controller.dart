import 'package:aqueduct/aqueduct.dart';

import 'package:sarsys_app_server/controllers/event_source/controllers.dart';
import 'package:sarsys_app_server/validation/validation.dart';
import 'package:sarsys_domain/sarsys_domain.dart' hide Operation;

class TrackingStatusController extends ValueController<TrackingCommand, Tracking> {
  TrackingStatusController(TrackingRepository repository, JsonValidation validation)
      : super(
          repository,
          "Tracking",
          "status",
          tag: "Tracking",
          validation: validation.copyWith([
            ValueValidator(path: 'status', allowed: ['tracking', 'paused']),
          ]),
        );

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
        case 'empty':
          return Response.badRequest(
            body: "Tracking is empty",
          );
        case 'closed':
          return Response.badRequest(
            body: "Tracking is closed",
          );
      }
      return super.update(uuid, data);
    } catch (e) {
      return Response.serverError(body: e);
    }
  }

  @override
  TrackingCommand onUpdate(String uuid, String type, Map<String, dynamic> data) => UpdateTrackingStatus(data);
}
