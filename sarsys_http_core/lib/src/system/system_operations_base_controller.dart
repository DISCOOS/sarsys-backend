import 'package:sarsys_http_core/sarsys_http_core.dart';

/// A [ResourceController] base class for operations requests
abstract class SystemOperationsBaseController<T> extends ResourceController {
  SystemOperationsBaseController(
    this.manager, {
    @required this.tag,
    @required this.type,
    @required this.config,
    @required this.actions,
    @required this.options,
    @required this.context,
    this.requireReady = true,
  });

  final String tag;
  final String type;
  final bool requireReady;
  final SarSysConfig config;
  final List<String> actions;
  final List<String> options;
  final RepositoryManager manager;
  final Map<String, dynamic> context;

  String get(String name) => context[name] ?? Platform.environment[name];

  bool contains(String name) => context.containsKey(name) || Platform.environment.containsKey(name);

  @override
  FutureOr<RequestOrResponse> willProcessRequest(Request req) => !requireReady || manager.isReady
      ? req
      : serviceUnavailable(
          body: 'Repositories are unavailable: build pending',
        );

  bool shouldAccept() {
    if (contains('POD-NAME')) {
      final name = get('POD-NAME');
      final match = request.raw.headers.value('x-if-match-pod');
      return match == null || name == null || match.toLowerCase() == name.toLowerCase();
    }
    return true;
  }

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
      '500': context.responses.getObject('503'),
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
            context.schema['${type}Meta'],
          ),
        });
        break;
    }
    return responses;
  }

  @override
  void documentComponents(APIDocumentContext context) {
    super.documentComponents(context);
    documentSchemaObjects(context).forEach((name, object) {
      if (object.title?.isNotEmpty == false) {
        object.title = '$name';
      }
      if (object.description?.isNotEmpty == false) {
        object.description = '$name schema';
      }
      context.schema.register(name, object);
    });
  }

  Map<String, APISchemaObject> documentSchemaObjects(APIDocumentContext context) => {
        '${type}Meta': documentMeta(context),
        '${type}Command': documentCommand(
          documentCommandParams(context),
        ),
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
}
