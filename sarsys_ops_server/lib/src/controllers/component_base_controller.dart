import 'package:event_source_grpc/event_source_grpc.dart';
import 'package:protobuf/protobuf.dart';
import 'package:sarsys_core/sarsys_core.dart';
import 'package:sarsys_ops_server/sarsys_ops_server.dart';
import 'package:sarsys_ops_server/src/config.dart';

/// A [ResourceController] base class for module component operations requests
abstract class ComponentBaseController extends ResourceController {
  ComponentBaseController(
    this.target,
    this.config, {
    @required this.tag,
    @required this.context,
    @required this.modules,
    this.actions = const [],
    this.options = const [],
    this.instanceActions = const [],
    this.instanceOptions = const [],
  });

  final String tag;
  final String target;
  final List<String> actions;
  final List<String> options;
  final List<String> modules;
  final SarSysOpsConfig config;
  final List<String> instanceActions;
  final List<String> instanceOptions;

  final Map<String, dynamic> context;

  @override
  Logger get logger => Logger('$runtimeType');

  bool isModule(String name) => modules.contains(name);
  String toModuleLabel(String module) => 'module=$module';
  List<String> toModuleLabels() => modules.map(toModuleLabel).toList();

  String get(String key) => context[key] ?? Platform.environment[key];
  bool contains(String key) => context.containsKey(key) || Platform.environment.containsKey(key);

  int toStatusCode(List<Map<String, dynamic>> metas, {int statusCode}) {
    final errors = metas
        // Filter on error
        .where((meta) => meta.hasPath('error'))
        // Get status code
        .map((meta) => meta.elementAt<int>('error/statusCode'))
        .toList();
    return errors.isEmpty
        ? statusCode ?? HttpStatus.ok
        : (errors.length == 1 ? errors.first : HttpStatus.partialContent);
  }

  bool shouldExpand(String expand, String field) {
    final elements = expand?.split(',') ?? <String>[];
    if (elements.any((element) => element.toLowerCase().startsWith(field))) {
      return true;
    }
    elements.removeWhere(
      (e) => !options.contains(e),
    );
    return false;
  }

  String assertCommand(Map<String, dynamic> body) {
    final action = body.elementAt('action');
    if (action == null) {
      throw const InvalidOperation("Argument 'action' is missing");
    } else if (action is! String) {
      throw InvalidOperation("Argument 'action' is not a String: $action");
    }
    return (action as String).toLowerCase();
  }

  /// Add @Operation.get() to activate
  Future<Response> getMeta({
    @Bind.query('expand') String expand,
  }) async {
    try {
      return doGetMeta(expand);
    } on InvalidOperation catch (e) {
      return Response.badRequest(body: e.message);
    } catch (e, stackTrace) {
      return toServerError(e, stackTrace);
    }
  }

  Future<Response> doGetMeta(String expand) => throw UnimplementedError(
        'doGetMeta not implemented',
      );

  /// Add @Operation.get('type') to activate
  Future<Response> getMetaByType(
    @Bind.path('type') String type, {
    @Bind.query('expand') String expand,
  }) async {
    try {
      return doGetMetaByType(type, expand);
    } on InvalidOperation catch (e) {
      return Response.badRequest(body: e.message);
    } catch (e, stackTrace) {
      return toServerError(e, stackTrace);
    }
  }

  Future<Response> doGetMetaByType(String type, String expand) => throw UnimplementedError(
        'doGetMetaByType not implemented',
      );

  /// Add @Operation.get('type', 'uuid') to activate
  Future<Response> getMetaByTypeAndUuid(
    @Bind.path('type') String type,
    @Bind.path('uuid') String uuid, {
    @Bind.query('expand') String expand,
  }) async {
    try {
      return doGetMetaByTypeAndUuid(
        type,
        uuid,
        expand,
      );
    } on InvalidOperation catch (e) {
      return Response.badRequest(body: e.message);
    } catch (e, stackTrace) {
      return toServerError(e, stackTrace);
    }
  }

  Future<Response> doGetMetaByTypeAndUuid(
    String type,
    String uuid,
    String expand,
  ) =>
      throw UnimplementedError(
        'doGetMetaByTypeAndUuid not implemented',
      );

