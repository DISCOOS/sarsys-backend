import 'package:sarsys_app_server/eventsource/eventsource.dart';
import 'package:sarsys_app_server/sarsys_app_server.dart';
import 'package:sarsys_app_server/validation/validation.dart';

// TODO: Add support for entities as query-param to limit default response to only value objects

/// A basic CRUD ResourceController for [AggregateRoot] requests
abstract class AggregateController<S extends Command, T extends AggregateRoot> extends ResourceController {
  AggregateController(this.repository, {this.validator});
  final RequestValidator validator;
  final Repository<S, T> repository;

  Type get aggregateType => typeOf<T>();

  @override
  FutureOr<RequestOrResponse> willProcessRequest(Request req) => repository.ready
      ? req
      : serviceUnavailable(
          body: "Repository ${repository.runtimeType} is unavailable: build pending",
        );

  //////////////////////////////////
  // Aggregate Operations
  //////////////////////////////////

  @Operation.get()
  Future<Response> getAll({
    @Bind.query('offset') int offset = 0,
    @Bind.query('limit') int limit = 20,
  }) async {
    try {
      final events = repository.getAll(offset: offset, limit: limit).toList();
      return okAggregatePaged(repository.count, offset, limit, events);
    } on InvalidOperation catch (e) {
      return Response.badRequest(body: e.message);
    } on Failure catch (e) {
      return Response.serverError(body: e.message);
    } on Error catch (e) {
      return Response.serverError(body: e);
    }
  }

  @Operation.get('uuid')
  Future<Response> getByUuid(@Bind.path('uuid') String uuid) async {
    try {
      if (!repository.contains(uuid)) {
        return Response.notFound(body: "$aggregateType $uuid not found");
      }
      return okAggregate(repository.get(uuid));
    } on InvalidOperation catch (e) {
      return Response.badRequest(body: e.message);
    } on Failure catch (e) {
      return Response.serverError(body: e.message);
    }
  }

  @Operation.post()
  Future<Response> create(@Bind.body() Map<String, dynamic> data) async {
    try {
      await repository.execute(onCreate(validate(data)));
      return Response.created("${toLocation(request)}/${data[repository.uuidFieldName]}");
    } on AggregateExists catch (e) {
      return Response.conflict(body: e.message);
    } on UUIDIsNull {
      return Response.badRequest(body: "Field [uuid] in $aggregateType is required");
    } on InvalidOperation catch (e) {
      return Response.badRequest(body: e.message);
    } on SchemaException catch (e) {
      return Response.badRequest(body: e.message);
    } on SocketException catch (e) {
      return serviceUnavailable(body: "Eventstore unavailable: $e");
    } on Failure catch (e) {
      return Response.serverError(body: e.message);
    }
  }

  S onCreate(Map<String, dynamic> data) => throw UnsupportedError("Create not implemented");

  @Operation('PATCH', 'uuid')
  Future<Response> update(@Bind.path('uuid') String uuid, @Bind.body() Map<String, dynamic> data) async {
    try {
      if (!repository.contains(uuid)) {
        return Response.notFound(body: "$aggregateType $uuid not found");
      }
      data[repository.uuidFieldName] = uuid;
      final events = await repository.execute(onUpdate(validate(data)));
      return events.isEmpty ? Response.noContent() : Response.noContent();
    } on AggregateNotFound catch (e) {
      return Response.notFound(body: e.message);
    } on UUIDIsNull {
      return Response.badRequest(body: "Field [uuid] in $aggregateType is required");
    } on InvalidOperation catch (e) {
      return Response.badRequest(body: e.message);
    } on SchemaException catch (e) {
      return Response.badRequest(body: e.message);
    } on SocketException catch (e) {
      return serviceUnavailable(body: "Eventstore unavailable: $e");
    } on Failure catch (e) {
      return Response.serverError(body: e.message);
    }
  }

  S onUpdate(Map<String, dynamic> data) => throw UnsupportedError("Update not implemented");

  @Operation('DELETE', 'uuid')
  Future<Response> delete(
    @Bind.path('uuid') String uuid, {
    @Bind.body() Map<String, dynamic> data,
  }) async {
    try {
      if (!repository.contains(uuid)) {
        return Response.notFound(body: "$aggregateType $uuid not found");
      }
      final aggregate = data ?? {};
      aggregate[repository.uuidFieldName] = uuid;
      final events = await repository.execute(onDelete(validate(aggregate)));
      return events.isEmpty ? Response.noContent() : Response.noContent();
    } on AggregateNotFound catch (e) {
      return Response.notFound(body: e.message);
    } on UUIDIsNull {
      return Response.badRequest(body: "Field [uuid] in $aggregateType is required");
    } on InvalidOperation catch (e) {
      return Response.badRequest(body: e.message);
    } on SchemaException catch (e) {
      return Response.badRequest(body: e.message);
    } on SocketException catch (e) {
      return serviceUnavailable(body: "Eventstore unavailable: $e");
    } on Failure catch (e) {
      return Response.serverError(body: e.message);
    }
  }

