import 'dart:io';

import 'package:aqueduct/aqueduct.dart';
import 'package:event_source/event_source.dart';

String toLocation(Request request) => 'http://${request.raw.connectionInfo.remoteAddress.host}'
    ':${request.raw.connectionInfo.localPort}${request.raw.uri}';

// Check if response is an error
bool isError(Response response) => !const [
      HttpStatus.ok,
      HttpStatus.created,
      HttpStatus.noContent,
    ].contains(response.statusCode);

/// Represents a 503 response.
Response serviceUnavailable({int retryAfter = 30, Map<String, dynamic> headers, dynamic body}) => Response(
      HttpStatus.serviceUnavailable,
      (headers ?? <String, dynamic>{})..addAll({'retry-after': retryAfter}),
      body,
    );

/// Represents a 504 response.
Response gatewayTimeout({int retryAfter = 30, Map<String, dynamic> headers, dynamic body}) => Response(
      HttpStatus.gatewayTimeout,
      (headers ?? <String, dynamic>{})..addAll({'retry-after': retryAfter}),
      body,
    );

/// Represents a 429 response.
Response tooManyRequests({int retryAfter = 30, Map<String, dynamic> headers, dynamic body}) => Response(
      HttpStatus.tooManyRequests,
      (headers ?? <String, dynamic>{})..addAll({'retry-after': retryAfter}),
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
  final message = '${request.method} ${request.raw.uri} failed';
  logger?.network(message, '$error', stackTrace);
  final body = error is Map || error is Iterable ? error : '$error';
  return Response.serverError(body: body);
}

Response okAggregate(AggregateRoot aggregate) => Response.ok(
      toAggregateData(
        aggregate,
      ),
    );

Response okAggregatePaged(
  int count,
  int offset,
  int limit,
  Iterable<AggregateRoot> aggregates,
) =>
    Response.ok(
      toDataPaged(
        count,
        offset,
        limit,
        aggregates.map(toAggregateData),
      ),
    );

Map<String, dynamic> toAggregateData(AggregateRoot aggregate) => {
      'type': '${aggregate.runtimeType}',
      'number': aggregate.number.value,
      'created': aggregate.createdWhen.toIso8601String(),
      'changed': aggregate.changedWhen.toIso8601String(),
      if (aggregate.isDeleted) 'deleted': aggregate.deletedWhen.toIso8601String(),
      'data': aggregate.data,
    };

Response okEntityObject<T extends AggregateRoot>(
  String uuid,
  String type,
  EventNumber number,
  String path,
  Map<String, dynamic> data,
) =>
    Response.ok(
      toEntityData(
        uuid,
        type,
        number,
        path,
        data: data,
      ),
    );

Response okEntityPaged<T extends AggregateRoot>(
  String uuid,
  String type,
  EventNumber number,
  String path,
  Iterable<Map<String, dynamic>> entities, {
  int count,
  int offset,
  int limit,
}) =>
    Response.ok(
      toEntityData<T>(uuid, type, number, path)
        ..addAll(
          toDataPaged(
            count ?? entities.length,
            offset ?? entities.length,
            limit ?? entities.length,
            entities,
          ),
        ),
    );

Map<String, dynamic> toEntityData<T extends AggregateRoot>(
  String uuid,
  String type,
  EventNumber number,
  String path, {
  Map<String, dynamic> data,
}) {
  return {
    'aggregate': {
      'type': '${typeOf<T>()}',
      'uuid': uuid,
    },
    'type': type,
    'path': path,
    if (!number.isNone) 'number': number.value,
    if (data != null) 'data': data,
  };
}

Response okValueObject<T extends AggregateRoot>(
  String uuid,
  String type,
  EventNumber number,
  String path, {
  dynamic data,
}) =>
    Response.ok(
      toValueData(
        uuid,
        type,
        number,
        path,
        data: data,
      ),
    );

Response okValuePaged<T extends AggregateRoot>(
  String uuid,
  String type,
  EventNumber number,
  String path,
  Iterable<dynamic> entities, {
  int count,
  int offset,
  int limit,
}) =>
    Response.ok(
      toValueData<T>(uuid, type, number, path)
        ..addAll(
          toDataPaged(
            count ?? entities.length,
            offset ?? entities.length,
            limit ?? entities.length,
            entities ?? [],
          ),
        ),
    );

Map<String, dynamic> toValueData<T extends AggregateRoot>(
  String uuid,
  String type,
  EventNumber number,
  String path, {
  dynamic data,
}) =>
    {
      'aggregate': {
        'type': '${typeOf<T>()}',
        'uuid': uuid,
      },
      'type': type,
      'path': path,
      if (!number.isNone) 'number': number.value,
      if (data != null) 'data': data,
    };

Map<String, dynamic> toDataPaged(
  int count,
  int offset,
  int limit,
  Iterable<dynamic> entries,
) =>
    {
      'total': count,
      'offset': offset,
      'limit': limit,
      if (offset + entries.length < count) 'next': offset + entries.length,
      'entries': entries.toList(),
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