  /// Add @Operation.get('name') to activate
  Future<Response> getMetaByName(
    @Bind.path('name') String name, {
    @Bind.query('expand') String expand,
  }) async {
    try {
      return doGetMetaByName(name, expand);
    } on InvalidOperation catch (e) {
      return Response.badRequest(body: e.message);
    } catch (e, stackTrace) {
      return toServerError(e, stackTrace);
    }
  }

  Future<Response> doGetMetaByName(String name, String expand) => throw UnimplementedError(
        'doGetMetaByName not implemented',
      );

  /// Add @Operation.get('name', 'uuid') to activate
  Future<Response> getMetaByNameAndUuid(
    @Bind.path('name') String name,
    @Bind.path('uuid') String uuid, {
    @Bind.query('expand') String expand,
  }) async {
    try {
      return doGetMetaByNameAndUuid(
        name,
        uuid,
        expand,
      );
    } on InvalidOperation catch (e) {
      return Response.badRequest(body: e.message);
    } catch (e, stackTrace) {
      return toServerError(e, stackTrace);
    }
  }

  Future<Response> doGetMetaByNameAndUuid(
    String name,
    String uuid,
    String expand,
  ) =>
      throw UnimplementedError(
        'doGetMetaByNameAndUuid not implemented',
      );

  /// Add @Operation.get('name', 'type') to activate
  Future<Response> getMetaByNameAndType(
    @Bind.path('name') String name,
    @Bind.path('type') String type, {
    @Bind.query('expand') String expand,
  }) async {
    try {
      return doGetMetaByNameAndType(
        name,
        type,
        expand,
      );
    } on InvalidOperation catch (e) {
      return Response.badRequest(body: e.message);
    } catch (e, stackTrace) {
      return toServerError(e, stackTrace);
    }
  }

  Future<Response> doGetMetaByNameAndType(
    String name,
    String type,
    String expand,
  ) =>
      throw UnimplementedError(
        'doGetMetaByNameAndType not implemented',
      );

  /// Add @Operation.get('name', 'type', 'uuid') to activate
  Future<Response> getMetaByNameTypeAndUuid(
    @Bind.path('name') String name,
    @Bind.path('type') String type,
    @Bind.path('uuid') String uuid, {
    @Bind.query('expand') String expand,
  }) async {
    try {
      return doGetMetaByNameTypeAndUuid(
        name,
        type,
        uuid,
        expand,
      );
    } on InvalidOperation catch (e) {
      return Response.badRequest(body: e.message);
    } catch (e, stackTrace) {
      return toServerError(e, stackTrace);
    }
  }

  Future<Response> doGetMetaByNameTypeAndUuid(
    String name,
    String type,
    String uuid,
    String expand,
  ) =>
      throw UnimplementedError(
        'doGetMetaByNameTypeAndUuid not implemented',
      );

  /// Add @Operation.post() to activate
  Future<Response> execute(
    @Bind.body() Map<String, dynamic> body, {
    @Bind.query('expand') String expand,
  }) async {
    try {
      final command = assertCommand(body);
      return doExecute(
        command,
        body,
        expand,
      );
    } on RepositoryMaxPressureExceeded catch (e) {
      return tooManyRequests(body: e.message);
    } on TimeoutException catch (e) {
      return gatewayTimeout(
        body: e.message,
      );
    } on StreamRequestTimeout catch (e) {
      return gatewayTimeout(
        body: 'Repository was unable to process request ${e.request.tag}',
      );
    } on AggregateCordoned catch (e) {
      return locked(body: e.message);
    } on SocketException catch (e) {
      return serviceUnavailable(body: 'Eventstore unavailable: $e');
    } on SchemaException catch (e) {
      return Response.badRequest(body: e.message);
    } on InvalidOperation catch (e) {
      return Response.badRequest(body: e.message);
    } catch (e, stackTrace) {
      return toServerError(e, stackTrace);
    }
  }

  Future<Response> doExecute(String command, Map<String, dynamic> body, String expand) => throw UnimplementedError(
        'doExecute not implemented',
      );

