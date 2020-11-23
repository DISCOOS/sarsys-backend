import 'package:aqueduct/aqueduct.dart';

import 'package:sarsys_app_server/controllers/event_source/controllers.dart';
import 'package:sarsys_app_server/validation/validation.dart';
import 'package:sarsys_domain/sarsys_domain.dart' hide Operation;

class TrackingTrackPositionsController extends ValueController<TrackingCommand, Tracking> {
  TrackingTrackPositionsController(TrackingRepository repository, JsonValidation validation)
      : super(
          repository,
          "PositionList",
          "tracks/positions",
          validation: validation,
          tag: "Trackings > Tracks",
        );

  @Operation('GET', 'uuid', 'id')
  Future<Response> getPositions(
    @Bind.path('uuid') String uuid,
    @Bind.path('id') String id,
  ) async {
    try {
      if (!await exists(uuid)) {
        return Response.notFound(
          body: "$aggregateType $uuid not found",
        );
      }
      // Get tracking aggregate
      final tracking = repository.get(uuid);
      final tracks = tracking.asEntityArray('tracks');
      if (!tracks.contains(id)) {
        return Response.notFound(
          body: "tracks/$id not found",
        );
      }
      return super.getValue(
        uuid,
        "tracks/$id/positions",
      );
    } catch (e, stackTrace) {
      return toServerError(e, stackTrace);
    }
  }

  // @Scope(['roles:commander'])
  // @Operation('PATCH', 'uuid', 'id')
  // Future<Response> setPositions(
  //   @Bind.path('uuid') String uuid,
  //   @Bind.path('id') String id,
  //   @Bind.body() List<Map<String, dynamic>> data,
  // ) async {
  //   try {
  //     if (!await exists(uuid)) {
  //       return Response.notFound(
  //         body: "$aggregateType $uuid not found",
  //       );
  //     }
  //     // Get tracking aggregate
  //     final tracking = repository.get(uuid);
  //     final tracks = tracking.asEntityArray('tracks');
  //     if (!tracks.contains(id)) {
  //       return Response.notFound(
  //         body: "tracks/$id not found",
  //       );
  //     }
  //     return super.setValue(
  //       uuid,
  //       "tracks/$id/positions",
  //       data,
  //     );
  //   } catch (e, stackTrace) {
  //     return toServerError(e, stackTrace);
  //   }
  // }
  //
  // @override
  // TrackingCommand onUpdate(String uuid, String type, Map<String, dynamic> data) => UpdateTrackingPosition(data);
  //

  //////////////////////////////////
  // Documentation
  //////////////////////////////////

  /// PositionList - Value object
  @override
  APISchemaObject documentValueObject(APIDocumentContext context) =>
      APISchemaObject.array(ofSchema: context.schema['Position'])
        ..description = "List of Position features"
        ..isReadOnly = false
        ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed;
}
