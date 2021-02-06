import 'package:sarsys_ops_server/sarsys_ops_server.dart';
import 'package:sarsys_ops_server/src/config.dart';
import 'package:sarsys_tracking_server/sarsys_tracking_server.dart';

import 'operations_base_controller.dart';

class TrackingServiceCommandsController extends OperationsBaseController {
  TrackingServiceCommandsController(
    this.client,
    SarSysOpsConfig config,
    Map<String, dynamic> context,
  ) : super(
          'TrackingService',
          config,
          options: [
            'repo',
          ],
          actions: [
            'add_trackings',
            'remove_trackings',
          ],
          tag: 'Tracking',
          context: context,
        );

  final k8s = K8sApi();
  final SarSysTrackingServiceClient client;

  @override
  @Operation.get()
  Future<Response> getMeta({
    @Bind.query('expand') String expand,
  }) {
    return super.getMeta(expand: expand);
  }

  @override
  Future<Response> doGetMeta(String expand) async {
    final meta = await client.getMeta(GetMetaRequest()
      ..expand.addAll([
        if (shouldExpand(expand, 'repo')) ExpandFields.EXPAND_FIELDS_REPO,
      ]));
    return Response.ok(
      _toJsonGetMetaResponse(meta, expand),
    );
  }

  Map<String, Object> _toJsonGetMetaResponse(GetMetaResponse meta, String expand) {
    return {
      'total': meta.total,
      'status': _toStatus(meta),
      'managerOf': _toJsonManagerOf(meta),
      'fractionManaged': meta.fractionManaged,
      'positions': _toJsonPositionsMeta(meta.positions),
      if (shouldExpand(expand, 'repo')) 'repo': _toJsonRepoMeta(meta.repo),
    };
  }

  String _toStatus(GetMetaResponse meta) {
    return enumName(meta.status).split('_').last.toLowerCase();
  }

  List<Map<String, dynamic>> _toJsonManagerOf(GetMetaResponse meta) => meta.managerOf
      .map((meta) => <String, dynamic>{
            'uuid': meta.uuid,
            'trackCount': meta.trackCount,
            'positionCount': meta.positionCount,
            if (meta.lastEvent.uuid.isNotEmpty) 'lastEvent': _toJsonEventMeta(meta.lastEvent),
          })
      .toList();

  Map<String, dynamic> _toJsonRepoMeta(RepositoryMeta meta) => {
        'type': meta.type,
      };

  Map<String, dynamic> _toJsonEventMeta(EventMeta meta) => {
        'type': meta.type,
        'uuid': meta.uuid,
        'remote': meta.remote,
        'number': meta.number,
        'position': meta.position,
      };

  Map<String, dynamic> _toJsonPositionsMeta(PositionsMeta meta) => {
        'total': meta.total,
        'lastEvent': _toJsonEventMeta(meta.lastEvent),
        'positionsPerMinute': meta.positionsPerMinute,
        'averageProcessingTimeMillis': meta.averageProcessingTimeMillis,
      };

  @override
  @Operation.post()
  Future<Response> execute(
    @Bind.body() Map<String, dynamic> body, {
    @Bind.query('expand') String expand,
  }) =>
      super.execute(body, expand: expand);

  @override
  Future<Response> doExecute(
    String command,
    Map<String, dynamic> body,
    String expand,
  ) async {
    switch (command) {
      case 'start':
        return doStart(expand);
      case 'stop':
        return doStop(expand);
      case 'add_trackings':
        final uuids = body.listAt<String>(
          'uuids',
          defaultList: [],
        );
        if (uuids.isEmpty) {
          return Response.badRequest(
            body: "One ore more tracing uuids are required ('uuids' was empty)",
          );
        }
        return doAddTrackings(command, uuids, expand);
      case 'remove_trackings':
        final uuids = body.listAt<String>(
          'uuids',
          defaultList: [],
        );
        if (uuids.isEmpty) {
          return Response.badRequest(
            body: "One ore more tracing uuids are required ('uuids' was empty)",
          );
        }
        return doRemoveTrackings(command, uuids, expand);
    }
    return Response.badRequest(
      body: "Command '$command' not found",
    );
  }

  Future<Response> doStart(
    String expand,
  ) async {
    final response = await client.start(
      StartTrackingRequest()
        ..expand.addAll([
          if (shouldExpand(expand, 'repo')) ExpandFields.EXPAND_FIELDS_REPO,
        ]),
    );
    return Response(
      response.statusCode,
      {},
      {
        'meta': _toJsonGetMetaResponse(response.meta, expand),
        if (response.statusCode != HttpStatus.ok)
          'error': {
            'reasonPhrase': response.reasonPhrase,
          }
      },
    );
  }

  Future<Response> doStop(
    String expand,
  ) async {
    final response = await client.stop(
      StopTrackingRequest()
        ..expand.addAll([
          if (shouldExpand(expand, 'repo')) ExpandFields.EXPAND_FIELDS_REPO,
        ]),
    );
    return Response(
      response.statusCode,
      {},
      {
        'meta': _toJsonGetMetaResponse(response.meta, expand),
        if (response.statusCode != HttpStatus.ok)
          'error': {
            'reasonPhrase': response.reasonPhrase,
          }
      },
    );
  }

  Future<Response> doAddTrackings(
    String command,
    List<String> uuids,
    String expand,
  ) async {
    final response = await client.addTrackings(
      AddTrackingsRequest()
        ..uuids.addAll(uuids)
        ..expand.addAll([
          if (shouldExpand(expand, 'repo')) ExpandFields.EXPAND_FIELDS_REPO,
        ]),
    );
    return Response(
      response.statusCode,
      {},
      {
        'meta': _toJsonGetMetaResponse(response.meta, expand),
        if (response.failed.isNotEmpty)
          'error': {
            'failed': response.failed,
            'reasonPhrase': response.reasonPhrase,
          }
      },
    );
  }

