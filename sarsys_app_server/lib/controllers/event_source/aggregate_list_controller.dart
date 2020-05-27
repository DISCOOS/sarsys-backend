import 'package:sarsys_app_server/controllers/event_source/aggregate_lookup_controller.dart';
import 'package:event_source/event_source.dart';
import 'package:sarsys_app_server/sarsys_app_server.dart';
import 'package:sarsys_app_server/validation/validation.dart';

import 'mixins.dart';

/// A basic ResourceController for aggregate list requests:
///
/// * [R] - [AggregateRoot] type managed by [foreign] repository
/// * [S] - [Command] type returned by [onCreate] and executed by [foreign] repository
/// * [T] - [AggregateRoot] type managed by [primary] repository
/// * [U] - [Command] type returned by [onCreated] executed by [primary] repository
///
abstract class AggregateListController<R extends Command, S extends AggregateRoot, T extends Command,
    U extends AggregateRoot> extends AggregateLookupController<S> with RequestValidatorMixin {
  AggregateListController(
    String field,
    this.primary,
    Repository<R, S> foreign,
    this.validation, {
    String tag,
    this.readOnly = const [],
  }) : super(field, primary, foreign, tag: tag);

  @override
  final List<String> readOnly;

  @override
  final JsonValidation validation;

  @override
  final Repository<T, U> primary;

  //////////////////////////////////
  // Aggregate Operations
  //////////////////////////////////

  @Operation.post('uuid')
  Future<Response> create(
    @Bind.path('uuid') String uuid,
    @Bind.body() Map<String, dynamic> data,
  ) async {
    try {
      if (!primary.exists(uuid)) {
        return Response.notFound(body: "$primaryType $uuid not found");
      }
      final aggregate = primary.get(uuid);
      final managedUuid = data[foreign.uuidFieldName] as String;
      await foreign.execute(onCreate(managedUuid, validate("${typeOf<S>()}", data)..addAll(_toParentRef(uuid))));
      await primary.execute(onCreated(aggregate, managedUuid));
      return Response.created("${toLocation(request)}/$managedUuid");
    } on AggregateExists catch (e) {
      return conflict(
        ConflictType.merge,
        e.message,
      );
    } on EntityExists catch (e) {
      return conflict(
        ConflictType.merge,
        e.message,
      );
    } on ConflictNotReconcilable catch (e) {
      return conflict(
        ConflictType.merge,
        e.message,
        mine: e.mine,
        yours: e.yours,
      );
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
        "$primaryType".toLowerCase(): {
          "${primary.uuidFieldName}": uuid,
        },
      };

  R onCreate(String uuid, Map<String, dynamic> data);
  T onCreated(U aggregate, String foreignUuid);

  //////////////////////////////////
  // Documentation
  //////////////////////////////////

  @override
  String documentOperationSummary(APIDocumentContext context, Operation operation) {
    switch (operation.method) {
      case "POST":
        return "Create ${_toName()} and add uuid to $field in $primaryType";
    }
    return super.documentOperationSummary(context, operation);
  }

  @override
  String documentOperationDescription(APIDocumentContext context, Operation operation) {
    switch (operation.method) {
      case "POST":
        return "${documentOperationSummary(context, operation)}. The field [uuid] MUST BE unique for each ${_toName()}. "
            "Use a [universally unique identifier](https://en.wikipedia.org/wiki/Universally_unique_identifier).";
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
            ..description = '$primaryType uuid'
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
