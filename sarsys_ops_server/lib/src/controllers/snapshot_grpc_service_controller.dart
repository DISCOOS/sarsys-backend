import 'package:event_source_grpc/event_source_grpc.dart';
import 'package:grpc/grpc.dart' hide Response;
import 'package:grpc/grpc_connection_interface.dart';
import 'package:sarsys_ops_server/sarsys_ops_server.dart';
import 'package:sarsys_ops_server/src/config.dart';
import 'package:sarsys_core/sarsys_core.dart';

import 'component_base_controller.dart';

class SnapshotGrpcServiceController extends ComponentBaseController {
  SnapshotGrpcServiceController(
    this.k8s,
    this.channels,
    SarSysOpsConfig config,
    Map<String, dynamic> context,
  ) : super(
          'SnapshotService',
          config,
          options: [
            'all',
            'data',
            'items',
            'metrics',
          ],
          actions: [
            'save_all',
            'upload_all',
            'configure_all',
          ],
          instanceOptions: [
            'all',
            'data',
            'items',
            'metrics',
          ],
          instanceActions: [
            'save',
            'configure',
          ],
          tag: 'Services',
          context: context,
          modules: [
            'sarsys-app-server',
            'sarsys-tracking-server',
          ],
        );

  final K8sApi k8s;
  final Map<String, ClientChannel> channels;
  final Map<String, SnapshotGrpcServiceClient> _clients = {};

  @override
  @Scope(['roles:admin'])
  @Operation.get('type')
  Future<Response> getMetaByType(
    @Bind.path('type') String type, {
    @Bind.query('expand') String expand,
  }) {
    return super.getMetaByType(
      type,
      expand: expand,
    );
  }

  @override
  Future<Response> doGetMetaByType(
    String type,
    String expand,
  ) async {
    final names = <String>[];
    final pods = await k8s.getPodsFromNs(
      k8s.namespace,
      labels: toModuleLabels(),
    );
    final items = <Map<String, dynamic>>[];
    for (var pod in pods) {
      final meta = await _doGetMetaByType(
        type,
        pod,
        expand,
      );
      items.add(meta);
      names.add(
        k8s.toPodName(pod),
      );
    }
    return toResponse(
      type: type,
      names: names,
      body: toJsonItemsMeta(
        items,
      ),
      args: {'expand': expand},
      statusCode: toStatusCode(items),
      method: 'doGetMetaByType',
    );
  }

  @override
  @Scope(['roles:admin'])
  @Operation.get('type', 'name')
  Future<Response> getMetaByNameAndType(
    @Bind.path('name') String name,
    @Bind.path('type') String type, {
    @Bind.query('expand') String expand,
  }) {
    return super.getMetaByNameAndType(
      name,
      type,
      expand: expand,
    );
  }

  @override
  Future<Response> doGetMetaByNameAndType(
    String name,
    String type,
    String expand,
  ) async {
    final pod = await _getPod(
      name,
    );
    if (pod?.isNotEmpty != true) {
      return toResponse(
        name: name,
        type: type,
        args: {'expand': expand},
        statusCode: HttpStatus.notFound,
        method: 'doGetMetaByNameAndType',
        body: "$target instance '$name' not found",
      );
    }
    final meta = await _doGetMetaByType(
      type,
      pod,
      expand,
    );
    return toResponse(
      name: name,
      type: type,
      body: meta,
      args: {'expand': expand},
      statusCode: meta.elementAt<int>(
        'error/statusCode',
        defaultValue: HttpStatus.ok,
      ),
      method: 'doGetMetaByNameTypeAndUuid',
    );
  }

  Future<Map<String, dynamic>> _doGetMetaByType(
    String type,
    Map<String, dynamic> pod,
    String expand,
  ) async {
    final response = await toClient(pod).getMeta(
      GetSnapshotMetaRequest()
        ..type = type
        ..expand.addAll(
          toExpandFields(expand),
        ),
    );
    return toJsonCommandMeta(
      toProto3JsonInstanceMeta(
        k8s.toPodName(pod),
        response.meta,
      ),
      response.statusCode,
      response.reasonPhrase,
    );
  }

  List<SnapshotExpandFields> toExpandFields(String expand) {
    return [
      if (shouldExpand(expand, 'all')) SnapshotExpandFields.SNAPSHOT_EXPAND_FIELDS_ALL,
      if (shouldExpand(expand, 'data')) SnapshotExpandFields.SNAPSHOT_EXPAND_FIELDS_DATA,
      if (shouldExpand(expand, 'items')) SnapshotExpandFields.SNAPSHOT_EXPAND_FIELDS_ITEMS,
      if (shouldExpand(expand, 'metrics')) SnapshotExpandFields.SNAPSHOT_EXPAND_FIELDS_METRICS,
    ];
  }

