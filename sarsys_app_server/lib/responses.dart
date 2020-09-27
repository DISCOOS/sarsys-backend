import 'dart:io';

import 'package:aqueduct/aqueduct.dart';
import 'package:event_source/event_source.dart';

String toLocation(Request request) => "http://${request.raw.connectionInfo.remoteAddress.host}"
    ":${request.raw.connectionInfo.localPort}${request.raw.uri}";

// Check if response is an error
bool isError(Response response) => !const [
      HttpStatus.ok,
      HttpStatus.created,
      HttpStatus.noContent,
    ].contains(response.statusCode);

/// Represents a 503 response.
Response serviceUnavailable({int retryAfter = 30, Map<String, dynamic> headers, dynamic body}) => Response(
      HttpStatus.serviceUnavailable,
      headers..addAll({'retry-after': retryAfter}),
      body,
    );

/// Represents a 429 response.
Response tooManyRequests({int retryAfter = 30, Map<String, dynamic> headers, dynamic body}) => Response(
      HttpStatus.tooManyRequests,
      headers..addAll({'retry-after': retryAfter}),
      body,
    );

/// Report error to Sentry and
/// return 500 with message as body
Response serverError(
  Request request,
  Object error,
  StackTrace stackTrace, {
  Logger logger,
}) {
  final String message = "${request.method} ${request.raw.uri} failed";
  logger?.network(message, error, stackTrace);
  final body = error is Map || error is Iterable ? error : "$error";
  return Response.serverError(body: body);
}

Response okAggregate(AggregateRoot aggregate) => Response.ok(toAggregateData(aggregate));

Map<String, dynamic> toAggregateData(AggregateRoot aggregate) => {
      "type": "${aggregate.runtimeType}",
      "number": aggregate.number.value,
      "created": aggregate.createdWhen.toIso8601String(),
      "changed": aggregate.changedWhen.toIso8601String(),
      if (aggregate.isDeleted) "deleted": aggregate.deletedWhen.toIso8601String(),
      "data": aggregate.data,
    };

Response okAggregatePaged(int count, int offset, int limit, Iterable<AggregateRoot> aggregates) => Response.ok(
      toDataPaged(
        count,
        offset,
        limit,
        aggregates.map(toAggregateData),
      ),
    );

Map<String, dynamic> toDataPaged(int count, int offset, int limit, Iterable<Map<String, dynamic>> entries) => {
      "total": count,
      "offset": offset,
      "limit": limit,
      if (offset + entries.length < count) "next": offset + entries.length,
      "entries": entries.toList(),
    };

Response okEntityPaged<T extends AggregateRoot>(
  String uuid,
  String entity,
  EventNumber number,
  List<Map<String, dynamic>> entities,
) {
  return Response.ok({
    "total": entities.length,
    "entries": entities.map((data) => toEntityData<T>(uuid, entity, number, data)).toList() ?? [],
  });
}

Response okEntityObject<T extends AggregateRoot>(
  String uuid,
  String entity,
  EventNumber number,
  Map<String, dynamic> data,
) =>
    Response.ok(
      toEntityData<T>(uuid, entity, number, data),
    );

Map<String, dynamic> toEntityData<T extends AggregateRoot>(
  String uuid,
  String type,
  EventNumber number,
  Map<String, dynamic> data,
) =>
    {
      "aggregate": {
        "type": "${typeOf<T>()}",
        "uuid": uuid,
      },
      "type": type,
      "data": data,
      if (!number.isNone) "number": number.value,
    };

Response okValueObject<T extends AggregateRoot>(
  String uuid,
  String type,
  EventNumber number,
  Map<String, dynamic> data,
) =>
    Response.ok(toValueData<T>(uuid, type, number, data));

Map<String, dynamic> toValueData<T extends AggregateRoot>(
  String uuid,
  String type,
  EventNumber number,
  Map<String, dynamic> data,
) =>
    {
      "aggregate": {
        "type": "${typeOf<T>()}",
        "uuid": uuid,
      },
      "type": type,
      "data": data,
      if (!number.isNone) "number": number.value,
    };

enum ConflictType {
  merge,
  exists,
  deleted,
}

/// Represents a 409 response.
Response conflict(
  ConflictType type,
  String error, {
  String code,
  Map<String, dynamic> base,
  Map<String, dynamic> headers,
  List<Map<String, dynamic>> mine,
  List<Map<String, dynamic>> yours,
}) =>
    Response.conflict(
      headers: headers,
      body: {
        'error': error,
        'type': enumName(type),
        'code': code ?? enumName(type),
        'mine': mine,
        'yours': yours,
        if (base != null) 'base': base,
      },
    );
