import 'package:grpc/grpc.dart' hide Response;
import 'package:grpc/grpc_connection_interface.dart';
import 'package:sarsys_ops_server/sarsys_ops_server.dart';
import 'package:sarsys_ops_server/src/config.dart';
import 'package:sarsys_core/sarsys_core.dart';
import 'package:sarsys_ops_server/src/controllers/utils.dart';
import 'package:sarsys_tracking_server/sarsys_tracking_server.dart';

import 'component_base_controller.dart';

class TrackingGrpcServiceController extends ComponentBaseController {
  TrackingGrpcServiceController(
    this.k8s,
    this.channels,
    SarSysOpsConfig config,
    Map<String, dynamic> context,
  ) : super(
          'TrackingService',
          config,
          options: [
            'all',
            'metrics',
            'repo',
            'repo:data',
            'repo:items',
            'repo:queue',
            'repo:metrics',
          ],
          actions: [
            'stop_all',
            'start_all',
          ],
          instanceOptions: [
            'repo',
          ],
          instanceActions: [
            'stop',
            'start',
            'add_trackings',
            'remove_trackings',
          ],
          tag: 'Tracking service',
          context: context,
          modules: [
            'sarsys-tracking-server',
          ],
        );

  final K8sApi k8s;
  final Map<String, ClientChannel> channels;

  @override
  @Scope(['roles:admin'])
  @Operation.get()
  Future<Response> getMeta({
    @Bind.query('expand') String expand,
  }) {
    return super.getMeta(expand: expand);
  }

  @override
  Future<Response> doGetMeta(String expand) async {
    final pods = await k8s.getPodList(
      k8s.namespace,
      labels: toModuleLabels(),
      metrics: shouldExpand(expand, 'metrics'),
    );
    if (pods.isEmpty) {
      return toResponse(
        args: {
          'expand': expand,
        },
        statusCode: HttpStatus.notFound,
        method: 'doGetMeta',
        body: "$modules not found",
      );
    }
    final names = [];
    final items = <Map<String, dynamic>>[];
    for (var pod in pods) {
      final meta = await _doGetMetaByName(pod, expand);
      if (pod.hasPath('metrics')) {
        meta['metrics'] = toPodMetrics(
          modules.first,
          pod,
        );
      }
      items.add(meta);
      names.add(k8s.toPodName(pod));
    }
    return toResponse(
      body: toJsonItemsMeta(
        items,
      ),
      name: '$names',
      method: 'doGetMeta',
      args: {'expand': expand},
      statusCode: toStatusCode(
        items,
      ),
    );
  }

  @override
  @Scope(['roles:admin'])
  @Operation.get('name')
  Future<Response> getMetaByName(
    @Bind.path('name') String name, {
    @Bind.query('expand') String expand,
  }) {
    return super.getMetaByName(name, expand: expand);
  }

  @override
  Future<Response> doGetMetaByName(String name, String expand) async {
    final pod = await _getPod(
      name,
      shouldExpand(expand, 'metrics'),
    );
    if (pod.isEmpty) {
      return toResponse(
        name: name,
        method: 'doGetMetaByName',
        args: {'expand': expand},
        statusCode: HttpStatus.notFound,
        body: "$target instance '$name' not found",
      );
    }
    final meta = await _doGetMetaByName(
      pod,
      expand,
    );
    if (pod.hasPath('metrics')) {
      meta['metrics'] = toPodMetrics(
        modules.first,
        pod,
      );
    }
    return toResponse(
      name: name,
      body: meta,
      args: {'expand': expand},
      method: 'doGetMetaByName',
      statusCode: meta.elementAt<int>(
        'error/statusCode',
        defaultValue: HttpStatus.ok,
      ),
    );
  }

  Future<Map<String, dynamic>> _doGetMetaByName(
    Map<String, dynamic> pod,
    String expand,
  ) async {
    final meta = await toClient(pod).getMeta(GetTrackingMetaRequest()
      ..expand.addAll(
        toRepoFields(expand),
      ));
    return _toJsonInstanceMeta(
      k8s.toPodName(pod),
      meta,
    );
  }