  Future<Response> doRemoveTrackings(
    String command,
    List<String> uuids,
    String expand,
  ) async {
    final response = await client.removeTrackings(
      RemoveTrackingsRequest()
        ..uuids.addAll(uuids)
        ..expand.addAll([
          if (shouldExpand(expand, 'repo')) ExpandFields.EXPAND_FIELDS_REPO,
        ]),
    );
    return Response(
      response.statusCode,
      {},
      {
        'meta': _toJsonGetMetaResponse(response.meta, expand),
        if (response.failed.isNotEmpty)
          'error': {
            'failed': response.failed,
            'reasonPhrase': response.reasonPhrase,
          }
      },
    );
  }

  //////////////////////////////////
  // Documentation
  //////////////////////////////////

  @override
  @override
  Map<String, APISchemaObject> documentCommandParams(APIDocumentContext context) => {
        'uuids': APISchemaObject.array(ofType: APIType.string)
          ..description = 'List of aggregate uuids which command applies to',
      };

  @override
  APISchemaObject documentMeta(APIDocumentContext context) {
    return APISchemaObject.object({
      'status': APISchemaObject.string()
        ..description = 'Tracking service status'
        ..enumerated = [
          'none',
          'ready',
          'competing',
          'paused',
          'disposed',
        ]
        ..isReadOnly = true,
      'total': APISchemaObject.integer()
        ..description = 'Total number of tracking objects'
        ..isReadOnly = true,
      'fractionManaged': APISchemaObject.integer()
        ..description = 'Number of managed tracking object to total number of tracking objects'
        ..isReadOnly = true,
      'positions': documentPositionsMeta(context),
      'managerOf': APISchemaObject.array(
        ofSchema: documentTrackingMeta(context),
      )
        ..description = 'List of metadata for managed tracking objects'
        ..isReadOnly = true,
      'repository': documentRepositoryMeta(context)
    });
  }

  APISchemaObject documentPositionsMeta(APIDocumentContext context) => APISchemaObject.object({
        'total': APISchemaObject.integer()
          ..description = 'Total number of positions heard'
          ..isReadOnly = true,
        'positionsPerMinute': APISchemaObject.integer()
          ..description = 'Number of positions processed per minute'
          ..isReadOnly = true,
        'averageProcessingTimeMillis': APISchemaObject.number()
          ..description = 'verage processing time in milliseconds'
          ..isReadOnly = true,
        'lastEvent': documentEvent(context)
          ..description = 'Last event applied to tracking object'
          ..isReadOnly = true,
      })
        ..description = 'Tracking object metadata'
        ..isReadOnly = true;

  APISchemaObject documentTrackingMeta(APIDocumentContext context) => APISchemaObject.object({
        'uuid': documentUUID()
          ..description = 'Tracking uuid'
          ..isReadOnly = true,
        'trackCount': APISchemaObject.integer()
          ..description = 'Number of tracks in tracking object'
          ..isReadOnly = true,
        'positionCount': APISchemaObject.integer()
          ..description = 'Total number of positions in tracking object'
          ..isReadOnly = true,
        'lastEvent': documentEvent(context)
          ..description = 'Last event applied to tracking object'
          ..isReadOnly = true,
      })
        ..description = 'Tracking object metadata'
        ..isReadOnly = true;

  APISchemaObject documentRepositoryMeta(APIDocumentContext context) => APISchemaObject.object({
        'type': APISchemaObject.string()
          ..description = 'Repository type'
          ..isReadOnly = true,
        'lastEvent': documentEvent(context)
          ..description = 'Last event applied to repository'
          ..isReadOnly = true,
        'queue': documentRepositoryQueueMeta(context),
      })
        ..description = 'List of metadata for managed tracking objects'
        ..isReadOnly = true;

  APISchemaObject documentRepositoryQueueMeta(APIDocumentContext context) => APISchemaObject.object({
        'pressure': documentRepositoryQueuePressureMeta(context),
        'status': documentRepositoryQueueStatusMeta(context),
      })
        ..description = 'Repository queue metadata'
        ..isReadOnly = true;

  APISchemaObject documentRepositoryQueuePressureMeta(APIDocumentContext context) => APISchemaObject.object({
        'push': APISchemaObject.integer()
          ..description = 'Number of pending pushes'
          ..isReadOnly = true,
        'commands': APISchemaObject.integer()
          ..description = 'Number of pending commands'
          ..isReadOnly = true,
        'total': APISchemaObject.integer()
          ..description = 'Total number of pending pushes and commands'
          ..isReadOnly = true,
        'maximum': APISchemaObject.integer()
          ..description = 'Maximum allowed queue pressure'
          ..isReadOnly = true,
        'exceeded': APISchemaObject.boolean()
          ..description = 'True if maximum queue pressure is exceeded'
          ..isReadOnly = true,
      })
        ..description = 'Repository queue pressure metadata'
        ..isReadOnly = true;

  APISchemaObject documentRepositoryQueueStatusMeta(APIDocumentContext context) => APISchemaObject.object({
        'idle': APISchemaObject.boolean()
          ..description = 'True if queue is idle'
          ..isReadOnly = true,
        'ready': APISchemaObject.boolean()
          ..description = 'True if queue is ready to process requests'
          ..isReadOnly = true,
        'disposed': APISchemaObject.boolean()
          ..description = 'True if queue is disposed'
          ..isReadOnly = true,
      })
        ..description = 'Repository queue status metadata'
        ..isReadOnly = true;
}
