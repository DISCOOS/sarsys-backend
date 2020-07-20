import 'package:event_source/event_source.dart';
import 'package:sarsys_app_server/sarsys_app_server.dart';
import 'package:strings/strings.dart';

/// A basic ResourceController for ReadModel requests
class AggregateLookupController<S extends Command, T extends AggregateRoot> extends ResourceController {
  AggregateLookupController(this.field, this.primary, this.foreign, {this.tag});
  final String tag;
  final String field;
  final Repository primary;
  final Repository<S, T> foreign;

  Type get aggregateType => typeOf<T>();
  Type get primaryType => primary.aggregateType;
  Type get foreignType => foreign.aggregateType;

  @override
  FutureOr<RequestOrResponse> willProcessRequest(Request req) => primary.ready && foreign.ready
      ? req
      : serviceUnavailable(
          body: "Repositories ${[primary.runtimeType, foreign.runtimeType].join(', ')} are unavailable: build pending",
        );

  /// Check if exist. Preform catchup if
  /// not found before checking again.
  Future<bool> exists<T extends AggregateRoot>(Repository repository, String uuid) async {
    if (!repository.contains(uuid)) {
      await repository.catchUp();
    }
    return repository.contains(uuid) && !repository.get(uuid).isDeleted;
  }

  //////////////////////////////////
  // Aggregate Operations
  //////////////////////////////////

  /// Add @Operation.get('uuid') to activate
  Future<Response> get(
    @Bind.path('uuid') String uuid, {
    @Bind.query('offset') int offset = 0,
    @Bind.query('limit') int limit = 20,
  }) async {
    try {
      if (!await exists(primary, uuid)) {
        return Response.notFound(body: "$primaryType $uuid not found");
      }
      final uuids = await removeDeleted(uuid);
      final aggregates = uuids.toPage(offset: offset, limit: limit).map(foreign.get).toList();
      return okAggregatePaged(uuids.length, offset, limit, aggregates);
    } on InvalidOperation catch (e) {
      return Response.badRequest(body: e.message);
    } catch (e) {
      return Response.serverError(body: e);
    }
  }

  Future<List<String>> removeDeleted(String uuid) async {
    final delete = <String>[];
    final aggregate = primary.get(uuid);
    final uuids = List<String>.from(aggregate.data[field] as List ?? []);
    for (String uuid in uuids) {
      if (!await exists(foreign, uuid)) {
        delete.add(uuid);
      }
    }
    uuids.removeWhere(delete.contains);
    return uuids;
  }

  //////////////////////////////////
  // Documentation
  //////////////////////////////////

  @override
  List<String> documentOperationTags(APIDocumentContext context, Operation operation) {
    return [tag ?? "$primaryType"];
  }

  @override
  Map<String, APIOperation> documentOperations(APIDocumentContext context, String route, APIPath path) {
    final operations = super.documentOperations(context, route, path);
    return operations.map((key, method) => MapEntry(
          key,
          APIOperation(
            "${method.id}${capitalize(field)}",
            method.responses,
            summary: method.summary,
            description: method.description,
            parameters: method.parameters,
            requestBody: method.requestBody,
            tags: method.tags,
          ),
        ));
  }

  String toName() => aggregateType.toDelimiterCase(' ');

  @override
  String documentOperationSummary(APIDocumentContext context, Operation operation) {
    String summary;
    switch (operation.method) {
      case "GET":
        summary = "Get all ${toName()}s";
        break;
    }
    return summary;
  }

  @override
  String documentOperationDescription(APIDocumentContext context, Operation operation) {
    return documentOperationSummary(context, operation);
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
          APIParameter.path('uuid')
            ..description = '$primaryType uuid'
            ..isRequired = true,
          APIParameter.query('offset')..description = 'Start with ${toName()} number equal to offset. Default is 0.',
          APIParameter.query('limit')..description = 'Maximum number of ${toName()} to fetch. Default is 20.',
        ];
    }
    return super.documentOperationParameters(context, operation);
  }
}
