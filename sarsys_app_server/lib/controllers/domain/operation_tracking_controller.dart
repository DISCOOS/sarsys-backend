import 'dart:io';

import 'package:meta/meta.dart';
import 'package:aqueduct/aqueduct.dart';

import 'package:event_source/event_source.dart';
import 'package:sarsys_app_server/controllers/domain/schemas.dart';
import 'package:sarsys_app_server/responses.dart';
import 'package:sarsys_domain/sarsys_domain.dart' hide Operation;
import 'package:sarsys_domain/sarsys_domain.dart' as sar show Operation;

/// Implement controller for field `trackings` in [sar.Operation]
class OperationTrackingController extends ResourceController {
  OperationTrackingController({
    @required this.units,
    @required this.trackings,
    @required this.operations,
    @required this.personnels,
  });

  UnitRepository units;
  TrackingRepository trackings;
  PersonnelRepository personnels;
  OperationRepository operations;

  @Operation.get('uuid')
  Future<Response> get(
    @Bind.path('uuid') String uuid, {
    @Bind.query('limit') int limit = 20,
    @Bind.query('offset') int offset = 0,
    @Bind.query('include') List<String> include = const ['unit', 'personnel'],
  }) async {
    try {
      if (!await exists(operations, uuid)) {
        return Response.notFound(body: "Operation $uuid not found");
      }
      final operation = operations.get(uuid);
      final tuuids = <String>[];
      if (_shouldInclude(include, 'unit')) {
        for (var uuuid in operation.listAt<String>('units', defaultList: [])) {
          if (units.exists(uuuid)) {
            final tuuid = units.get(uuuid).elementAt<String>('tracking/uuid');
            if (trackings.exists(tuuid)) {
              tuuids.add(tuuid);
            }
          }
        }
      }
      if (_shouldInclude(include, 'personnel')) {
        for (var puuid in operation.listAt<String>('personnels', defaultList: [])) {
          if (personnels.exists(puuid)) {
            final tuuid = personnels.get(puuid).elementAt<String>('tracking/uuid');
            if (trackings.exists(tuuid)) {
              tuuids.add(tuuid);
            }
          }
        }
      }
      final total = tuuids.length;
      final page = tuuids.toPage(
        offset: offset,
        limit: limit,
      );
      return okAggregatePaged(
        total,
        offset,
        limit,
        page.map((uuid) => trackings.get(uuid)),
      );
    } on RepositoryMaxPressureExceeded catch (e) {
      return tooManyRequests(body: e.message);
    } on CommandTimeout catch (e) {
      return gatewayTimeout(
        body: e.message,
      );
    } on StreamRequestTimeout catch (e) {
      return gatewayTimeout(
        body: "Repository command queue was unable to process ${e.request.tag}",
      );
    } on SocketException catch (e) {
      return serviceUnavailable(body: "Eventstore unavailable: $e");
    } on InvalidOperation catch (e) {
      return Response.badRequest(body: e.message);
    } catch (e, stackTrace) {
      return toServerError(e, stackTrace);
    }
  }

  /// Check if exist. Preform catchup if
  /// not found before checking again.
  Future<bool> exists<T extends AggregateRoot>(Repository repository, String uuid) async {
    if (!repository.contains(uuid)) {
      await repository.catchup(
        master: true,
        uuids: [uuid],
      );
    }
    return repository.contains(uuid) && !repository.get(uuid).isDeleted;
  }

  bool _shouldInclude(List<String> include, String type) {
    if (include.any((element) => element.toLowerCase() == type.toLowerCase())) {
      return true;
    }
    return false;
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
  List<String> documentOperationTags(APIDocumentContext context, Operation operation) {
    return ['Operation > Trackings'];
  }

  @override
  Map<String, APIOperation> documentOperations(APIDocumentContext context, String route, APIPath path) {
    final operations = super.documentOperations(context, route, path);
    return operations.map((key, method) => MapEntry(
          key,
          APIOperation(
            "${method.id}$Tracking",
            method.responses,
            summary: method.summary,
            description: method.description,
            parameters: method.parameters,
            requestBody: method.requestBody,
            tags: method.tags,
          ),
        ));
  }

  String toName() => 'Tracking';

  @override
  String documentOperationSummary(APIDocumentContext context, Operation operation) {
    String summary;
    switch (operation.method) {
      case "GET":
        summary = "Get all ${toName()}s for given Operation uuid";
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
            documentAggregatePageResponse(
              context,
              type: 'Tracking',
            ),
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
            ..description = '${toName()} uuid'
            ..isRequired = true,
          APIParameter.query('offset')..description = 'Start with ${toName()} number equal to offset. Default is 0.',
          APIParameter.query('limit')..description = 'Maximum number of ${toName()} to fetch. Default is 20.',
          APIParameter.query('include')
            ..description = 'Array of trackable aggregate types. Allowed are [unit, personnel]',
        ];
    }
    return super.documentOperationParameters(context, operation);
  }
}
