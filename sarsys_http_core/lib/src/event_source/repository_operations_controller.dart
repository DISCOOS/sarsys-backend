import 'package:sarsys_http_core/sarsys_http_core.dart';

/// A [ResourceController] for [Repository] operations requests
class RepositoryOperationsController extends ResourceController {
  RepositoryOperationsController(
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
  @Operation.get('type')
  Future<Response> getMeta(
    @Bind.path('type') String type, {
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
      return Response.ok(
        repository.toMeta(
          data: _shouldExpand(expand, 'data'),
          queue: _shouldExpand(expand, 'queue'),
          items: _shouldExpand(expand, 'items'),
          snapshot: _shouldExpand(expand, 'snapshot'),
          connection: _shouldExpand(expand, 'connection'),
          subscriptions: _shouldExpand(expand, 'subscriptions'),
        ),
      );
    } on InvalidOperation catch (e) {
      return Response.badRequest(body: e.message);
    } catch (e, stackTrace) {
      return toServerError(e, stackTrace);
    }
  }

  @Scope(['roles:admin'])
  @Operation.post('type')
  Future<Response> command(
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
      final command = _assertCommand(body);
      switch (command) {
        case 'rebuild':
          await repository.build();
          break;
        case 'replay':
          final uuids = body.listAt<String>(
            'params/uuids',
            defaultList: <String>[],
          );
          await repository.replay(
            uuids: uuids,
          );
          break;
        case 'catchup':
          final uuids = body.listAt<String>(
            'params/uuids',
            defaultList: <String>[],
          );
          await repository.catchup(
            uuids: uuids,
          );
          break;
        default:
          return Response.badRequest(
            body: 'Command $command not found',
          );
      }
      return Response.ok(
        repository.toMeta(
          data: _shouldExpand(expand, 'data'),
          queue: _shouldExpand(expand, 'queue'),
          items: _shouldExpand(expand, 'items'),
          snapshot: _shouldExpand(expand, 'snapshot'),
          connection: _shouldExpand(expand, 'connection'),
          subscriptions: _shouldExpand(expand, 'subscriptions'),
        ),
      );
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
        'queue',
        'items',
        'snapshot',
        'connection',
        'subscriptions',
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
        summary = 'Get repository metadata';
        break;
      case 'POST':
        summary = 'Execute command on repository';
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
          context.schema['RepositoryCommand'],
          description: 'Repository Command Request',
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
        'RepositoryMeta': _documentMeta(context),
        'RepositoryCommand': _documentCommand(),
      };

  APISchemaObject _documentMeta(APIDocumentContext context) {
    return APISchemaObject.object({
      'type': APISchemaObject.string()
        ..description = 'Aggregate Type'
        ..isReadOnly = true,
      'count': APISchemaObject.integer()
        ..description = 'Number of aggregates'
        ..isReadOnly = true,
      'queue': _documentQueue(),
      'snapshot': _documentSnapshot(context),
      'connection': _documentConnection(context),
      'subscriptions': _documentSubscriptions(context),
    });
  }

  APISchemaObject _documentQueue() {
    return APISchemaObject.object({
      'pressure': APISchemaObject.object({
        'push': APISchemaObject.integer()
          ..description = 'Number of pending pushes'
          ..isReadOnly = true,
        'command': APISchemaObject.integer()
          ..description = 'Number of pending commands'
          ..isReadOnly = true,
        'total': APISchemaObject.integer()
          ..description = 'Total pressure'
          ..isReadOnly = true,
        'maximum': APISchemaObject.integer()
          ..description = 'Maximum allowed pressure'
          ..isReadOnly = true,
        'exceeded': APISchemaObject.boolean()
          ..description = 'True if maximum pressure is exceeded'
          ..isReadOnly = true,
      })
        ..description = 'Queue pressure data'
        ..isReadOnly = true,
      'status': APISchemaObject.object({
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
        ..description = 'Queue status'
        ..isReadOnly = true,
    })
      ..description = 'Queue metadata'
      ..isReadOnly = true;
  }

  APISchemaObject _documentSnapshot(APIDocumentContext context) {
    return APISchemaObject.object({
      'uuid': documentUUID()
        ..description = 'Globally unique Snapshot id'
        ..isReadOnly = true,
      'number': APISchemaObject.integer()
        ..description = 'Snapshot event number '
            '(or position in projection if using instance-streams)'
        ..isReadOnly = true,
      'keep': APISchemaObject.integer()
        ..description = 'Number of snapshots to keep until deleting oldest'
        ..isReadOnly = true,
      'unsaved': APISchemaObject.integer()
        ..description = 'Number of unsaved events'
        ..isReadOnly = true,
      'threshold': APISchemaObject.integer()
        ..description = 'Number of unsaved events before saving to next snapshot'
        ..isReadOnly = true,
      'partial': APISchemaObject.object({
        'missing': APISchemaObject.integer()
          ..description = 'Number of missing events in snapshot'
          ..isReadOnly = true,
      })
        ..description = 'Snapshot contains partial state if defined'
        ..isReadOnly = true,
      'aggregates': APISchemaObject.object({
        'count': APISchemaObject.integer()
          ..description = 'Total number aggregates in snapshot'
          ..isReadOnly = true,
        'items': APISchemaObject.array(
          ofSchema: _documentAggregate(context),
        )..description = 'Array of skipped events',
      }),
    })
      ..description = 'Queue pressure data'
      ..isReadOnly = true;
  }

  APISchemaObject _documentAggregate(APIDocumentContext context) {
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
      'data': APISchemaObject.freeForm()
        ..description = 'Map of JSON-Patch compliant values'
        ..isReadOnly = true,
    });
  }

  APISchemaObject _documentConnection(APIDocumentContext context) {
    return APISchemaObject.object({
      'metrics': APISchemaObject.object({
        'read': _documentMetric('Read'),
        'write': _documentMetric('Write'),
      })
        ..description = 'Connection metrics'
        ..isReadOnly = true,
    });
  }

  APISchemaObject _documentMetric(String name) {
    return APISchemaObject.object({
      'count': APISchemaObject.integer()
        ..description = 'Number of measurements'
        ..isReadOnly = true,
      'duration': APISchemaObject.integer()
        ..description = 'Last $name time in ms'
        ..isReadOnly = true,
      'durationAverage': APISchemaObject.integer()
        ..description = '$name time average'
        ..isReadOnly = true,
    })
      ..description = '$name metrics'
      ..isReadOnly = true;
  }

  APISchemaObject _documentSubscriptions(APIDocumentContext context) {
    return APISchemaObject.object({
      'catchup': APISchemaObject.object({
        'isAutomatic': APISchemaObject.boolean()
          ..description = 'True if automatic catchup is activated'
          ..isReadOnly = true,
        'exists': APISchemaObject.boolean()
          ..description = 'True if subscription exists'
          ..isReadOnly = true,
        'last': documentEvent(context)
          ..description = 'Last event processed'
          ..isReadOnly = true,
        'status': APISchemaObject.object({
          'isPaused': APISchemaObject.boolean()
            ..description = 'True if subscription is paused'
            ..isReadOnly = true,
          'isCancelled': APISchemaObject.boolean()
            ..description = 'True if subscription is cancelled'
            ..isReadOnly = true,
          'isCompeting': APISchemaObject.boolean()
            ..description = 'True if subscription is competing (pulling when false)'
            ..isReadOnly = true,
        })
          ..description = 'Catchup subscription status'
          ..isReadOnly = true,
        'stats': APISchemaObject.object({
          'processed': APISchemaObject.integer()
            ..description = 'Number of events processed'
            ..isReadOnly = true,
          'reconnects': APISchemaObject.integer()
            ..description = 'Number of reconnections'
            ..isReadOnly = true,
        })
          ..description = 'Catchup subscription statistics'
          ..isReadOnly = true
      })
        ..description = 'Catchup subscription'
        ..isReadOnly = true,
      'push': APISchemaObject.object({
        'exists': APISchemaObject.boolean()
          ..description = 'True if subscription exists'
          ..isReadOnly = true,
        'isPaused': APISchemaObject.boolean()
          ..description = 'True if subscription is paused'
          ..isReadOnly = true,
      })
        ..description = 'Request queue subscription status'
        ..isReadOnly = true,
    });
  }

  APISchemaObject _documentCommand() {
    return APISchemaObject.object({
      'action': APISchemaObject.string()
        ..description = 'Repository actions'
        ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
        ..enumerated = [
          'rebuild',
          'replay',
          'catchup',
        ],
      'params': APISchemaObject.object({
        'uuids': APISchemaObject.array(ofType: APIType.string)
          ..description = 'List of aggregate uuids which command applies to'
      })
        ..description = 'Command properties'
        ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
    });
  }
}
