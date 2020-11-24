import 'package:event_source/event_source.dart';
import 'package:sarsys_app_server/controllers/domain/schemas.dart';
import 'package:sarsys_app_server/controllers/domain/track_request_utils.dart';
import 'package:sarsys_app_server/controllers/event_source/controllers.dart';
import 'package:sarsys_domain/sarsys_domain.dart' hide Operation;
import 'package:sarsys_app_server/sarsys_app_server.dart';
import 'package:sarsys_app_server/validation/validation.dart';

/// A ResourceController that handles Track requests
class TrackingTrackController extends EntityController<TrackingCommand, Tracking> {
  TrackingTrackController(TrackingRepository repository, JsonValidation validation)
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
  Future<Response> getAll(
    @Bind.path('uuid') String uuid, {
    @Bind.query('expand') String expand,
    @Bind.query('option') List<String> options = const ['truncate:-20:m'],
  }) async {
    try {
      if (!await exists(uuid)) {
        return Response.notFound(body: "$aggregateType $uuid not found");
      }
      final aggregate = repository.get(uuid);
      final array = aggregate.asEntityArray(
        aggregateField,
        entityIdFieldName: entityIdFieldName ?? aggregate.entityIdFieldName,
      );
      return okEntityPaged<Tracking>(
        uuid,
        entityType,
        aggregate.number,
        TrackRequestUtils.toTracks(
          array,
          expand,
          options,
        ),
      );
    } on InvalidOperation catch (e) {
      return Response.badRequest(
        body: e.message,
      );
    } catch (e, stackTrace) {
      return toServerError(e, stackTrace);
    }
  }

  @override
  @Operation.get('uuid', 'id')
  Future<Response> getById(
    @Bind.path('uuid') String uuid,
    @Bind.path('id') String id, {
    @Bind.query('expand') String expand,
    @Bind.query('option') List<String> options = const ['truncate:-20:m'],
  }) async {
    try {
      if (!await exists(uuid)) {
        return Response.notFound(body: "$aggregateType $uuid not found");
      }
      final aggregate = repository.get(uuid);
      final array = aggregate.asEntityArray(
        aggregateField,
        entityIdFieldName: entityIdFieldName ?? aggregate.entityIdFieldName,
      );
      if (!array.contains(id)) {
        return Response.notFound(body: "Entity $id not found");
      }
      final track = TrackRequestUtils.toTrack(
        array[id].data,
        expand,
        options,
      );
      return okEntityObject<Tracking>(
        uuid,
        entityType,
        aggregate.number,
        track,
      );
    } on EntityNotFound catch (e) {
      return Response.notFound(body: e.message);
    } on InvalidOperation catch (e) {
      return Response.badRequest(body: e.message);
    } catch (e, stackTrace) {
      return toServerError(e, stackTrace);
    }
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

  /// TrackStatus - Value Object
  APISchemaObject documentTrackStatus() => APISchemaObject.string()
    ..description = "Track status"
    ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
    ..enumerated = [
      'attached',
      'detached',
    ];

  @override
  List<APIParameter> documentOperationParameters(APIDocumentContext context, Operation operation) {
    switch (operation.method) {
      case "GET":
        return [
          if (operation.pathVariables.length == 1)
            APIParameter.query('expand')
              ..description = "Expand response with optional fields. Legal values are: 'positions'",
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
