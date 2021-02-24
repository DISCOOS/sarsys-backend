import 'package:event_source_grpc/event_source_grpc.dart';
import 'package:grpc/grpc.dart' hide Response;
import 'package:grpc/grpc_connection_interface.dart';
import 'package:sarsys_ops_server/sarsys_ops_server.dart';
import 'package:sarsys_ops_server/src/config.dart';
import 'package:sarsys_core/sarsys_core.dart';

import 'component_base_controller.dart';

class RepositoryGrpcServiceController extends ComponentBaseController {
  RepositoryGrpcServiceController(
    this.k8s,
    this.channels,
    SarSysOpsConfig config,
    Map<String, dynamic> context,
  ) : super(
          'RepositoryService',
          config,
          options: [
            'all',
            'data',
            'items',
            'queue',
            'metrics',
            'snapshot',
            'connection',
          ],
          actions: [
            'replay_all',
            'repair_all',
            'catchup_all',
            'rebuild_all',
          ],
          instanceOptions: [
            'all',
            'data',
            'items',
            'queue',
            'metrics',
            'snapshot',
            'connection',
          ],
          instanceActions: [
            'replay',
            'repair',
            'catchup',
            'rebuild',
          ],
          tag: 'Repository service',
          context: context,
          modules: [
            'sarsys-app-server',
            'sarsys-tracking-server',
          ],
        );

