import 'package:event_source_grpc/event_source_grpc.dart';
import 'package:grpc/grpc.dart' hide Response;
import 'package:grpc/grpc_connection_interface.dart';
import 'package:protobuf/protobuf.dart';
import 'package:sarsys_ops_server/sarsys_ops_server.dart';
import 'package:sarsys_ops_server/src/config.dart';
import 'package:sarsys_core/sarsys_core.dart';

import 'component_base_controller.dart';

class AggregateGrpcServiceController extends ComponentBaseController {
  AggregateGrpcServiceController(
    this.k8s,
    this.channels,
    SarSysOpsConfig config,
    Map<String, dynamic> context,
  ) : super(
          'AggregateService',
          config,
          options: [
            'all',
            'data',
            'items',
          ],
          actions: [
            'replay_all',
            'catchup_all',
            'replace_all',
          ],
          instanceOptions: [
            'all',
            'data',
            'items',
          ],
          instanceActions: [
            'replay',
            'catchup',
            'replace',
          ],
          tag: 'Aggregate Service',
          context: context,
          modules: [
            'sarsys-app-server',
            'sarsys-tracking-server',
          ],
        );

  final K8sApi k8s;
  final Map<String, ClientChannel> channels;
  final Map<String, AggregateGrpcServiceClient> _clients = {};

  @override
  @Scope(['roles:admin'])
  @Operation.get('type', 'uuid')
  Future<Response> getMetaByTypeAndUuid(
    @Bind.path('type') String type,
    @Bind.path('uuid') String uuid, {
    @Bind.query('expand') String expand,
  }) {
    return super.getMetaByTypeAndUuid(
      type,
      uuid,
      expand: expand,
    );
  }

