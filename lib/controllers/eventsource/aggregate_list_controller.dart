import 'package:sarsys_app_server/controllers/eventsource/aggregate_lookup_controller.dart';
import 'package:sarsys_app_server/eventsource/eventsource.dart';
import 'package:sarsys_app_server/sarsys_app_server.dart';
import 'package:sarsys_app_server/validation/validation.dart';

/// A basic ResourceController for aggregate list requests:
///
/// * [R] - [AggregateRoot] type managed by [foreign] repository
/// * [S] - [Command] type returned by [onCreate] and executed by [foreign] repository
/// * [T] - [AggregateRoot] type managed by [primary] repository
/// * [U] - [Command] type returned by [onCreated] executed by [primary] repository
///
abstract class AggregateListController<R extends Command, S extends AggregateRoot, T extends Command,
    U extends AggregateRoot> extends AggregateLookupController<S> {
  AggregateListController(
    String field,
    this.primary,
    Repository<R, S> foreign,
    this.validator, {
    String tag,
  }) : super(field, primary, foreign, tag: tag);
  @override
  final Repository<T, U> primary;
  final RequestValidator validator;

  //////////////////////////////////
  // Aggregate Operations
  //////////////////////////////////

  @Operation.post('uuid')
  Future<Response> create(
    @Bind.path('uuid') String uuid,
    @Bind.body() Map<String, dynamic> data,
  ) async {
    try {
      if (!primary.contains(uuid)) {
        return Response.notFound(body: "$aggregateType $uuid not found");
      }
      final aggregate = primary.get(uuid);
      final managedUuid = data[foreign.uuidFieldName] as String;
      await foreign.execute(onCreate(managedUuid, validate(data)..addAll(_toParentRef(uuid))));
      await primary.execute(onCreated(aggregate, managedUuid));
      return Response.created("${toLocation(request)}/$managedUuid");
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

  Map<String, dynamic> _toParentRef(String uuid) => {
        "$parentType".toLowerCase(): {
          "${primary.uuidFieldName}": uuid,
        },
      };

  R onCreate(String uuid, Map<String, dynamic> data);
  T onCreated(U aggregate, String foreignUuid);

  Map<String, dynamic> validate(Map<String, dynamic> data) {
    // TODO: Refactor read-only checks into RequestValidator
    if (data.containsKey('incident')) {
      throw SchemaException("Schema $aggregateType has 1 errors: /incident/uuid: read only");
    }
    if (validator != null) {
      validator.validateBody("$aggregateType", data);
    }
    return data;
  }

  //////////////////////////////////
  // Documentation
  //////////////////////////////////

  @override
  String documentOperationSummary(APIDocumentContext context, Operation operation) {
    switch (operation.method) {
      case "POST":
        return "Create ${_toName()} and add uuid to $field in $parentType";
    }
    return super.documentOperationSummary(context, operation);
  }

  @override
  String documentOperationDescription(APIDocumentContext context, Operation operation) {
    switch (operation.method) {
      case "POST":
        return "${documentOperationSummary(context, operation)}. The field [uuid] MUST BE unique for each incident. Use a "
            "[universally unique identifier](https://en.wikipedia.org/wiki/Universally_unique_identifier).";
    }
    return super.documentOperationSummary(context, operation);
  }

  String _toName() => aggregateType.toDelimiterCase(' ');

  @override
  Map<String, APIResponse> documentOperationResponses(APIDocumentContext context, Operation operation) {
    final responses = super.documentOperationResponses(context, operation);
    switch (operation.method) {
      case "POST":
        responses.addAll({
          "201": context.responses.getObject("201"),
          "400": context.responses.getObject("400"),
          "409": context.responses.getObject("409"),
        });
        break;
    }
    return responses;
  }

  @override
  List<APIParameter> documentOperationParameters(APIDocumentContext context, Operation operation) {
    switch (operation.method) {
      case "POST":
        return [
          APIParameter.path('uuid')
            ..description = '$parentType uuid'
            ..isRequired = true,
        ];
    }
    return super.documentOperationParameters(context, operation);
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
    }
    return super.documentOperationRequestBody(context, operation);
  }
}