  /// Add @Operation.post('name') to activate
  Future<Response> executeByName(
    @Bind.path('name') String name,
    @Bind.body() Map<String, dynamic> body, {
    @Bind.query('expand') String expand,
  }) async {
    try {
      final command = assertCommand(body);
      return doExecuteByName(
        name,
        command,
        body,
        expand,
      );
    } on RepositoryMaxPressureExceeded catch (e) {
      return tooManyRequests(body: e.message);
    } on TimeoutException catch (e) {
      return gatewayTimeout(
        body: e.message,
      );
    } on StreamRequestTimeout catch (e) {
      return gatewayTimeout(
        body: 'Repository was unable to process request ${e.request.tag}',
      );
    } on AggregateCordoned catch (e) {
      return locked(body: e.message);
    } on SocketException catch (e) {
      return serviceUnavailable(body: 'Eventstore unavailable: $e');
    } on SchemaException catch (e) {
      return Response.badRequest(body: e.message);
    } on InvalidOperation catch (e) {
      return Response.badRequest(body: e.message);
    } catch (e, stackTrace) {
      return toServerError(e, stackTrace);
    }
  }

  Future<Response> doExecuteByName(
    String name,
    String command,
    Map<String, dynamic> body,
    String expand,
  ) =>
      throw UnimplementedError(
        'doExecuteByName not implemented',
      );

  /// Add @Operation.post('name', 'uuid') to activate
  Future<Response> executeByNameAndUuid(
    @Bind.path('name') String name,
    @Bind.path('uuid') String uuid,
    @Bind.body() Map<String, dynamic> body, {
    @Bind.query('expand') String expand,
  }) async {
    try {
      final command = assertCommand(body);
      return doExecuteByNameAndUuid(
        name,
        uuid,
        command,
        body,
        expand,
      );
    } on RepositoryMaxPressureExceeded catch (e) {
      return tooManyRequests(body: e.message);
    } on TimeoutException catch (e) {
      return gatewayTimeout(
        body: e.message,
      );
    } on StreamRequestTimeout catch (e) {
      return gatewayTimeout(
        body: 'Repository was unable to process request ${e.request.tag}',
      );
    } on AggregateCordoned catch (e) {
      return locked(body: e.message);
    } on SocketException catch (e) {
      return serviceUnavailable(body: 'Eventstore unavailable: $e');
    } on SchemaException catch (e) {
      return Response.badRequest(body: e.message);
    } on InvalidOperation catch (e) {
      return Response.badRequest(body: e.message);
    } catch (e, stackTrace) {
      return toServerError(e, stackTrace);
    }
  }

  Future<Response> doExecuteByNameAndUuid(
    String name,
    String uuid,
    String command,
    Map<String, dynamic> body,
    String expand,
  ) =>
      throw UnimplementedError(
        'doExecuteByNameAndUuid not implemented',
      );

  /// Add @Operation.post('name', 'uuid') to activate
  Future<Response> executeByNameAndType(
    @Bind.path('name') String name,
    @Bind.path('Type') String type,
    @Bind.body() Map<String, dynamic> body, {
    @Bind.query('expand') String expand,
  }) async {
    try {
      final command = assertCommand(body);
      return doExecuteByNameAndType(
        name,
        type,
        command,
        body,
        expand,
      );
    } on RepositoryMaxPressureExceeded catch (e) {
      return tooManyRequests(body: e.message);
    } on TimeoutException catch (e) {
      return gatewayTimeout(
        body: e.message,
      );
    } on StreamRequestTimeout catch (e) {
      return gatewayTimeout(
        body: 'Repository was unable to process request ${e.request.tag}',
      );
    } on AggregateCordoned catch (e) {
      return locked(body: e.message);
    } on SocketException catch (e) {
      return serviceUnavailable(body: 'Eventstore unavailable: $e');
    } on SchemaException catch (e) {
      return Response.badRequest(body: e.message);
    } on InvalidOperation catch (e) {
      return Response.badRequest(body: e.message);
    } catch (e, stackTrace) {
      return toServerError(e, stackTrace);
    }
  }

  Future<Response> doExecuteByNameAndType(
    String name,
    String type,
    String command,
    Map<String, dynamic> body,
    String expand,
  ) =>
      throw UnimplementedError(
        'doExecuteByNameAndType not implemented',
      );

