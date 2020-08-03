import 'package:sarsys_domain/sarsys_domain.dart' hide Operation;
import 'package:sarsys_app_server/sarsys_app_server.dart';
import 'package:sarsys_app_server/validation/validation.dart';

import 'device_position_controller.dart';

/// A ResourceController that handles
/// [/api/incidents/{uuid}/messages](http://localhost/api/client.html#/Message) requests
class DevicePositionBatchController extends DevicePositionControllerBase {
  DevicePositionBatchController(DeviceRepository repository, JsonValidation validation)
      : super(
          repository,
          validation,
        );

  @Operation.post('uuid')
  Future<Response> batch(
    @Bind.path('uuid') String uuid,
    @Bind.body() List<Map<String, dynamic>> data,
  ) async {
    if (!await exists(uuid)) {
      return Response.notFound(body: "$aggregateType $uuid not found");
    }
    final codes = <int>{};
    final failures = <Response>[];
    for (var position in data) {
      final response = await update(uuid, position);
      if (response.statusCode >= 400) {
        codes.add(response.statusCode);
        failures.add(response);
      }
    }
    return failures.isEmpty
        ? Response.noContent()
        : Response(codes.length == 1 ? codes.first : HttpStatus.partialContent, {}, {
            'errors': failures
                .map(
                  (response) => '${response.statusCode}: ${response.body}',
                )
                .toList()
          });
  }

//////////////////////////////////
  // Documentation
  //////////////////////////////////

  @override
  String documentOperationSummary(APIDocumentContext context, Operation operation) {
    String summary;
    switch (operation.method) {
      case "POST":
        summary = "Process ${valueType}s";
        break;
    }
    return summary;
  }

  @override
  String documentOperationDescription(APIDocumentContext context, Operation operation) {
    String desc = "${documentOperationSummary(context, operation)}. ";
    switch (operation.method) {
      case "POST":
        desc +=
            "Only fields in each Position are applied. Existing values WILL BE overwritten, others remain unchanged.";
        break;
    }
    return desc;
  }

  @override
  APIRequestBody documentOperationRequestBody(APIDocumentContext context, Operation operation) {
    switch (operation.method) {
      case "POST":
        return APIRequestBody.schema(
          APISchemaObject.array(ofSchema: context.schema[valueType])
            ..description = "Process $valueType. Only fields in each Position are updated.",
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
      "500": context.responses.getObject("503"),
      "503": context.responses.getObject("503"),
    };
    switch (operation.method) {
      case "POST":
        responses.addAll({
          "204": context.responses.getObject("204"),
          "400": context.responses.getObject("400"),
          "409": context.responses.getObject("409"),
        });
        break;
    }
    return responses;
  }
}