  @override
  String parseActionFromUri() {
    final variableCount = request.path.variables.length;
    final all = variableCount == 1;
    final segmentCount = request.path.segments.length;
    final action = request.path.segments[segmentCount - variableCount];
    return const ['upload', 'download'].contains(action) ? (all ? '${action}_all' : action) : null;
  }

  @override
  @Scope(['roles:admin'])
  @Operation.post('type')
  Future<Response> executeByType(
    @Bind.path('type') String type,
    @Bind.body() Map<String, dynamic> body, {
    @Bind.query('expand') String expand,
  }) =>
      super.executeByType(
        type,
        body,
        expand: expand,
      );

  @override
  Future<Response> doExecuteByType(
    String type,
    String command,
    Map<String, dynamic> body,
    String expand,
  ) async {
    final pods = await k8s.getPodsFromNs(
      k8s.namespace,
      labels: toModuleLabels(),
    );
    switch (command) {
      case 'save_all':
        return doSaveAll(
          type,
          body,
          pods,
          expand,
        );
      case 'configure_all':
        return doConfigureAll(
          type,
          body,
          pods,
          expand,
        );
    }
    return toResponse(
      type: type,
      method: 'doExecuteByType',
      statusCode: HttpStatus.badRequest,
      names: pods.map(k8s.toPodName).toList(),
      args: {'command': command, 'expand': expand},
      body: "$target command '$command' not supported",
    );
  }

  Future<Response> doSaveAll(
    String type,
    Map<String, dynamic> body,
    List<Map<String, dynamic>> pods,
    String expand,
  ) async {
    final names = <String>[];
    final items = <Map<String, dynamic>>[];
    final force = body.elementAt<bool>(
      'params/force',
      defaultValue: false,
    );
    for (var pod in pods) {
      final meta = await _doSave(
        type,
        pod,
        force,
        expand,
      );
      items.add(meta);
      names.add(
        k8s.toPodName(pod),
      );
    }
    return toResponse(
      type: type,
      names: names,
      method: 'doSaveAll',
      body: toJsonItemsMeta(
        items,
      ),
      args: {
        'command': 'save_all',
        'force': force,
        'expand': expand,
      },
      statusCode: toStatusCode(items),
    );
  }

  Future<Response> doConfigureAll(
    String type,
    Map<String, dynamic> body,
    List<Map<String, dynamic>> pods,
    String expand,
  ) async {
    final names = <String>[];
    final items = <Map<String, dynamic>>[];
    final params = body.mapAt<String, dynamic>(
      'params',
      defaultMap: {},
    );
    for (var pod in pods) {
      final meta = await _doConfigure(
        type,
        pod,
        params,
        expand,
      );
      items.add(meta);
      names.add(
        k8s.toPodName(pod),
      );
    }
    return toResponse(
      type: type,
      names: names,
      method: 'doConfigureAll',
      body: toJsonItemsMeta(
        items,
      ),
      args: {
        'command': 'configure_all',
        ...params,
        'expand': expand,
      },
      statusCode: toStatusCode(items),
    );
  }

  @override
  @Scope(['roles:admin'])
  @Operation.post('type', 'name')
  Future<Response> executeByNameAndType(
    @Bind.path('name') String name,
    @Bind.path('type') String type,
    @Bind.body() Map<String, dynamic> body, {
    @Bind.query('expand') String expand,
  }) {
    return super.executeByNameAndType(
      name,
      type,
      body,
      expand: expand,
    );
  }

  @override
  Future<Response> doExecuteByNameAndType(
    String name,
    String type,
    String command,
    Map<String, dynamic> body,
    String expand,
  ) async {
    final pod = await _getPod(
      name,
    );
    if (pod?.isNotEmpty != true) {
      return toResponse(
        name: name,
        type: type,
        args: {'expand': expand},
        statusCode: HttpStatus.notFound,
        method: 'doExecuteByNameAndType',
        body: "$target instance '$name' not found",
      );
    }
    final args = {
      'command': command,
      'body': body,
      'expand': expand,
    };
    if (pod == null) {
      return toResponse(
        name: name,
        type: type,
        args: args,
        statusCode: HttpStatus.notFound,
        method: 'doExecuteByNameAndType',
        body: "$target instance '$name' not found",
      );
    }
    switch (command) {
      case 'save':
        return doSave(type, pod, body, expand);
      case 'configure':
        return doConfigure(type, pod, body, expand);
    }
    return toResponse(
      name: name,
      type: type,
      args: args,
      statusCode: HttpStatus.badRequest,
      method: 'doExecuteByNameAndType',
      body: "$target instance command '$command' not supported",
    );
  }

