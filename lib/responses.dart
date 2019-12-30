import 'dart:io';

import 'package:aqueduct/aqueduct.dart';

String toLocation(Request request) => "http://${request.raw.connectionInfo.remoteAddress.host}"
    ":${request.raw.connectionInfo.localPort}${request.raw.uri}";

/// Represents a 503 response.
Response serviceUnavailable({Map<String, dynamic> headers, dynamic body}) => Response(
      HttpStatus.serviceUnavailable,
      headers,
      body,
    );

Response okPaged(int count, int offset, int limit, List<Map<String, dynamic>> data) {
  return Response.ok({
    "total": count,
    "offset": offset,
    "limit": limit,
    if (offset + data.length < count) "next": offset + data.length,
    "data": data ?? [],
  });
}