  /// Add @Operation.post('type') to activate
  Future<Response> executeByType(
    @Bind.path('type') String type,
    @Bind.body() Map<String, dynamic> body, {
    @Bind.query('expand') String expand,
  }) async {
    try {
      final command = assertCommand(body);
      return doExecuteByType(
        type,
        command,
        body,
        expand,
      );
    } on RepositoryMaxPressureExceeded catch (e) {
      return tooManyRequests(body: e.message);
    } on TimeoutException catch (e) {
      return gatewayTimeout(
        body: e.message,
      );
    } on StreamRequestTimeout catch (e) {
      return gatewayTimeout(
        body: 'Repository was unable to process request ${e.request.tag}',
      );
    } on AggregateCordoned catch (e) {
      return locked(body: e.message);
    } on SocketException catch (e) {
      return serviceUnavailable(body: 'Eventstore unavailable: $e');
    } on SchemaException catch (e) {
      return Response.badRequest(body: e.message);
    } on InvalidOperation catch (e) {
      return Response.badRequest(body: e.message);
    } catch (e, stackTrace) {
      return toServerError(e, stackTrace);
    }
  }

  Future<Response> doExecuteByType(
    String type,
    String command,
    Map<String, dynamic> body,
    String expand,
  ) =>
      throw UnimplementedError(
        'doExecuteByType not implemented',
      );

  /// Add @Operation.post('type', 'uuid') to activate
  Future<Response> executeByTypeAndUuid(
    @Bind.path('type') String type,
    @Bind.path('uuid') String uuid,
    @Bind.body() Map<String, dynamic> body, {
    @Bind.query('expand') String expand,
  }) async {
    try {
      final command = assertCommand(body);
      return doExecuteByTypeAndUuid(
        type,
        uuid,
        command,
        body,
        expand,
      );
    } on RepositoryMaxPressureExceeded catch (e) {
      return tooManyRequests(body: e.message);
    } on TimeoutException catch (e) {
      return gatewayTimeout(
        body: e.message,
      );
    } on StreamRequestTimeout catch (e) {
      return gatewayTimeout(
        body: 'Repository was unable to process request ${e.request.tag}',
      );
    } on AggregateCordoned catch (e) {
      return locked(body: e.message);
    } on SocketException catch (e) {
      return serviceUnavailable(body: 'Eventstore unavailable: $e');
    } on SchemaException catch (e) {
      return Response.badRequest(body: e.message);
    } on InvalidOperation catch (e) {
      return Response.badRequest(body: e.message);
    } catch (e, stackTrace) {
      return toServerError(e, stackTrace);
    }
  }

  Future<Response> doExecuteByTypeAndUuid(
    String type,
    String uuid,
    String command,
    Map<String, dynamic> body,
    String expand,
  ) =>
      throw UnimplementedError(
        'doExecuteByTypeAndUuid not implemented',
      );

  /// Add @Operation.post('name', 'type', 'uuid') to activate
  Future<Response> executeByNameTypeAndUuid(
    @Bind.path('name') String name,
    @Bind.path('type') String type,
    @Bind.path('uuid') String uuid,
    @Bind.body() Map<String, dynamic> body, {
    @Bind.query('expand') String expand,
  }) async {
    try {
      final command = assertCommand(body);
      return doExecuteByNameTypeAndUuid(
        name,
        type,
        uuid,
        command,
        body,
        expand,
      );
    } on RepositoryMaxPressureExceeded catch (e) {
      return tooManyRequests(body: e.message);
    } on TimeoutException catch (e) {
      return gatewayTimeout(
        body: e.message,
      );
    } on StreamRequestTimeout catch (e) {
      return gatewayTimeout(
        body: 'Repository was unable to process request ${e.request.tag}',
      );
    } on AggregateCordoned catch (e) {
      return locked(body: e.message);
    } on SocketException catch (e) {
      return serviceUnavailable(body: 'Eventstore unavailable: $e');
    } on SchemaException catch (e) {
      return Response.badRequest(body: e.message);
    } on InvalidOperation catch (e) {
      return Response.badRequest(body: e.message);
    } catch (e, stackTrace) {
      return toServerError(e, stackTrace);
    }
  }

  Future<Response> doExecuteByNameTypeAndUuid(
    String name,
    String type,
    String uuid,
    String command,
    Map<String, dynamic> body,
    String expand,
  ) =>
      throw UnimplementedError(
        'doExecuteByNameTypeAndUuid not implemented',
      );

