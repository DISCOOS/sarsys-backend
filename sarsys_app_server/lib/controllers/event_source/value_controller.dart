import 'package:event_source/event_source.dart';
import 'package:sarsys_app_server/controllers/domain/schemas.dart';
import 'package:sarsys_app_server/sarsys_app_server.dart';
import 'package:sarsys_app_server/validation/validation.dart';
import 'package:strings/strings.dart';

import 'mixins.dart';

/// A basic CRUD ResourceController for [AggregateRoot] value requests
abstract class ValueController<S extends Command, T extends AggregateRoot> extends ResourceController
    with RequestValidatorMixin {
  ValueController(
    this.repository,
    this.valueType,
    this.aggregateField, {
    this.tag,
    this.validation,
    this.readOnly = const [],
    this.validators = const [],
  });
  final String tag;
  final String valueType;
  final String aggregateField;
  final Repository<S, T> repository;

  /// Get aggregate [Type]
  Type get aggregateType => typeOf<T>();

  @override
  final List<String> readOnly;

  @override
  final JsonValidation validation;

  @override
  final List<Validator> validators;

  @override
  FutureOr<RequestOrResponse> willProcessRequest(Request req) => repository.ready
      ? req
      : serviceUnavailable(
          body: "Repository ${repository.runtimeType} is unavailable: build pending",
        );

  //////////////////////////////////
  // Entity Operations
  //////////////////////////////////

  /// Add @Operation.get('uuid') to activate
  Future<Response> get(
    @Bind.path('uuid') String uuid,
  ) async {
    try {
      if (!repository.exists(uuid)) {
        return Response.notFound(body: "$aggregateType $uuid not found");
      }
      final aggregate = repository.get(uuid);
      final value = aggregate.data.elementAt(aggregateField);
      if (value is Map<String, dynamic>) {
        return okValueObject<T>(
          uuid,
          valueType,
          value,
        );
      } else if (value == null) {
        return Response.notFound(body: "Value $aggregateField not found");
      } else {
        return Response.serverError(body: "Value $aggregateField is an object");
      }
    } on InvalidOperation catch (e) {
      return Response.badRequest(body: e.message);
    } on Failure catch (e) {
      return Response.serverError(body: e.message);
    }
  }

  /// Add @Operation('PATCH', 'uuid') to active
  Future<Response> update(
    @Bind.path('uuid') String uuid,
    @Bind.body() Map<String, dynamic> data,
  ) async {
    try {
      if (!repository.exists(uuid)) {
        return Response.notFound(body: "$aggregateType $uuid not found");
      }
      final events = await repository.execute(
        onUpdate(uuid, valueType, {
          'uuid': uuid,
          aggregateField: validate(valueType, data, isPatch: true),
        }),
      );
      return events.isEmpty ? Response.noContent() : Response.noContent();
    } on ConflictNotReconcilable catch (e) {
      return conflict(
        ConflictType.merge,
        e.message,
        mine: e.mine,
        yours: e.yours,
      );
    } on SchemaException catch (e) {
      return Response.badRequest(body: e.message);
    } on SocketException catch (e) {
      return serviceUnavailable(body: "Eventstore unavailable: $e");
    } on InvalidOperation catch (e) {
      return Response.badRequest(body: e.message);
    } on Failure catch (e) {
      return Response.serverError(body: e.message);
    }
  }

  S onUpdate(String uuid, String type, Map<String, dynamic> data) => throw UnsupportedError("Update not implemented");

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
        summary = "Get $valueType";
        break;
      case "PATCH":
        summary = "Update $valueType";
        break;
    }
    return summary;
  }

  @override
  String documentOperationDescription(APIDocumentContext context, Operation operation) {
    String desc = "${documentOperationSummary(context, operation)}. ";
    switch (operation.method) {
      case "PATCH":
        desc += "Only fields in request are updated. Existing values WILL BE overwritten, others remain unchanged.";
        break;
    }
    return desc;
  }

  @override
  APIRequestBody documentOperationRequestBody(APIDocumentContext context, Operation operation) {
    switch (operation.method) {
      case "PATCH":
        return APIRequestBody.schema(
          context.schema[valueType],
          description: "Update $valueType. Only fields in request are updated.",
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
            "Successful response",
            documentValueResponse(context, type: valueType),
          ),
        });
        break;
      case "PATCH":
        responses.addAll({
          "204": context.responses.getObject("204"),
          "400": context.responses.getObject("400"),
          "409": context.responses.getObject("409"),
        });
        break;
    }
    return responses;
  }

  @override
  Map<String, APIOperation> documentOperations(APIDocumentContext context, String route, APIPath path) {
    final operations = super.documentOperations(context, route, path);
    return operations.map((key, method) => MapEntry(
          key,
          APIOperation(
            "${method.id}${capitalize(valueType)}",
            method.responses,
            summary: method.summary,
            description: method.description,
            parameters: method.parameters,
            requestBody: method.requestBody,
            tags: method.tags,
          ),
        ));
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
        valueType: documentValueObject(context),
      };

  APISchemaObject documentValueObject(APIDocumentContext context) => context.schema[valueType];
}
