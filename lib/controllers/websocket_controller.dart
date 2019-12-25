import 'dart:async';
import 'dart:io';

import 'package:aqueduct/aqueduct.dart';
import 'package:sarsys_app_server/eventstore/eventstore.dart';
import 'package:sarsys_app_server/sarsys_app_server.dart';

class WebSocketController extends Controller {
  WebSocketController(this.channel);
  final MessageChannel channel;

  @override
  FutureOr<RequestOrResponse> handle(Request request) async {
    final socket = await WebSocketTransformer.upgrade(request.raw);
    final appId = request.raw.headers.value('x-app-id');
    if (appId != null) {
      channel.subscribe("$appId", socket);
    } else {
      await socket.close(WebSocketStatus.protocolError, "Header 'x-app-id' not found");
    }
    return null;
  }
}
