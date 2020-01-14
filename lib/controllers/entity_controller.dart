import 'package:sarsys_app_server/eventsource/eventsource.dart';
import 'package:sarsys_app_server/sarsys_app_server.dart';
import 'package:sarsys_app_server/validation/validation.dart';

/// A basic CRUD ResourceController for [AggregateRoot] entity requests
abstract class EntityController<S extends Command, T extends AggregateRoot> extends ResourceController {
  EntityController(this.repository, this.entityType, this.aggregateField, {this.validator});
  final String entityType;
  final String aggregateField;
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
  // Entity Operations
  //////////////////////////////////

  @Operation.get('uuid')
  Future<Response> getAll(@Bind.path('uuid') String uuid) async {
    try {
      if (!repository.contains(uuid)) {
        return Response.notFound(body: "$aggregateType $uuid not found");
      }
      return okEntities<T>(
        uuid,
        entityType,
        List<Map<String, dynamic>>.from(repository.get(uuid).data[aggregateField] as List<dynamic>),
      );
    } on InvalidOperation catch (e) {
      return Response.badRequest(body: e.message);
    } on Failure catch (e) {
      return Response.serverError(body: e.message);
    }
  }

  @Operation.get('uuid', 'id')
  Future<Response> getById(
    @Bind.path('uuid') String uuid,
    @Bind.path('id') int id,
  ) async {
    try {
      if (!repository.contains(uuid)) {
        return Response.notFound(body: "$aggregateType $uuid not found");
      }
      final aggregate = repository.get(uuid);
      final data = aggregate.data[aggregateField] as List;
      if (data.isEmpty || data.length - 1 < id) {
        return Response.notFound(body: "Entity $id not found");
      }
      return okEntity<T>(
        uuid,
        entityType,
        data.elementAt(id) as Map<String, dynamic>,
      );
    } on InvalidOperation catch (e) {
      return Response.badRequest(body: e.message);
    } on Failure catch (e) {
      return Response.serverError(body: e.message);
    }
  }

  @Operation.post('uuid')
  Future<Response> create(
    @Bind.path('uuid') String uuid,
    @Bind.body() Map<String, dynamic> data,
  ) async {
    try {
      if (repository.contains(uuid)) {
        return Response.notFound(body: "$aggregateType $uuid exists");
      }
      final aggregate = repository.get(uuid);
      await repository.execute(onCreate(uuid, entityType, validate(data)));
      return Response.created("${toLocation(request)}/${data[aggregate.entityIdFieldName]}");
    } on AggregateExists catch (e) {
      return Response.conflict(body: e.message);
    } on EntityExists catch (e) {
      return Response.conflict(body: e.message);
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

  S onCreate(String uuid, String type, Map<String, dynamic> data) => throw UnsupportedError("Create not implemented");

  @Operation('PATCH', 'uuid', 'id')
  Future<Response> update(
    @Bind.path('uuid') String uuid,
    @Bind.path('id') int id,
    @Bind.body() Map<String, dynamic> data,
  ) async {
    try {
      if (!repository.contains(uuid)) {
        return Response.notFound(body: "$aggregateType $uuid not found");
      }
      final aggregate = repository.get(uuid);
      data[aggregate.entityIdFieldName] = id;
      final events = await repository.execute(onUpdate(uuid, entityType, validate(data)));
      return events.isEmpty ? Response.noContent() : Response.noContent();
    } on EntityNotFound catch (e) {
      return Response.notFound(body: e.message);
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

  S onUpdate(String uuid, String type, Map<String, dynamic> data) => throw UnsupportedError("Update not implemented");

  @Operation('DELETE', 'uuid', 'id')
  Future<Response> delete(
    @Bind.path('uuid') String uuid,
    @Bind.path('id') int id, {
    @Bind.body() Map<String, dynamic> data,
  }) async {
    try {
      if (!repository.contains(uuid)) {
        return Response.notFound(body: "Aggregate $uuid not found");
      }
      final aggregate = repository.get(uuid);
      final entity = data ?? {};
      entity[aggregate.entityIdFieldName] = id;
      final events = await repository.execute(onDelete(uuid, entityType, validate(entity)));
      return events.isEmpty ? Response.noContent() : Response.noContent();
    } on AggregateNotFound catch (e) {
      return Response.notFound(body: e.message);
    } on EntityNotFound catch (e) {
      return Response.notFound(body: e.message);
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

  S onDelete(String uuid, String type, Map<String, dynamic> data) => throw UnsupportedError("Remove not implemented");

  //////////////////////////////////
  // Documentation
  //////////////////////////////////

  @override
  String documentOperationSummary(APIDocumentContext context, Operation operation) {
    String summary;
    switch (operation.method) {
      case "GET":
        summary = operation.pathVariables.length < 2 ? "Get all ${_toLowerCase()}s" : "Get ${_toLowerCase()}";
        break;
      case "POST":
        summary = "Create ${_toLowerCase()}";
        break;
      case "PATCH":
        summary = "Update ${_toLowerCase()}";
        break;
      case "DELETE":
        summary = "Delete ${_toLowerCase()}";
        break;
    }
    return summary;
  }

  String _toLowerCase() => entityType.toLowerCase();

  @override
  String documentOperationDescription(APIDocumentContext context, Operation operation) {
    String desc = "${documentOperationSummary(context, operation)}. ";
    switch (operation.method) {
      case "POST":
        desc += "The field [uuid] MUST BE unique for each incident. Use a "
            "[universally unique identifier](https://en.wikipedia.org/wiki/Universally_unique_identifier).";
        break;
      case "PATCH":
        desc += "Only fields in request are updated. Existing values WILL BE overwritten, others remain unchanged.";
        break;
    }
    return desc;
  }

  @override
  APIRequestBody documentOperationRequestBody(APIDocumentContext context, Operation operation) {
    switch (operation.method) {
      case "POST":
        return APIRequestBody.schema(
          context.schema[entityType],
          description: "New $entityType",
          required: true,
        );
        break;
      case "PATCH":
        return APIRequestBody.schema(
          context.schema[entityType],
          description: "Update $entityType. Only fields in request are updated.",
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
              APISchemaObject.array(ofSchema: context.schema[entityType]),
            )
          });
        } else {
          responses.addAll({
            "200": APIResponse.schema("Successful response", context.schema[entityType]),
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
  void documentComponents(APIDocumentContext context) {
    super.documentComponents(context);
    _documentSchemaObjects(context).forEach((name, object) {
      if (object.title?.isNotEmpty == false) {
        object.title = "$name";
      }
      if (object.description?.isNotEmpty == false) {
        object.description = "$name schema";
      }
      context.schema.register(name, object);
    });
  }

  Map<String, APISchemaObject> _documentSchemaObjects(APIDocumentContext context) => {
        entityType: documentEntityObject(context),
      }..addAll(documentEntities(context));

  APISchemaObject documentEntityObject(APIDocumentContext context);

  Map<String, APISchemaObject> documentEntities(APIDocumentContext context) => {};

  Map<String, dynamic> validate(Map<String, dynamic> data) {
    if (validator != null) {
      validator.validateBody("$entityType", data);
    }
    return data;
  }
}