  Map<String, dynamic> toJsonItemsMeta(List<Map<String, dynamic>> items) {
    return {
      'items': items,
    };
  }

  Map<String, dynamic> toProto3JsonInstanceMeta(
    String name,
    GeneratedMessage meta, [
    Map<String, dynamic> Function(Map<String, dynamic>) map,
  ]) {
    final json = Map<String, dynamic>.from(
      toProto3Json(meta),
    );
    json['name'] = name;

    // Replace JsonValue?
    if (json.hasPath('data/compression')) {
      json['data'] = json.mapAt('data/data');
    }

    return map == null ? json : map(json);
  }

  Map<String, dynamic> toJsonCommandMeta(
    Map<String, dynamic> meta,
    int statusCode,
    String reasonPhrase, [
    Map<String, dynamic> Function() onError,
  ]) {
    return {
      'meta': meta,
      if (statusCode >= HttpStatus.badRequest)
        'error': onError != null
            ? onError()
            : {
                'statusCode': statusCode,
                'reasonPhrase': reasonPhrase,
              }
    };
  }

  Response toResponse({
    @required String method,
    @required int statusCode,
    @required Map<String, dynamic> args,
    String name,
    String type,
    String uuid,
    List<String> names,
    List<String> uuids,
    dynamic body,
  }) {
    logger.fine(
      Context.toMethod(method, [
        if (name != null) 'name: $name',
        if (type != null) 'type: $type',
        if (names != null) 'names: $names',
        if (uuid != null) 'uuid: $uuid',
        if (uuids != null) 'uuids: $uuids',
        ...args.entries.map(
          (entry) => '${entry.key}: ${entry.value}',
        ),
        'response: $body',
      ]),
    );
    return Response(
      statusCode,
      {},
      body,
    );
  }

  /// Report error to Sentry and
  /// return 500 with message as body
  Response toServerError(Object error, StackTrace stackTrace) => serverError(
        request,
        error,
        stackTrace,
        logger: logger,
      );

  //////////////////////////////////
  // Documentation
  //////////////////////////////////

  APISchemaObject documentInstanceMeta(APIDocumentContext context);
  Map<String, APISchemaObject> documentCommandParams(APIDocumentContext context) => {};
  Map<String, APISchemaObject> documentInstanceCommandParams(APIDocumentContext context) => {};

  @override
  List<String> documentOperationTags(APIDocumentContext context, Operation operation) =>
      tag == null ? super.documentOperationTags(context, operation) : [tag];

  @override
  String documentOperationSummary(APIDocumentContext context, Operation operation) {
    String summary;
    switch (operation.method) {
      case 'GET':
        summary = 'Get $target metadata';
        break;
      case 'POST':
        summary = 'Execute command on $target';
        break;
    }
    return summary;
  }

  @override
  String documentOperationDescription(APIDocumentContext context, Operation operation) {
    return '${documentOperationSummary(context, operation)}.';
  }

  @override
  List<APIParameter> documentOperationParameters(APIDocumentContext context, Operation operation) {
    final parameters = super.documentOperationParameters(context, operation);
    switch (operation.method) {
      case 'GET':
      case 'POST':
        parameters.add(
          APIParameter.query('expand')
            ..description = 'Expand response with metadata. '
                'Legal values are: '
                "'${(operation.pathVariables.isEmpty ? options : instanceOptions).join("', '")}'",
        );
        break;
    }
    return parameters;
  }

  @override
  APIRequestBody documentOperationRequestBody(APIDocumentContext context, Operation operation) {
    switch (operation.method) {
      case 'POST':
        return operation.pathVariables.isEmpty
            ? APIRequestBody.schema(
                context.schema['${target}Command'],
                description: '$target Command Request',
                required: true,
              )
            : APIRequestBody.schema(
                context.schema['${target}InstanceCommand'],
                description: '$target Instance Command Request',
                required: true,
              );
        break;
    }
    return super.documentOperationRequestBody(context, operation);
  }

