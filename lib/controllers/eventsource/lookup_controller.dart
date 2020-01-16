import 'package:sarsys_app_server/eventsource/eventsource.dart';
import 'package:sarsys_app_server/sarsys_app_server.dart';

/// A basic ResourceController for ReadModel requests
class LookupController<T extends AggregateRoot> extends ResourceController {
  LookupController(this.field, this.primary, this.foreign);
  final Repository primary;
  final String field;
  final Repository<Command, T> foreign;

  Type get aggregateType => typeOf<T>();

  @override
  FutureOr<RequestOrResponse> willProcessRequest(Request req) => primary.ready
      ? req
      : serviceUnavailable(
          body: "Repository ${primary.runtimeType} is unavailable: build pending",
        );

  //////////////////////////////////
  // Aggregate Operations
  //////////////////////////////////

  @Operation.get('uuid')
  Future<Response> lookup(
    @Bind.path('uuid') String uuid, {
    @Bind.query('offset') int offset = 0,
    @Bind.query('limit') int limit = 20,
  }) async {
    try {
      if (!primary.contains(uuid)) {
        return Response.notFound(body: "$aggregateType $uuid not found");
      }
      final aggregate = primary.get(uuid);
      final uuids = List<String>.from(aggregate.data[field] as List ?? []);
      final aggregates = uuids.toPage(offset: offset, limit: limit).map(foreign.get).toList();
      return okAggregatePaged(uuids.length, offset, limit, aggregates);
    } on InvalidOperation catch (e) {
      return Response.badRequest(body: e.message);
    } on Failure catch (e) {
      return Response.serverError(body: e.message);
    } on Error catch (e) {
      return Response.serverError(body: e);
    }
  }

  //////////////////////////////////
  // Documentation
  //////////////////////////////////

  @override
  List<String> documentOperationTags(APIDocumentContext context, Operation operation) {
    final tag = "${primary.runtimeType}".replaceAll("Repository", "");
    return [tag];
  }

  @override
  String documentOperationSummary(APIDocumentContext context, Operation operation) {
    String summary;
    switch (operation.method) {
      case "GET":
        summary = "Get all ${_toName()}s";
        break;
    }
    return summary;
  }

  String _toName() => aggregateType.toDelimiterCase(' ');

  @override
  Map<String, APIResponse> documentOperationResponses(APIDocumentContext context, Operation operation) {
    final responses = {
      "401": context.responses.getObject("401"),
      "403": context.responses.getObject("403"),
    };
    switch (operation.method) {
      case "GET":
        responses.addAll({
          "200": APIResponse.schema(
            "Successful response.",
            APISchemaObject.array(ofSchema: context.schema["$aggregateType"]),
          )
        });
        break;
    }
    return responses;
  }

  @override
  List<APIParameter> documentOperationParameters(APIDocumentContext context, Operation operation) {
    switch (operation.method) {
      case "GET":
        return [
          APIParameter.query('offset')..description = 'Start with [${_toName()}] number equal to offset. Default is 0.',
          APIParameter.query('limit')..description = 'Maximum number of [${_toName()}] to fetch. Default is 20.',
        ];
    }
    return super.documentOperationParameters(context, operation);
  }
}