  S onDelete(Map<String, dynamic> data) => throw UnsupportedError("Update not implemented");

  //////////////////////////////////
  // Documentation
  //////////////////////////////////

  @override
  String documentOperationSummary(APIDocumentContext context, Operation operation) {
    String summary;
    switch (operation.method) {
      case "GET":
        summary = operation.pathVariables.isEmpty ? "Get all ${_toName()}s" : "Get ${_toName()}";
        break;
      case "POST":
        summary = "Create ${_toName()}";
        break;
      case "PATCH":
        summary = "Update ${_toName()}";
        break;
    }
    return summary;
  }

  String _toName() => aggregateType.toDelimiterCase(' ');

  @override
  String documentOperationDescription(APIDocumentContext context, Operation operation) {
    String desc = "${documentOperationSummary(context, operation)}. ";
    switch (operation.method) {
      case "POST":
        desc += "The field [uuid] MUST BE unique for each $aggregateType. Use a "
            "[universally unique identifier](https://en.wikipedia.org/wiki/Universally_unique_identifier).";
        break;
      case "PATCH":
        desc += "Only fields in request are applied to $aggregateType. Other values remain unchanged.";
        break;
    }
    return desc;
  }

  @override
  APIRequestBody documentOperationRequestBody(APIDocumentContext context, Operation operation) {
    switch (operation.method) {
      case "POST":
        return APIRequestBody.schema(
          context.schema["$aggregateType"],
          description: "New $aggregateType",
          required: true,
        );
        break;
      case "PATCH":
        return APIRequestBody.schema(
          context.schema["$aggregateType"],
          description: "Update $aggregateType. Only fields in request are updated.",
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
    };
    switch (operation.method) {
      case "GET":
        if (operation.pathVariables.isEmpty) {
          responses.addAll({
            "200": APIResponse.schema(
              "Successful response.",
              APISchemaObject.array(ofSchema: context.schema["$aggregateType"]),
            )
          });
        } else {
          responses.addAll({
            "200": APIResponse.schema("Successful response", context.schema["$aggregateType"]),
          });
        }
        break;
      case "POST":
        responses.addAll({
          "201": context.responses.getObject("201"),
          "400": context.responses.getObject("400"),
          "409": context.responses.getObject("409"),
          "409": context.responses.getObject("409"),
          "503": context.responses.getObject("503"),
        });
        break;
      case "PATCH":
        responses.addAll({
          "204": context.responses.getObject("204"),
          "400": context.responses.getObject("400"),
          "409": context.responses.getObject("409"),
          "503": context.responses.getObject("503"),
        });
        break;
    }
    return responses;
  }

  @override
  List<APIParameter> documentOperationParameters(APIDocumentContext context, Operation operation) {
    switch (operation.method) {
      case "GET":
        if (operation.pathVariables.isEmpty) {
          return [
            APIParameter.query('offset')
              ..description = 'Start with [${_toName()}] number equal to offset. Default is 0.',
            APIParameter.query('limit')..description = 'Maximum number of [${_toName()}] to fetch. Default is 20.',
          ];
        }
        break;
    }
    return super.documentOperationParameters(context, operation);
  }

  @override
  void documentComponents(APIDocumentContext context) {
    super.documentComponents(context);
    _documentSchemaObjects(context).forEach((name, object) {
      if (object.title?.isNotEmpty == false) {
        object.title = "$name";
      }
      if (object.description?.isNotEmpty == false) {
        object.description = "$name schema";
      }
      if (object.title == "$aggregateType" && object.required?.contains(repository.uuidFieldName) == false) {
        if (!object.properties.containsKey(repository.uuidFieldName)) {
          throw UnimplementedError("Property '${repository.uuidFieldName}' is required for aggregates");
        }
        object.required = ["uuid", ...object.required];
      }
      context.schema.register(name, object);
    });
  }

  Map<String, APISchemaObject> _documentSchemaObjects(APIDocumentContext context) => {
        "$aggregateType": documentAggregateRoot(context),
      }
        ..addAll(documentEntities(context))
        ..addAll(documentValues(context));

  APISchemaObject documentAggregateRoot(APIDocumentContext context);

  Map<String, APISchemaObject> documentEntities(APIDocumentContext context) => {};
  Map<String, APISchemaObject> documentValues(APIDocumentContext context) => {};

  Map<String, dynamic> validate(Map<String, dynamic> data) {
    if (validator != null) {
      validator.validateBody("$aggregateType", data);
    }
    return data;
  }
}
