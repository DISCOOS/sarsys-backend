import 'package:sarsys_http_core/sarsys_http_core.dart';

/// A [ResourceController] for [AggregateRoot] operations requests
class AggregateOperationsController extends ResourceController {
  AggregateOperationsController(
    this.manager, {
    @required this.tag,
  });

  final String tag;

  final RepositoryManager manager;

  @override
  FutureOr<RequestOrResponse> willProcessRequest(Request req) => manager.isReady
      ? req
      : serviceUnavailable(
          body: 'Repositories are unavailable: build pending',
        );

  //////////////////////////////////
  // Aggregate Operations
  //////////////////////////////////

  @Scope(['roles:admin'])
  @Operation.get('type', 'uuid')
  Future<Response> getMeta(
    @Bind.path('type') String type,
    @Bind.path('uuid') String uuid, {
    @Bind.query('expand') String expand,
  }) async {
    try {
      if (!_shouldAccept()) {
        return requestedRangeNotSatisfiable();
      }
      final repository = manager.getFromTypeName(type);
      if (repository == null) {
        return Response.notFound(
          body: 'Repository for type $type not found',
        );
      }
      if (!repository.contains(uuid)) {
        Response.notFound(
          body: 'Aggregate ${repository.aggregateType} $uuid not found',
        );
      }
      final aggregate = repository.get(uuid);
      final trx = repository.inTransaction(uuid) ? repository.get(uuid) : null;
      final data = _shouldExpand(expand, 'data');
      final items = _shouldExpand(expand, 'items');
      return Response.ok(
        aggregate.toMeta(
          data: data,
          items: items,
        )..addAll({'transaction': trx?.toMeta(data: data, items: items) ?? {}}),
      );
    } on InvalidOperation catch (e) {
      return Response.badRequest(body: e.message);
    } catch (e, stackTrace) {
      return toServerError(e, stackTrace);
    }
  }

  @Scope(['roles:admin'])
  @Operation.post('type', 'uuid')
  Future<Response> command(
    @Bind.path('uuid') String uuid,
    @Bind.path('type') String type,
    @Bind.body() Map<String, dynamic> body, {
    @Bind.query('expand') String expand,
  }) async {
    try {
      if (!_shouldAccept()) {
        return requestedRangeNotSatisfiable();
      }
      final repository = manager.getFromTypeName(type);
      if (repository == null) {
        return Response.notFound(
          body: 'Repository for type $type not found',
        );
      }
      if (!repository.contains(uuid)) {
        Response.notFound(
          body: 'Aggregate ${repository.aggregateType} $uuid not found',
        );
      }
      final command = _assertCommand(body);
      final expandData = _shouldExpand(expand, 'data');
      final expandItems = _shouldExpand(expand, 'items');

      switch (command) {
        case 'replay':
          await repository.replay(
            uuids: [uuid],
          );
          return Response.ok(
            repository.get(uuid).toMeta(
                  data: expandData,
                  items: expandItems,
                ),
          );
        case 'catchup':
          await repository.catchup(
            uuids: [uuid],
          );
          return Response.ok(
            repository.get(uuid).toMeta(
                  data: expandData,
                  items: expandItems,
                ),
          );
        case 'replace':
          final data = body.mapAt<String, dynamic>(
            'params/data',
          );
          final patches = body.listAt<Map<String, dynamic>>(
            'params/patches',
          );
          final old = repository.replace(
            uuid,
            data: data,
            patches: patches,
          );
          return Response.ok(
            old.toMeta(
              data: expandData,
              items: expandItems,
            ),
          );
      }
      return Response.badRequest(
        body: "Command '$command' not found",
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

  bool _shouldAccept() {
    if (Platform.environment.containsKey('POD-NAME')) {
      final name = Platform.environment['POD-NAME'];
      final match = request.raw.headers.value('x-if-match-pod');
      return match == null || name == null || match.toLowerCase() == name.toLowerCase();
    }
    return true;
  }

  bool _shouldExpand(String expand, String field) {
    final elements = expand?.split(',') ?? <String>[];
    if (elements.any((element) => element.toLowerCase() == field)) {
      return true;
    }
    elements.removeWhere(
      (e) => !options.contains(e),
    );
    return false;
  }

  List<String> get options => const [
        'data',
        'items',
      ];

  String _assertCommand(Map<String, dynamic> body) {
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
        summary = 'Get aggregate metadata';
        break;
      case 'POST':
        summary = 'Execute command on aggregate';
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
          context.schema['AggregateCommand'],
          description: 'Aggregate Command Request',
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
            context.schema['RepositoryMeta'],
          ),
        });
        break;
      case 'POST':
        responses.addAll({
          '200': APIResponse.schema(
            'Successful response.',
            context.schema['RepositoryMeta'],
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
        'AggregateMeta': _documentMeta(context),
        'AggregateCommand': _documentCommand(),
      };

  APISchemaObject _documentMeta(APIDocumentContext context) {
    return APISchemaObject.object({
      'uuid': documentUUID()
        ..description = 'Globally unique aggregate id'
        ..isReadOnly = true,
      'type': APISchemaObject.string()
        ..description = 'Aggregate Type'
        ..isReadOnly = true,
      'number': APISchemaObject.integer()
        ..description = 'Current event number'
        ..isReadOnly = true,
      'created': documentEvent(context)
        ..description = 'Created by given event'
        ..isReadOnly = true,
      'changed': documentEvent(context)
        ..description = 'Last changed by given event'
        ..isReadOnly = true,
      'modifications': APISchemaObject.integer()
        ..description = 'Total number of modifications'
        ..isReadOnly = true,
      'applied': APISchemaObject.object({
        'count': APISchemaObject.integer()
          ..description = 'Total number of applied events'
          ..isReadOnly = true,
        'items': APISchemaObject.array(
          ofSchema: documentEvent(context),
        )..description = 'Array of skipped events',
      }),
      'skipped': APISchemaObject.object({
        'count': APISchemaObject.integer()
          ..description = 'Total number of skipped events'
          ..isReadOnly = true,
        'items': APISchemaObject.array(
          ofSchema: documentEvent(context),
        )..description = 'Array of skipped events',
      }),
      'pending': APISchemaObject.object({
        'count': APISchemaObject.integer()
          ..description = 'Total number of local events pending push'
          ..isReadOnly = true,
        'items': APISchemaObject.array(
          ofSchema: documentEvent(context),
        )..description = 'Array of local events pending push',
      }),
      'data': APISchemaObject.freeForm()
        ..description = 'Map of JSON-Patch compliant values'
        ..isReadOnly = true,
    });
  }

  APISchemaObject _documentCommand() {
    return APISchemaObject.object({
      'action': APISchemaObject.string()
        ..description = 'Aggregate actions'
        ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
        ..enumerated = [
          'replay',
          'replace',
          'catchup',
        ],
      'params': APISchemaObject.object({
        'data': APISchemaObject.freeForm()..description = 'Map of JSON-compliant values',
        'patches': APISchemaObject.array(
          ofSchema: APISchemaObject.freeForm()..description = 'Map of JSON-Patch compliant values',
        )
      })
        ..description = 'Command properties'
        ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
    });
  }
}
