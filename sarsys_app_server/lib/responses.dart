import 'dart:io';

import 'package:aqueduct/aqueduct.dart';
import 'package:event_source/event_source.dart';

String toLocation(Request request) => "http://${request.raw.connectionInfo.remoteAddress.host}"
    ":${request.raw.connectionInfo.localPort}${request.raw.uri}";

/// Represents a 503 response.
Response serviceUnavailable({Map<String, dynamic> headers, dynamic body}) => Response(
      HttpStatus.serviceUnavailable,
      headers,
      body,
    );

Response okAggregate(AggregateRoot aggregate) => Response.ok(toAggregateData(aggregate));

Map<String, dynamic> toAggregateData(AggregateRoot aggregate) => {
      "type": "${aggregate.runtimeType}",
      "created": aggregate.createdWhen.toIso8601String(),
      "changed": aggregate.changedWhen.toIso8601String(),
      if (aggregate.isDeleted) "deleted": aggregate.deletedWhen.toIso8601String(),
      "data": aggregate.data,
    };

Response okAggregatePaged(int count, int offset, int limit, List<AggregateRoot> aggregates) => Response.ok({
      "total": count,
      "offset": offset,
      "limit": limit,
      if (offset + aggregates.length < count) "next": offset + aggregates.length,
      "entries": aggregates.map(toAggregateData).toList() ?? [],
    });

Response okEntityPaged<T extends AggregateRoot>(
  String uuid,
  String entity,
  List<Map<String, dynamic>> entities,
) {
  return Response.ok({
    "total": entities.length,
    "entries": entities.map((data) => toEntityData<T>(uuid, entity, data)).toList() ?? [],
  });
}

Response okEntityObject<T extends AggregateRoot>(
  String uuid,
  String entity,
  Map<String, dynamic> data,
) =>
    Response.ok(toEntityData<T>(uuid, entity, data));

Map<String, dynamic> toEntityData<T extends AggregateRoot>(String uuid, String type, Map<String, dynamic> data) => {
      "aggregate": {
        "type": "${typeOf<T>()}",
        "uuid": uuid,
      },
      "type": type,
      "data": data,
    };

Response okValueObject<T extends AggregateRoot>(
  String uuid,
  String type,
  Map<String, dynamic> data,
) =>
    Response.ok(toValueData<T>(uuid, type, data));

Map<String, dynamic> toValueData<T extends AggregateRoot>(String uuid, String type, Map<String, dynamic> data) => {
      "aggregate": {
        "type": "${typeOf<T>()}",
        "uuid": uuid,
      },
      "type": type,
      "data": data,
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
  Map<String, dynamic> headers,
  List<Map<String, dynamic>> mine,
  List<Map<String, dynamic>> yours,
}) =>
    Response.conflict(
      headers: headers,
      body: {
        'type': enumName(type),
        'mine': mine,
        'yours': yours,
      },
    );