  @override
  Map<String, APIResponse> documentOperationResponses(APIDocumentContext context, Operation operation) {
    final responses = {
      '200': context.responses.getObject('200'),
      '400': context.responses.getObject('400'),
      '401': context.responses.getObject('401'),
      '403': context.responses.getObject('403'),
      '416': context.responses.getObject('416'),
      '429': context.responses.getObject('429'),
      '500': context.responses.getObject('500'),
      '503': context.responses.getObject('503'),
      '504': context.responses.getObject('504'),
    };
    switch (operation.method) {
      case 'GET':
        responses.addAll({
          '200': operation.pathVariables.isEmpty
              ? APIResponse.schema(
                  'Successful response.',
                  context.schema['${target}Meta'],
                )
              : APIResponse.schema(
                  'Successful response.',
                  context.schema['${target}InstanceMeta'],
                ),
        });
        break;
      case 'POST':
        responses.addAll({
          '200': operation.pathVariables.isEmpty
              ? APIResponse.schema(
                  'Successful $target command response.',
                  context.schema['${target}CommandResult'],
                )
              : APIResponse.schema(
                  'Successful $target instance command response.',
                  context.schema['${target}InstanceCommandResult'],
                ),
        });
        break;
    }
    return responses;
  }

  @override
  void documentComponents(APIDocumentContext context) {
    super.documentComponents(context);
    documentSchemaObjects(context).forEach((target, object) {
      if (object.title?.isNotEmpty == false) {
        object.title = '$target';
      }
      if (object.description?.isNotEmpty == false) {
        object.description = '$target schema';
      }
      context.schema.register(target, object);
    });
  }

  Map<String, APISchemaObject> documentSchemaObjects(APIDocumentContext context) => {
        '${target}Meta': documentMeta(context),
        if (actions.isNotEmpty) '${target}Command': documentCommand(documentCommandParams(context)),
        if (actions.isNotEmpty) '${target}CommandResult': documentCommandResult(context),
        '${target}InstanceMeta': documentInstanceMeta(context),
        if (instanceActions.isNotEmpty)
          '${target}InstanceCommand': documentInstanceCommand(documentInstanceCommandParams(context)),
        if (instanceActions.isNotEmpty) '${target}InstanceCommandResult': documentInstanceCommandResult(context),
      };

  APISchemaObject documentMeta(APIDocumentContext context) => APISchemaObject.object(
        {'items': APISchemaObject.array(ofSchema: documentInstanceMeta(context))},
      );

  APISchemaObject documentCommand(Map<String, APISchemaObject> params) {
    return APISchemaObject.object({
      'action': APISchemaObject.string()
        ..description = '$target actions'
        ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
        ..enumerated = actions,
      'params': APISchemaObject.object(params)
        ..description = '$target command properties'
        ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
    });
  }

  APISchemaObject documentInstanceCommand(Map<String, APISchemaObject> params) {
    return APISchemaObject.object({
      'action': APISchemaObject.string()
        ..description = '$target instance actions'
        ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
        ..enumerated = instanceActions,
      'params': APISchemaObject.object(params)
        ..description = '$target instance command properties'
        ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
    });
  }

  APISchemaObject documentCommandResult(APIDocumentContext context) {
    return APISchemaObject.object({
      'meta': documentMeta(context)
        ..description = '$target metadata'
        ..isReadOnly = true,
      'error': documentError(),
    });
  }

  APISchemaObject documentInstanceCommandResult(APIDocumentContext context) {
    return APISchemaObject.object({
      'meta': documentInstanceMeta(context)
        ..description = '$target instance metadata'
        ..isReadOnly = true,
      'error': documentError(),
    });
  }

  APISchemaObject documentError() {
    return APISchemaObject.object({
      'failed': APISchemaObject.array(ofSchema: documentUUID())
        ..description = 'List of aggregate uuids witch command failed on'
        ..isReadOnly = true
    })
      ..description = 'Error information'
      ..isReadOnly = true;
  }

  APISchemaObject documentMetric(String target) {
    return APISchemaObject.object({
      'count': APISchemaObject.integer()
        ..description = 'Number of measurements'
        ..isReadOnly = true,
      'duration': APISchemaObject.integer()
        ..description = 'Last $target time in ms'
        ..isReadOnly = true,
      'durationAverage': APISchemaObject.integer()
        ..description = '$target time average'
        ..isReadOnly = true,
    })
      ..description = '$target metrics'
      ..isReadOnly = true;
  }
}