  @override
  Future<Response> doGetMetaByTypeAndUuid(
    String type,
    String uuid,
    String expand,
  ) async {
    final names = [];
    final pods = await k8s.getPodList(
      k8s.namespace,
      labels: toModuleLabels(),
    );
    final items = <Map<String, dynamic>>[];
    for (var pod in pods) {
      final meta = await _doGetMetaByTypeAndUuid(
        type,
        uuid,
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
      uuid: uuid,
      name: '$names',
      body: toJsonItemsMeta(
        items,
      ),
      args: {'expand': expand},
      statusCode: toStatusCode(items),
      method: 'doGetMetaByTypeAndUuid',
    );
  }

  @override
  @Scope(['roles:admin'])
  @Operation.get('type', 'uuid', 'name')
  Future<Response> getMetaByNameTypeAndUuid(
    @Bind.path('name') String name,
    @Bind.path('type') String type,
    @Bind.path('uuid') String uuid, {
    @Bind.query('expand') String expand,
  }) {
    return super.getMetaByNameTypeAndUuid(
      name,
      type,
      uuid,
      expand: expand,
    );
  }

  @override
  Future<Response> doGetMetaByNameTypeAndUuid(
    String name,
    String type,
    String uuid,
    String expand,
  ) async {
    final pod = await _getPod(
      name,
    );
    if (pod?.isNotEmpty != true) {
      return toResponse(
        name: name,
        type: type,
        uuid: uuid,
        args: {'expand': expand},
        statusCode: HttpStatus.notFound,
        method: 'doGetMetaByNameTypeAndUuid',
        body: "$target instance '$name' not found",
      );
    }
    final meta = await _doGetMetaByTypeAndUuid(
      type,
      uuid,
      pod,
      expand,
    );
    return toResponse(
      name: name,
      type: type,
      uuid: uuid,
      body: meta,
      args: {'expand': expand},
      statusCode: meta.elementAt<int>(
        'error/statusCode',
        defaultValue: HttpStatus.ok,
      ),
      method: 'doGetMetaByNameTypeAndUuid',
    );
  }

  Future<Map<String, dynamic>> _doGetMetaByTypeAndUuid(
    String type,
    String uuid,
    Map<String, dynamic> pod,
    String expand,
  ) async {
    final response = await toClient(pod).getMeta(
      GetAggregateMetaRequest()
        ..type = type
        ..uuid = uuid
        ..expand.addAll(
          toExpandFields(expand),
        ),
    );
    return toProto3JsonInstanceMeta(
      k8s.toPodName(pod),
      response.meta,
    );
  }

  @override
  Map<String, dynamic> toProto3JsonInstanceMeta(
    String name,
    GeneratedMessage meta, [
    Map<String, dynamic> Function(Map<String, dynamic>) map,
  ]) {
    return super.toProto3JsonInstanceMeta(
      name, meta, // Replace JsonValue
      (json) => map == null
          ? (json
            ..update(
              'data',
              (value) => value['data'],
            ))
          : map(json),
    );
  }

  List<AggregateExpandFields> toExpandFields(String expand) {
    return [
      if (shouldExpand(expand, 'all')) AggregateExpandFields.AGGREGATE_EXPAND_FIELDS_ALL,
      if (shouldExpand(expand, 'data')) AggregateExpandFields.AGGREGATE_EXPAND_FIELDS_DATA,
      if (shouldExpand(expand, 'items')) AggregateExpandFields.AGGREGATE_EXPAND_FIELDS_ITEMS,
    ];
  }

  @override
  @Scope(['roles:admin'])
  @Operation.post('type', 'uuid')
  Future<Response> executeByTypeAndUuid(
    @Bind.path('type') String type,
    @Bind.path('uuid') String uuid,
    @Bind.body() Map<String, dynamic> body, {
    @Bind.query('expand') String expand,
  }) =>
      super.executeByTypeAndUuid(
        type,
        uuid,
        body,
        expand: expand,
      );

  @override
  Future<Response> doExecuteByTypeAndUuid(
    String type,
    String uuid,
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
          uuid,
          pods,
          expand,
        );
      case 'catchup_all':
        return doCatchupAll(
          type,
          uuid,
          pods,
          expand,
        );
      case 'replace_all':
        final data = body.mapAt<String, dynamic>('params/data');
        if (data == null) {
          return toResponse(
            type: type,
            uuid: uuid,
            method: 'doExecuteByTypeAndUuid',
            statusCode: HttpStatus.badRequest,
            names: pods.map(k8s.toPodName).toList(),
            args: {'command': command, 'expand': expand},
            body: "param 'data' in $target command 'replace' is required",
          );
        }
        return doReplaceAll(
          type,
          uuid,
          data,
          pods,
          expand,
        );
    }
    return toResponse(
      type: type,
      uuid: uuid,
      method: 'doExecuteByTypeAndUuid',
      statusCode: HttpStatus.badRequest,
      names: pods.map(k8s.toPodName).toList(),
      args: {'command': command, 'expand': expand},
      body: "$target command '$command' not supported",
    );
  }

  Future<Response> doReplayAll(
    String type,
    String uuid,
    List<Map<String, dynamic>> pods,
    String expand,
  ) async {
    final names = [];
    final items = <Map<String, dynamic>>[];
    for (var pod in pods) {
      final meta = await _doReplay(
        type,
        uuid,
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
      uuid: uuid,
      name: '$names',
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
    String uuid,
    List<Map<String, dynamic>> pods,
    String expand,
  ) async {
    final names = [];
    final items = <Map<String, dynamic>>[];
    for (var pod in pods) {
      final meta = await _doCatchup(
        type,
        uuid,
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
      uuid: uuid,
      name: '$names',
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

  Future<Response> doReplaceAll(
    String type,
    String uuid,
    Map<String, dynamic> data,
    List<Map<String, dynamic>> pods,
    String expand,
  ) async {
    final names = [];
    final items = <Map<String, dynamic>>[];

    for (var pod in pods) {
      final meta = await _doReplace(
        type,
        uuid,
        pod,
        data,
        expand,
      );
      items.add(meta);
      names.add(
        k8s.toPodName(pod),
      );
    }
    return toResponse(
      type: type,
      uuid: uuid,
      name: '$names',
      method: 'doReplaceAll',
      body: toJsonItemsMeta(
        items,
      ),
      args: {
        'command': 'replace_all',
        'expand': expand,
      },
      statusCode: toStatusCode(items),
    );
  }

  @override
  @Scope(['roles:admin'])
  @Operation.post('type', 'uuid', 'name')
  Future<Response> executeByNameTypeAndUuid(
    @Bind.path('name') String name,
    @Bind.path('type') String type,
    @Bind.path('uuid') String uuid,
    @Bind.body() Map<String, dynamic> body, {
    @Bind.query('expand') String expand,
  }) {
    return super.executeByNameTypeAndUuid(
      name,
      type,
      uuid,
      body,
      expand: expand,
    );
  }

  @override
  Future<Response> doExecuteByNameTypeAndUuid(
    String name,
    String type,
    String uuid,
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
        uuid: uuid,
        args: {'expand': expand},
        statusCode: HttpStatus.notFound,
        method: 'doExecuteByNameTypeAndUuid',
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
        uuid: uuid,
        args: args,
        statusCode: HttpStatus.notFound,
        method: 'doExecuteByNameTypeAndUuid',
        body: "$target instance '$name' not found",
      );
    }
    switch (command) {
      case 'replay':
        return doReplay(type, uuid, pod, expand);
      case 'catchup':
        return doCatchup(type, uuid, pod, expand);
      case 'replace':
        return doReplace(type, uuid, pod, body, expand);
    }
    return toResponse(
      name: name,
      type: type,
      uuid: uuid,
      args: args,
      statusCode: HttpStatus.badRequest,
      method: 'doExecuteByNameTypeAndUuid',
      body: "$target instance command '$command' not supported",
    );
  }

  Future<Response> doReplay(
    String type,
    String uuid,
    Map<String, dynamic> pod,
    String expand,
  ) async {
    final meta = await _doReplay(
      type,
      uuid,
      pod,
      expand,
    );
    return toResponse(
      type: type,
      uuid: uuid,
      body: meta,
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
    String uuid,
    Map<String, dynamic> pod,
    String expand,
  ) async {
    final response = await toClient(pod).replayEvents(
      ReplayAggregateEventsRequest()
        ..type = type
        ..uuid = uuid
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
    String uuid,
    Map<String, dynamic> pod,
    String expand,
  ) async {
    final meta = await _doCatchup(
      type,
      uuid,
      pod,
      expand,
    );
    return toResponse(
      type: type,
      uuid: uuid,
      body: meta,
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
    String uuid,
    Map<String, dynamic> pod,
    String expand,
  ) async {
    final response = await toClient(pod).catchupEvents(
      CatchupAggregateEventsRequest()
        ..type = type
        ..uuid = uuid
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

  Future<Response> doReplace(
    String type,
    String uuid,
    Map<String, dynamic> pod,
    Map<String, dynamic> body,
    String expand,
  ) async {
    final name = k8s.toPodName(pod);
    final args = {
      'command': 'replace',
      'expand': expand,
    };
    final data = body.mapAt<String, dynamic>('params/data');
    if (data == null) {
      return toResponse(
        name: name,
        type: type,
        uuid: uuid,
        args: args,
        method: 'doReplace',
        statusCode: HttpStatus.badRequest,
        body: "param 'data' in $target instance command 'replace' is required",
      );
    }
    final meta = await _doReplace(
      type,
      uuid,
      pod,
      data,
      expand,
    );

    return toResponse(
      name: name,
      type: type,
      uuid: uuid,
      args: args,
      method: 'doReplace',
      body: meta,
      statusCode: toStatusCode([meta]),
    );
  }

  Future<Map<String, dynamic>> _doReplace(
    String type,
    String uuid,
    Map<String, dynamic> pod,
    Map<String, dynamic> data,
    String expand,
  ) async {
    final response = await toClient(pod).replaceData(
      ReplaceAggregateDataRequest()
        ..type = type
        ..uuid = uuid
        ..data = toAnyFromJson(
          data,
        )
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

  AggregateGrpcServiceClient toClient(Map<String, dynamic> pod) {
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
      () => AggregateGrpcServiceClient(
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
    return await k8s.getPod(
      k8s.namespace,
      name,
    );
  }

  //////////////////////////////////
  // Documentation
  //////////////////////////////////

  @override
  Map<String, APISchemaObject> documentInstanceCommandParams(APIDocumentContext context) => {
        'data': APISchemaObject.freeForm()..description = 'Aggregate data',
      };

  @override
  APISchemaObject documentInstanceMeta(APIDocumentContext context) => documentAggregate(context);
}
