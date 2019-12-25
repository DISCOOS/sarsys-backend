import 'dart:async';
import 'dart:io';

import 'package:aqueduct/aqueduct.dart';
import 'package:sarsys_app_server/eventstore/eventstore.dart';
import 'package:sarsys_app_server/sarsys_app_server.dart';
import 'package:uuid/uuid.dart';

class WebSocketController extends Controller {
  WebSocketController(this.channel);
  final MessageChannel channel;

  @override
  FutureOr<RequestOrResponse> handle(Request request) async {
    final socket = await WebSocketTransformer.upgrade(request.raw);
    final appId = request.raw.headers.value('x-app-id') ?? Uuid().v4();
    final heartbeat = request.raw.headers.value('x-with-heartbeat') ?? 'true';
    if (appId != null) {
      channel.subscribe("$appId", socket, withHeartbeat: heartbeat?.toLowerCase() == "true");
    } else {
      await socket.close(WebSocketStatus.protocolError, "Header 'x-app-id' not found");
    }
    return null;
  }
}