  List<TrackingExpandFields> toRepoFields(String expand) {
    final all = shouldExpand(expand, 'all');
    return [
      if (all || shouldExpand(expand, 'repo')) ...[
        TrackingExpandFields.TRACKING_EXPAND_FIELDS_REPO,
        if (all || shouldExpand(expand, 'repo:data')) TrackingExpandFields.TRACKING_EXPAND_FIELDS_REPO_DATA,
        if (all || shouldExpand(expand, 'repo:items')) TrackingExpandFields.TRACKING_EXPAND_FIELDS_REPO_ITEMS,
        if (all || shouldExpand(expand, 'repo:queue')) TrackingExpandFields.TRACKING_EXPAND_FIELDS_REPO_QUEUE,
        if (all || shouldExpand(expand, 'repo:metrics')) TrackingExpandFields.TRACKING_EXPAND_FIELDS_REPO_METRICS,
      ],
    ];
  }

  @override
  @Scope(['roles:admin'])
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
    final pods = await k8s.getPodList(
      k8s.namespace,
      labels: toModuleLabels(),
    );
    if (pods.isEmpty) {
      return toResponse(
        args: {
          'expand': expand,
        },
        statusCode: HttpStatus.notFound,
        method: 'doExecute',
        body: "$modules not found",
      );
    }
    switch (command) {
      case 'start_all':
        return doStartAll(pods, expand);
      case 'stop_all':
        return doStopAll(pods, expand);
    }
    return toResponse(
      method: 'doExecute',
      statusCode: HttpStatus.badRequest,
      name: '${pods.map(k8s.toPodName).toList()}',
      body: "$target command '$command' not found",
      args: {'command': command, 'expand': expand},
    );
  }

  @override
  @Scope(['roles:admin'])
  @Operation.post('name')
  Future<Response> executeByName(
    @Bind.path('name') String name,
    @Bind.body() Map<String, dynamic> body, {
    @Bind.query('expand') String expand,
  }) {
    return super.executeByName(name, body, expand: expand);
  }

  @override
  Future<Response> doExecuteByName(
    String name,
    String command,
    Map<String, dynamic> body,
    String expand,
  ) async {
    final pod = await _getPod(
      name,
      shouldExpand(expand, 'metrics'),
    );
    if (pod.isEmpty) {
      return toResponse(
        name: name,
        args: {
          'expand': expand,
        },
        statusCode: HttpStatus.notFound,
        method: 'doExecuteByName',
        body: "$target instance '$name' not found",
      );
    }
    final uuids = body.listAt<String>(
      'uuids',
      defaultList: [],
    );
    final args = {
      'uuids': uuids,
      'expand': expand,
      'command': command,
    };
    if (pod == null) {
      return toResponse(
        name: name,
        args: args,
        method: 'doExecuteByName',
        statusCode: HttpStatus.notFound,
        body: "$target instance '$name' not found",
      );
    }
    switch (command) {
      case 'start':
        return doStart(
          pod,
          expand,
        );
      case 'stop':
        return doStop(
          pod,
          expand,
        );
      case 'add_trackings':
        return doAddTrackings(
          pod,
          uuids,
          expand,
        );
      case 'remove_trackings':
        return doRemoveTrackings(
          pod,
          uuids,
          expand,
        );
    }
    return toResponse(
      name: name,
      args: args,
      method: 'doExecuteByName',
      statusCode: HttpStatus.badRequest,
      body: "$target instance command '$command' not found",
    );
  }

  Future<Response> doStartAll(
    List<Map<String, dynamic>> pods,
    String expand,
  ) async {
    final names = [];
    final items = <Map<String, dynamic>>[];
    for (var pod in pods) {
      final meta = await _doStart(
        pod,
        expand,
      );
      items.add(meta);
      names.add(
        k8s.toPodName(pod),
      );
    }
    return toResponse(
      body: toJsonItemsMeta(
        items,
      ),
      name: '$names',
      method: 'doStartAll',
      args: {'expand': expand},
      statusCode: toStatusCode(items),
    );
  }

  Future<Response> doStopAll(
    List<Map<String, dynamic>> pods,
    String expand,
  ) async {
    final names = [];
    final items = <Map<String, dynamic>>[];
    for (var pod in pods) {
      final meta = await _doStop(
        pod,
        expand,
      );
      items.add(meta);
      names.add(
        k8s.toPodName(pod),
      );
    }
    return toResponse(
      body: toJsonItemsMeta(
        items,
      ),
      name: '$names',
      method: 'doStopAll',
      args: {'expand': expand},
      statusCode: toStatusCode(items),
    );
  }

  Future<Response> doStart(
    Map<String, dynamic> pod,
    String expand,
  ) async {
    final meta = await _doStart(pod, expand);
    if (pod.hasPath('metrics')) {
      meta['metrics'] = toPodMetrics(
        modules.first,
        pod,
      );
    }
    return toResponse(
      body: meta,
      method: 'doStart',
      name: k8s.toPodName(pod),
      args: {'expand': expand},
      statusCode: toStatusCode([meta]),
    );
  }

  Future<Map<String, dynamic>> _doStart(
    Map<String, dynamic> pod,
    String expand,
  ) async {
    final response = await toClient(pod).start(
      StartTrackingRequest()
        ..expand.addAll(
          toRepoFields(expand),
        ),
    );
    return toJsonCommandMeta(
      _toJsonInstanceMeta(
        k8s.toPodName(pod),
        response.meta,
      ),
      response.statusCode,
      response.reasonPhrase,
    );
  }

  Future<Response> doStop(
    Map<String, dynamic> pod,
    String expand,
  ) async {
    final meta = await _doStop(pod, expand);
    if (pod.hasPath('metrics')) {
      meta['metrics'] = toPodMetrics(
        modules.first,
        pod,
      );
    }
    return toResponse(
      body: meta,
      method: 'doStop',
      name: k8s.toPodName(pod),
      args: {'expand': expand},
      statusCode: toStatusCode([meta]),
    );
  }

  Future<Map<String, dynamic>> _doStop(
    Map<String, dynamic> pod,
    String expand,
  ) async {
    final response = await toClient(pod).stop(
      StopTrackingRequest()
        ..expand.addAll(
          toRepoFields(expand),
        ),
    );
    return toJsonCommandMeta(
      _toJsonInstanceMeta(
        k8s.toPodName(pod),
        response.meta,
      ),
      response.statusCode,
      response.reasonPhrase,
    );
  }

  Future<Response> doAddTrackings(
    Map<String, dynamic> pod,
    List<String> uuids,
    String expand,
  ) async {
    final name = k8s.toPodName(pod);
    final args = {
      'command': 'add_trackings',
      'uuids': uuids,
      'expand': expand,
    };
    if (uuids.isEmpty) {
      return toResponse(
        name: name,
        args: args,
        method: 'doAddTrackings',
        statusCode: HttpStatus.badRequest,
        body: "One ore more tracing uuids are required ('uuids' was empty)",
      );
    }
    final response = await toClient(pod).addTrackings(
      AddTrackingsRequest()
        ..uuids.addAll(uuids)
        ..expand.addAll(
          toRepoFields(expand),
        ),
    );
    final meta = _toJsonInstanceMeta(
      k8s.toPodName(pod),
      response.meta,
    );
    if (pod.hasPath('metrics')) {
      meta['metrics'] = toPodMetrics(
        modules.first,
        pod,
      );
    }
    return toResponse(
      name: name,
      args: args,
      method: 'doAddTrackings',
      body: toJsonCommandMeta(
        meta,
        response.statusCode,
        response.reasonPhrase,
        () => {
          'failed': response.failed,
          'statusCode': response.statusCode,
          'reasonPhrase': response.reasonPhrase,
        },
      ),
      statusCode: response.statusCode,
    );
  }

  Future<Response> doRemoveTrackings(
    Map<String, dynamic> pod,
    List<String> uuids,
    String expand,
  ) async {
    final name = k8s.toPodName(pod);
    final args = {
      'command': 'remove_trackings',
      'uuids': uuids,
      'expand': expand,
    };
    if (uuids.isEmpty) {
      return toResponse(
        name: name,
        args: args,
        method: 'doRemoveTrackings',
        statusCode: HttpStatus.badRequest,
        body: "One ore more tracing uuids are required ('uuids' was empty)",
      );
    }
    final response = await toClient(pod).removeTrackings(
      RemoveTrackingsRequest()
        ..uuids.addAll(uuids)
        ..expand.addAll(
          toRepoFields(expand),
        ),
    );
    final meta = _toJsonInstanceMeta(
      k8s.toPodName(pod),
      response.meta,
    );
    if (pod.hasPath('metrics')) {
      meta['metrics'] = toPodMetrics(
        modules.first,
        pod,
      );
    }
    return toResponse(
      name: name,
      args: args,
      method: 'doRemoveTrackings',
      body: toJsonCommandMeta(
        meta,
        response.statusCode,
        response.reasonPhrase,
        () => {
          'failed': response.failed,
          'statusCode': response.statusCode,
          'reasonPhrase': response.reasonPhrase,
        },
      ),
      statusCode: response.statusCode,
    );
  }

  SarSysTrackingServiceClient toClient(
    Map<String, dynamic> pod, {
    Duration timeout = const Duration(
      seconds: 30,
    ),
  }) {
    final uri = k8s.toPodUri(
      pod,
      port: config.tracking.grpcPort,
    );
    final channel = channels.putIfAbsent(
      uri.authority,
      () => ClientChannel(
        uri.host,
        port: uri.port,
        options: const ChannelOptions(
          credentials: ChannelCredentials.insecure(),
        ),
      ),
    );
    final client = SarSysTrackingServiceClient(
      channel,
      options: CallOptions(
        timeout: timeout,
      ),
    );
    logger.fine(
      Context.toMethod('toClient', [
        'host: ${channel.host}',
        'port: ${channel.port}',
      ]),
    );
    return client;
  }

  Future<Map<String, dynamic>> _getPod(String name, bool metrics) {
    return k8s.getPod(
      k8s.namespace,
      name,
      metrics: metrics,
    );
  }

  Map<String, dynamic> _toJsonInstanceMeta(String name, GetTrackingMetaResponse meta) {
    return toProto3JsonInstanceMeta(
      name,
      meta,
      (json) => json
        ..update(
          'status',
          (value) => capitalize(enumName(meta.status).split('_').last),
          ifAbsent: () => 'None',
        ),
    );
  }

  //////////////////////////////////
  // Documentation
  //////////////////////////////////

  @override
  Map<String, APISchemaObject> documentCommandParams(APIDocumentContext context) => {};

  @override
  Map<String, APISchemaObject> documentInstanceCommandParams(APIDocumentContext context) => {
        'uuids': APISchemaObject.array(ofType: APIType.string)
          ..description = 'List of aggregate uuids which command applies to',
      };

  @override
  APISchemaObject documentInstanceMeta(APIDocumentContext context) {
    return APISchemaObject.object({
      'name': APISchemaObject.string()
        ..description = 'Tracking service instance name'
        ..isReadOnly = true,
      'status': APISchemaObject.string()
        ..description = 'Tracking service status'
        ..enumerated = [
          'none',
          'ready',
          'started',
          'stopped',
          'disposed',
        ]
        ..isReadOnly = true,
      'trackings': documentTrackingsMeta(context),
      'positions': documentPositionsMeta(context),
      'managerOf': APISchemaObject.array(
        ofSchema: documentTrackingMeta(context),
      )
        ..description = 'List of metadata for managed tracking objects'
        ..isReadOnly = true,
      'repository': documentRepositoryMeta(context)
    });
  }

  APISchemaObject documentTrackingsMeta(APIDocumentContext context) => APISchemaObject.object({
        'total': APISchemaObject.integer()
          ..description = 'Total number of trackings heard'
          ..isReadOnly = true,
        'fractionManaged': APISchemaObject.integer()
          ..description = 'Number of managed tracking object to total number of tracking objects'
          ..isReadOnly = true,
        'eventsPerMinute': APISchemaObject.integer()
          ..description = 'Number of tracking events processed per minute'
          ..isReadOnly = true,
        'averageProcessingTimeMillis': APISchemaObject.number()
          ..description = 'Average processing time in milliseconds'
          ..isReadOnly = true,
        'lastEvent': documentEvent(context)
          ..description = 'Last event applied to tracking object'
          ..isReadOnly = true,
      })
        ..description = 'Tracking processing metadata'
        ..isReadOnly = true;

  APISchemaObject documentPositionsMeta(APIDocumentContext context) => APISchemaObject.object({
        'total': APISchemaObject.integer()
          ..description = 'Total number of positions heard'
          ..isReadOnly = true,
        'eventsPerMinute': APISchemaObject.integer()
          ..description = 'Number of positions processed per minute'
          ..isReadOnly = true,
        'averageProcessingTimeMillis': APISchemaObject.number()
          ..description = 'Average processing time in milliseconds'
          ..isReadOnly = true,
        'lastEvent': documentEvent(context)
          ..description = 'Last event applied to track in tracking object'
          ..isReadOnly = true,
      })
        ..description = 'Position processing metadata'
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