  Future<Response> doSave(
    String type,
    Map<String, dynamic> pod,
    Map<String, dynamic> body,
    String expand,
  ) async {
    final force = body.elementAt<bool>(
      'params/force',
      defaultValue: false,
    );
    final meta = await _doSave(
      type,
      pod,
      force,
      expand,
    );
    return toResponse(
      type: type,
      body: meta,
      method: 'doSave',
      args: {
        'command': 'save',
        'force': force,
        'expand': expand,
      },
      name: k8s.toPodName(pod),
      statusCode: toStatusCode([meta]),
    );
  }

  Future<Map<String, dynamic>> _doSave(
    String type,
    Map<String, dynamic> pod,
    bool force,
    String expand,
  ) async {
    final response = await toClient(pod).save(
      SaveSnapshotRequest()
        ..type = type
        ..force = force
        ..expand.addAll(
          toExpandFields(expand),
        ),
    );
    return toJsonCommandMeta(
      toProto3JsonInstanceMeta(
        k8s.toPodName(pod),
        response.meta,
      ),
      response.statusCode,
      response.reasonPhrase,
    );
  }

  Future<Response> doConfigure(
    String type,
    Map<String, dynamic> pod,
    Map<String, dynamic> body,
    String expand,
  ) async {
    final name = k8s.toPodName(pod);
    final params = body.mapAt<String, dynamic>(
      'params',
      defaultMap: {},
    );
    final args = {
      'command': 'configure',
      ...params,
      'expand': expand,
    };
    final meta = await _doConfigure(
      type,
      pod,
      params,
      expand,
    );

    return toResponse(
      name: name,
      type: type,
      args: args,
      method: 'doConfigure',
      body: meta,
      statusCode: toStatusCode([meta]),
    );
  }

  Future<Map<String, dynamic>> _doConfigure(
    String type,
    Map<String, dynamic> pod,
    Map<String, dynamic> params,
    String expand,
  ) async {
    final request = ConfigureSnapshotRequest()
      ..type = type
      ..expand.addAll(toExpandFields(expand));

    request.setIfExists<int>(params, 'config/keep', (keep) => request.keep = keep);
    request.setIfExists<int>(params, 'config/threshold', (threshold) => request.threshold = threshold);
    request.setIfExists<bool>(params, 'config/automatic', (automatic) => request.automatic = automatic);

    final response = await toClient(pod).configure(
      request,
    );
    return toJsonCommandMeta(
      toProto3JsonInstanceMeta(
        k8s.toPodName(pod),
        response.meta,
      ),
      response.statusCode,
      response.reasonPhrase,
    );
  }

  SnapshotGrpcServiceClient toClient(Map<String, dynamic> pod) {
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
    final client = _clients.putIfAbsent(
      uri.authority,
      () => SnapshotGrpcServiceClient(
        channel,
        options: CallOptions(
          timeout: const Duration(
            seconds: 30,
          ),
        ),
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

  Future<Map<String, dynamic>> _getPod(String name) async {
    return await k8s.getPodInNs(
      k8s.namespace,
      name,
    );
  }

  //////////////////////////////////
  // Documentation
  //////////////////////////////////

  @override
  Map<String, APISchemaObject> documentCommandParams(APIDocumentContext context) =>
      documentInstanceCommandParams(context);

  @override
  Map<String, APISchemaObject> documentInstanceCommandParams(APIDocumentContext context) => {
        'force': APISchemaObject.boolean()..description = 'Force save of snapshot',
        'config': APISchemaObject.object({
          'keep': APISchemaObject.integer()..description = 'Number of snapshots to keep before deleting',
          'threshold': APISchemaObject.integer()
            ..description = 'Maximum number of events applied to repository before next snapshot is taken',
          'automatic': APISchemaObject.boolean()..description = 'Flag to activate automatic snapshots',
        })
          ..description = 'Force save of snapshot',
      };

  @override
  APISchemaObject documentInstanceMeta(APIDocumentContext context) => documentSnapshotMeta(context);
}
