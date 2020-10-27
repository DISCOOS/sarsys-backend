import 'package:event_source/event_source.dart';
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
    try {
      final trx = repository.getTransaction(uuid);
      for (var position in data) {
        await trx.execute(
          onUpdate(uuid, valueType, {
            'uuid': uuid,
            aggregateField: validate(
              valueType,
              process(uuid, position),
              isPatch: true,
            ),
          }),
        );
      }
      await trx.push();
      return Response.noContent();
    } on ConflictNotReconcilable catch (e) {
      return conflict(
        ConflictType.merge,
        e.message,
        base: e.base,
        mine: e.mine,
        yours: e.yours,
      );
    } on SchemaException catch (e) {
      return Response.badRequest(body: e.message);
    } on RepositoryMaxPressureExceeded catch (e) {
      return tooManyRequests(body: e.message);
    } on StreamRequestTimeout catch (e) {
      return serviceUnavailable(
        body: "Repository $aggregateType was unable to process request ${e.request.tag}",
      );
    } on SocketException catch (e) {
      return serviceUnavailable(body: "Eventstore unavailable: $e");
    } on InvalidOperation catch (e) {
      return Response.badRequest(body: e.message);
    } catch (e, stackTrace) {
      return toServerError(e, stackTrace);
    }
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
