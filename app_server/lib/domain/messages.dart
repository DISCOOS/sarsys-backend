import 'package:sarsys_app_server/sarsys_app_server.dart';
import 'package:event_source/event_source.dart';

class WebSocketMessageProcessor extends MessageHandler<WebSocketMessage> {
  Logger logger = Logger("WebSocketMessageProcessor");
  @override
  void handle(WebSocketMessage message) {
    logger.fine("Received $message");
  }
}
