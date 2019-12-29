import 'package:sarsys_app_server/sarsys_app_server.dart';
import 'package:sarsys_app_server/eventsource/eventsource.dart';

class WebSocketMessageProcessor extends MessageHandler<WebSocketMessage> {
  Logger logger = Logger("WebSocketMessageProcessor");
  @override
  void handle(WebSocketMessage message) {
    logger.fine("Received $message");
  }
}