  final K8sApi k8s;
  final Map<String, ClientChannel> channels;

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
    final pods = await k8s.getPodList(
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
      method: 'doGetMetaByNameAndType',
    );
  }

  Future<Map<String, dynamic>> _doGetMetaByType(
    String type,
    Map<String, dynamic> pod,
    String expand,
  ) async {
    final response = await toClient(pod).getMeta(
      GetRepoMetaRequest()
        ..type = type
        ..expand.addAll(
          toExpandFields(expand),
        ),
    );
    return toProto3JsonInstanceMeta(
      k8s.toPodName(pod),
      response.meta,
    );
  }

  List<RepoExpandFields> toExpandFields(String expand) {
    return [
      if (shouldExpand(expand, 'all')) RepoExpandFields.REPO_EXPAND_FIELDS_ALL,
      if (shouldExpand(expand, 'data')) RepoExpandFields.REPO_EXPAND_FIELDS_DATA,
      if (shouldExpand(expand, 'items')) RepoExpandFields.REPO_EXPAND_FIELDS_ITEMS,
      if (shouldExpand(expand, 'queue')) RepoExpandFields.REPO_EXPAND_FIELDS_QUEUE,
      if (shouldExpand(expand, 'metrics')) RepoExpandFields.REPO_EXPAND_FIELDS_METRICS,
      if (shouldExpand(expand, 'connection')) RepoExpandFields.REPO_EXPAND_FIELDS_CONN,
      if (shouldExpand(expand, 'snapshot')) RepoExpandFields.REPO_EXPAND_FIELDS_SNAPSHOT,
    ];
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
    final pods = await k8s.getPodList(
      k8s.namespace,
      labels: toModuleLabels(),
    );
    switch (command) {
      case 'replay_all':
        return doReplayAll(
          type,
          body,
          pods,
          expand,
        );
      case 'catchup_all':
        return doCatchupAll(
          type,
          body,
          pods,
          expand,
        );
      case 'repair_all':
        return doRepairAll(
          type,
          body,
          pods,
          expand,
        );
      case 'rebuild_all':
        return doRebuildAll(
          type,
          body,
          pods,
          expand,
        );
    }
    return toResponse(
      type: type,
      uuids: body.listAt(
        'params/uuids',
        defaultList: [],
      ),
      method: 'doExecuteByType',
      statusCode: HttpStatus.badRequest,
      names: pods.map(k8s.toPodName).toList(),
      args: {'command': command, 'expand': expand},
      body: "$target command '$command' not supported",
    );
  }

  Future<Response> doReplayAll(
    String type,
    Map<String, dynamic> body,
    List<Map<String, dynamic>> pods,
    String expand,
  ) async {
    final names = <String>[];
    final items = <Map<String, dynamic>>[];
    final uuids = body.listAt<String>(
      'params/uuids',
      defaultList: [],
    );
    for (var pod in pods) {
      final meta = await _doReplay(
        type,
        uuids,
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
      uuids: uuids,
      names: names,
      method: 'doReplayAll',
      body: toJsonItemsMeta(
        items,
      ),
      args: {
        'command': 'replay_all',
        'expand': expand,
      },
      statusCode: toStatusCode(items),
    );
  }

  Future<Response> doCatchupAll(
    String type,
    Map<String, dynamic> body,
    List<Map<String, dynamic>> pods,
    String expand,
  ) async {
    final names = <String>[];
    final items = <Map<String, dynamic>>[];
    final uuids = body.listAt<String>(
      'params/uuids',
      defaultList: [],
    );
    for (var pod in pods) {
      final meta = await _doCatchup(
        type,
        uuids,
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
      uuids: uuids,
      method: 'doCatchupAll',
      body: toJsonItemsMeta(
        items,
      ),
      args: {
        'command': 'catchup_all',
        'expand': expand,
      },
      statusCode: toStatusCode(items),
    );
  }

  Future<Response> doRepairAll(
    String type,
    Map<String, dynamic> body,
    List<Map<String, dynamic>> pods,
    String expand,
  ) async {
    final names = <String>[];
    final items = <Map<String, dynamic>>[];
    final master = body.elementAt<bool>(
      'params/master',
      defaultValue: true,
    );
    for (var pod in pods) {
      final meta = await _doRepair(
        type,
        pod,
        master,
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
      method: 'doRepairAll',
      body: toJsonItemsMeta(
        items,
      ),
      args: {
        'command': 'repair_all',
        'master': master,
        'expand': expand,
      },
      statusCode: toStatusCode(items),
    );
  }

  Future<Response> doRebuildAll(
    String type,
    Map<String, dynamic> body,
    List<Map<String, dynamic>> pods,
    String expand,
  ) async {
    final names = <String>[];
    final items = <Map<String, dynamic>>[];
    final master = body.elementAt<bool>(
      'params/master',
      defaultValue: true,
    );
    for (var pod in pods) {
      final meta = await _doRebuild(
        type,
        pod,
        master,
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
      method: 'doRebuildAll',
      body: toJsonItemsMeta(
        items,
      ),
      args: {
        'command': 'rebuild_all',
        'master': master,
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
      case 'replay':
        return doReplay(type, pod, body, expand);
      case 'catchup':
        return doCatchup(type, pod, body, expand);
      case 'repair':
        return doRepair(type, pod, body, expand);
      case 'rebuild':
        return doRebuild(type, pod, body, expand);
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

  Future<Response> doReplay(
    String type,
    Map<String, dynamic> pod,
    Map<String, dynamic> body,
    String expand,
  ) async {
    final uuids = body.listAt<String>(
      'params/uuids',
      defaultList: [],
    );
    final meta = await _doReplay(
      type,
      uuids,
      pod,
      expand,
    );
    return toResponse(
      type: type,
      body: meta,
      uuids: uuids,
      method: 'doReplay',
      args: {
        'command': 'replay',
        'expand': expand,
      },
      name: k8s.toPodName(pod),
      statusCode: toStatusCode([meta]),
    );
  }

  Future<Map<String, dynamic>> _doReplay(
    String type,
    List<String> uuids,
    Map<String, dynamic> pod,
    String expand,
  ) async {
    final response = await toClient(
      pod,
      timeout: const Duration(
        minutes: 2,
      ),
    ).replayEvents(
      ReplayRepoEventsRequest()
        ..type = type
        ..uuids.addAll(
          uuids,
        )
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

  Future<Response> doCatchup(
    String type,
    Map<String, dynamic> pod,
    Map<String, dynamic> body,
    String expand,
  ) async {
    final uuids = body.listAt<String>(
      'params/uuids',
      defaultList: [],
    );
    final meta = await _doCatchup(
      type,
      uuids,
      pod,
      expand,
    );
    return toResponse(
      type: type,
      body: meta,
      uuids: uuids,
      method: 'doCatchup',
      args: {
        'command': 'catchup',
        'expand': expand,
      },
      name: k8s.toPodName(pod),
      statusCode: toStatusCode([meta]),
    );
  }

  Future<Map<String, dynamic>> _doCatchup(
    String type,
    List<String> uuids,
    Map<String, dynamic> pod,
    String expand,
  ) async {
    final response = await toClient(
      pod,
      timeout: const Duration(
        minutes: 2,
      ),
    ).catchupEvents(
      CatchupRepoEventsRequest()
        ..type = type
        ..uuids.addAll(
          uuids,
        )
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

  Future<Response> doRepair(
    String type,
    Map<String, dynamic> pod,
    Map<String, dynamic> body,
    String expand,
  ) async {
    final name = k8s.toPodName(pod);
    final master = body.elementAt<bool>(
      'params/master',
      defaultValue: true,
    );
    final args = {
      'command': 'repair',
      'master': master,
      'expand': expand,
    };
    final meta = await _doRepair(
      type,
      pod,
      master,
      expand,
    );

    return toResponse(
      name: name,
      type: type,
      args: args,
      method: 'doRepair',
      body: meta,
      statusCode: toStatusCode([meta]),
    );
  }

  Future<Map<String, dynamic>> _doRepair(
    String type,
    Map<String, dynamic> pod,
    bool master,
    String expand,
  ) async {
    final response = await toClient(
      pod,
      timeout: const Duration(
        minutes: 2,
      ),
    ).repair(
      RepairRepoRequest()
        ..type = type
        ..master = master
        ..expand.addAll(toExpandFields(expand)),
    );
    final json = toJsonCommandMeta(
      toProto3JsonInstanceMeta(
        k8s.toPodName(pod),
        response.meta,
      ),
      response.statusCode,
      response.reasonPhrase,
    );
    json['after'] = toProto3Json(
      response.after,
    );
    json['before'] = toProto3Json(
      response.before,
    );
    return json;
  }

  Future<Response> doRebuild(
    String type,
    Map<String, dynamic> pod,
    Map<String, dynamic> body,
    String expand,
  ) async {
    final name = k8s.toPodName(pod);
    final master = body.elementAt<bool>(
      'params/master',
      defaultValue: true,
    );
    final args = {
      'command': 'rebuild',
      'master': master,
      'expand': expand,
    };
    final meta = await _doRebuild(
      type,
      pod,
      master,
      expand,
    );

    return toResponse(
      name: name,
      type: type,
      args: args,
      method: 'doRebuild',
      body: meta,
      statusCode: toStatusCode([meta]),
    );
  }

  Future<Map<String, dynamic>> _doRebuild(
    String type,
    Map<String, dynamic> pod,
    bool master,
    String expand,
  ) async {
    final response = await toClient(
      pod,
      timeout: const Duration(
        minutes: 2,
      ),
    ).rebuild(
      RebuildRepoRequest()
        ..type = type
        ..master = master
        ..expand.addAll(toExpandFields(expand)),
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

  RepositoryGrpcServiceClient toClient(
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
    final client = RepositoryGrpcServiceClient(
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

  Future<Map<String, dynamic>> _getPod(String name) async {
    return await k8s.getPod(
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
        'uuids': APISchemaObject.array(ofType: APIType.string)
          ..description = 'List of aggregate uuids which command applies to',
      };

  @override
  APISchemaObject documentInstanceMeta(APIDocumentContext context) => documentRepositoryMeta(context);
}
