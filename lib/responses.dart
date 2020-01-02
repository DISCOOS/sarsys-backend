import 'dart:io';

import 'package:aqueduct/aqueduct.dart';

import 'eventsource/eventsource.dart';

String toLocation(Request request) => "http://${request.raw.connectionInfo.remoteAddress.host}"
    ":${request.raw.connectionInfo.localPort}${request.raw.uri}";

/// Represents a 503 response.
Response serviceUnavailable({Map<String, dynamic> headers, dynamic body}) => Response(
      HttpStatus.serviceUnavailable,
      headers,
      body,
    );

Response ok(AggregateRoot aggregate) => Response.ok(toData(aggregate));

Map<String, dynamic> toData(AggregateRoot aggregate) => {
      "type": "${aggregate.runtimeType}",
      "changed": aggregate.changedWhen.toIso8601String(),
      "data": aggregate.data,
    };

Response okPaged(int count, int offset, int limit, List<AggregateRoot> aggregates) => Response.ok({
      "total": count,
      "offset": offset,
      "limit": limit,
      if (offset + aggregates.length < count) "next": offset + aggregates.length,
      "entries": aggregates.map(toData).toList() ?? [],
    });
