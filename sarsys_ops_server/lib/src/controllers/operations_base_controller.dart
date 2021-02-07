import 'package:sarsys_http_core/sarsys_http_core.dart';
import 'package:sarsys_ops_server/src/config.dart';

/// A [ResourceController] base class for system operations requests
abstract class OperationsBaseController extends ResourceController {
  OperationsBaseController(
    this.type,
    this.config, {
    @required this.tag,
    @required this.actions,
    @required this.options,
    @required this.context,
  });

  final String tag;
  final String type;
  final List<String> actions;
  final List<String> options;
  final SarSysOpsConfig config;
  final Map<String, dynamic> context;

  String get(String key) => context[key] ?? Platform.environment[key];

  bool contains(String key) => context.containsKey(key) || Platform.environment.containsKey(key);

  bool shouldExpand(String expand, String field) {
    final elements = expand?.split(',') ?? <String>[];
    if (elements.any((element) => element.toLowerCase() == field)) {
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

  /// Add @Operation.get('uuid') to activate
  Future<Response> getMetaByUuid(
    @Bind.path('uuid') String uuid, {
    @Bind.query('expand') String expand,
  }) async {
    try {
      return doGetMetaByUuid(uuid, expand);
    } on InvalidOperation catch (e) {
      return Response.badRequest(body: e.message);
    } catch (e, stackTrace) {
      return toServerError(e, stackTrace);
    }
  }

  Future<Response> doGetMetaByUuid(String uuid, String expand) => throw UnimplementedError(
        'doGetMetaByName not implemented',
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

  /// Add @Operation.post('uuid') to activate
  Future<Response> executeByUuid(
    @Bind.path('uuid') String uuid,
    @Bind.body() Map<String, dynamic> body, {
    @Bind.query('expand') String expand,
  }) async {
    try {
      final command = assertCommand(body);
      return doExecuteByUuid(
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

  Future<Response> doExecuteByUuid(
    String uuid,
    String command,
    Map<String, dynamic> body,
    String expand,
  ) =>
      throw UnimplementedError(
        'doExecute not implemented',
      );

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

  @override
  List<String> documentOperationTags(APIDocumentContext context, Operation operation) =>
      tag == null ? super.documentOperationTags(context, operation) : [tag];

  @override
  String documentOperationSummary(APIDocumentContext context, Operation operation) {
    String summary;
    switch (operation.method) {
      case 'GET':
        summary = 'Get $type metadata';
        break;
      case 'POST':
        summary = 'Execute command on $type';
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
        parameters.add(
          APIParameter.query('expand')
            ..description = 'Expand response with metadata. '
                "Legal values are: '${options.join("', '")}'",
        );
        break;
    }
    return parameters;
  }

  @override
  APIRequestBody documentOperationRequestBody(APIDocumentContext context, Operation operation) {
    switch (operation.method) {
      case 'POST':
        return APIRequestBody.schema(
          context.schema['${type}Command'],
          description: '$type Command Request',
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
          '200': APIResponse.schema(
            'Successful response.',
            context.schema['${type}Meta'],
          ),
        });
        break;
      case 'POST':
        responses.addAll({
          '200': APIResponse.schema(
            'Successful response.',
            context.schema['${type}CommandResult'],
          ),
        });
        break;
    }
    return responses;
  }

  @override
  void documentComponents(APIDocumentContext context) {
    super.documentComponents(context);
    documentSchemaObjects(context).forEach((type, object) {
      if (object.title?.isNotEmpty == false) {
        object.title = '$type';
      }
      if (object.description?.isNotEmpty == false) {
        object.description = '$type schema';
      }
      context.schema.register(type, object);
    });
  }

  Map<String, APISchemaObject> documentSchemaObjects(APIDocumentContext context) => {
        '${type}Meta': documentMeta(context),
        '${type}Command': documentCommand(
          documentCommandParams(context),
        ),
        '${type}CommandResult': documentCommandResult(context),
      };

  APISchemaObject documentMeta(APIDocumentContext context);
  Map<String, APISchemaObject> documentCommandParams(APIDocumentContext context);

  APISchemaObject documentCommand(Map<String, APISchemaObject> params) {
    return APISchemaObject.object({
      'action': APISchemaObject.string()
        ..description = 'Snapshot actions'
        ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
        ..enumerated = actions,
      'params': APISchemaObject.object(params)
        ..description = 'Command properties'
        ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
    });
  }

  APISchemaObject documentCommandResult(APIDocumentContext context) {
    return APISchemaObject.object({
      'meta': documentMeta(context)
        ..description = '$type metadata'
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

  APISchemaObject documentMetric(String type) {
    return APISchemaObject.object({
      'count': APISchemaObject.integer()
        ..description = 'Number of measurements'
        ..isReadOnly = true,
      'duration': APISchemaObject.integer()
        ..description = 'Last $type time in ms'
        ..isReadOnly = true,
      'durationAverage': APISchemaObject.integer()
        ..description = '$type time average'
        ..isReadOnly = true,
    })
      ..description = '$type metrics'
      ..isReadOnly = true;
  }
}
