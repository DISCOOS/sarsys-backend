import 'package:meta/meta.dart';
import 'package:event_source/event_source.dart';
import 'package:sarsys_app_server/sarsys_app_server.dart';

/// A basic CRUD ResourceController for [Repository] metadata requests
class RepositoryController extends ResourceController {
  RepositoryController(
    this.manager, {
    @required this.tag,
  });

  final String tag;

  final RepositoryManager manager;

  @override
  FutureOr<RequestOrResponse> willProcessRequest(Request req) => manager.isReady
      ? req
      : serviceUnavailable(
          body: "Repositories are unavailable: build pending",
        );

  //////////////////////////////////
  // Aggregate Operations
  //////////////////////////////////

  @Scope(['roles:admin'])
  @Operation.get('type')
  Future<Response> getMeta(
    @Bind.path('type') String type,
  ) async {
    try {
      final repository = manager.getFromTypeName(type);
      if (repository == null) {
        Response.notFound(
          body: 'Repository for type $type not found',
        );
      }
      return Response.ok(
        repository.getMeta(),
      );
    } on InvalidOperation catch (e) {
      return Response.badRequest(body: e.message);
    } catch (e, stackTrace) {
      return toServerError(e, stackTrace);
    }
  }

  @Scope(['roles:admin'])
  @Operation.get('type', 'uuid')
  Future<Response> getMetaWithAggregate(
    @Bind.path('type') String type,
    @Bind.path('uuid') String uuid,
  ) async {
    try {
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
      return Response.ok(
        repository.getMeta(uuid),
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
    @Bind.body() Map<String, dynamic> body,
  ) async {
    try {
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
      }
      return Response.ok(
        repository.getMeta(),
      );
    } on InvalidOperation catch (e) {
      return Response.badRequest(body: e.message);
    } catch (e, stackTrace) {
      return toServerError(e, stackTrace);
    }
  }

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
      case "GET":
        summary = "Get repository metadata";
        break;
      case "POST":
        summary = "Execute command on repository";
        break;
    }
    return summary;
  }

  @override
  String documentOperationDescription(APIDocumentContext context, Operation operation) {
    return "${documentOperationSummary(context, operation)}.";
  }

  @override
  APIRequestBody documentOperationRequestBody(APIDocumentContext context, Operation operation) {
    switch (operation.method) {
      case "POST":
        return APIRequestBody.schema(
          context.schema["RepositoryCommand"],
          description: "Repository Command Request",
          required: true,
        );
        break;
    }
    return super.documentOperationRequestBody(context, operation);
  }

  @override
  Map<String, APIResponse> documentOperationResponses(APIDocumentContext context, Operation operation) {
    final responses = {
      "401": context.responses.getObject("401"),
      "403": context.responses.getObject("403"),
      "503": context.responses.getObject("503"),
    };
    switch (operation.method) {
      case "GET":
        responses.addAll({
          "200": APIResponse.schema(
            "Successful response.",
            context.schema["RepositoryMeta"],
          ),
        });
        break;
      case "POST":
        responses.addAll({
          "200": APIResponse.schema(
            "Successful response.",
            context.schema["RepositoryMeta"],
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
        object.title = "$name";
      }
      if (object.description?.isNotEmpty == false) {
        object.description = "$name schema";
      }
      context.schema.register(name, object);
    });
  }

  Map<String, APISchemaObject> documentSchemaObjects(APIDocumentContext context) => {
        "RepositoryMeta": _documentMeta(),
        "RepositoryCommand": _documentCommand(),
      };

  APISchemaObject _documentMeta() {
    return APISchemaObject.object({
      'type': APISchemaObject.string()
        ..description = 'Aggregate Type'
        ..isReadOnly = true,
      'count': APISchemaObject.integer()
        ..description = 'Number of aggregates'
        ..isReadOnly = true,
      'queue': APISchemaObject.object({
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
        ..isReadOnly = true,
    });
  }

  APISchemaObject _documentCommand() {
    return APISchemaObject.object({
      'action': APISchemaObject.string()
        ..description = "Repository action"
        ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
        ..enumerated = [
          'rebuild',
        ]
    });
  }
}
