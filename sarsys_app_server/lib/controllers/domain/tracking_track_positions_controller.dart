import 'package:aqueduct/aqueduct.dart';
import 'package:event_source/event_source.dart';
import 'package:sarsys_app_server/controllers/domain/track_request_utils.dart';

import 'package:sarsys_app_server/controllers/event_source/controllers.dart';
import 'package:sarsys_app_server/validation/validation.dart';
import 'package:sarsys_domain/sarsys_domain.dart' hide Operation;

class TrackingTrackPositionsController extends ValueController<TrackingCommand, Tracking> {
  TrackingTrackPositionsController(TrackingRepository repository, JsonValidation validation)
      : super(
          repository,
          "Position",
          "tracks/positions",
          validation: validation,
          tag: "Trackings > Tracks",
        );

  @override
  @Operation('GET', 'uuid', 'id')
  Future<Response> getPaged(
    @Bind.path('uuid') String uuid, {
    @Bind.path('id') String id,
    @Bind.query('offset') int offset = 0,
    @Bind.query('limit') int limit = 20,
    @Bind.query('option') List<String> options = const ['truncate:-20:m'],
  }) async {
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
      return super.getValuePaged<Map<String, dynamic>>(
        uuid,
        "tracks/$id",
        map: (track) => _toPositions(
          track,
          TrackRequestUtils.toOptions(options),
        ),
        offset: offset,
        limit: limit,
      );
    } catch (e, stackTrace) {
      return toServerError(e, stackTrace);
    }
  }

  Iterable<Map<String, dynamic>> _toPositions(
    Map<String, dynamic> track,
    Map<String, String> options,
  ) {
    var positions = track.listAt<Map<String, dynamic>>('positions') ?? <Map<String, dynamic>>[];
    if (options.containsKey('truncate')) {
      final option = options['truncate'];
      final truncate = option.split(':');
      if (truncate.length != 2) {
        throw const InvalidOperation(
          "Option has format 'truncate:{value}:{unit}'",
        );
      }
      final value = int.parse(truncate[0]);
      final unit = truncate[1];
      positions = TrackRequestUtils.truncate(
        track,
        value,
        unit,
      ).listAt<Map<String, dynamic>>('positions');
    }
    return positions;
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

  //////////////////////////////////
  // Documentation
  //////////////////////////////////

  @override
  Map<String, APIResponse> documentOperationResponses(APIDocumentContext context, Operation operation) {
    final responses = super.documentOperationResponses(context, operation);
    switch (operation.method) {
      case "GET":
        responses["200"] = APIResponse.schema(
          "Successful response",
          context.schema['PositionListResponse'],
        );
        break;
    }
    return responses;
  }

  @override
  List<APIParameter> documentOperationParameters(APIDocumentContext context, Operation operation) {
    switch (operation.method) {
      case "GET":
        return [
          APIParameter.query('offset')..description = 'Start with position at given offset. Default is 0.',
          APIParameter.query('limit')..description = 'Maximum number of positions to fetch. Default is 20.',
          APIParameter.query('option', schema: APISchemaObject.array(ofType: APIType.string))
            ..description = "Options for fetching tracks. "
                "Legal values are: 'option=truncate:{value}:{unit}' (default is '-20:m'). "
                "Use 'truncate' limit number of positions in tracks "
                "where units are 'p' for positions, 'm' for minutes and 'h' for hours. "
                "If 'value' is negative, positions are truncated from head (last position)."
                "If 'value' is positive, positions are truncated from tail (first position).",
        ];
    }
    return super.documentOperationParameters(context, operation);
  }
}
