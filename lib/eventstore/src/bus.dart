import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:meta/meta.dart';

import 'core.dart';

/// Message bus implementation
class MessageBus implements MessageNotifier, CommandSender, EventPublisher {
  /// Registered message routes from Type to to handlers
  final Map<Type, List<MessageHandler>> _routes = {};

  /// Check if messages are being replayed
  bool get replaying => _replaying;

  /// Flag toggled by integration messages [ReplayStarted] and [ReplayEnded]
  bool _replaying = false;

  /// Register message handler
  void register<T extends Message>(MessageHandler handler) => _routes.update(
        typeOf<T>(),
        (handlers) => handlers..add(handler),
        ifAbsent: () => [handler],
      );

  /// Invoked before first event is replayed
  ///
  /// Throws [InvalidOperation] on illegal [replaying] state.
  void replayStarted() => notify(ReplayStarted());

  /// Invoked after last event is replayed
  ///
  /// Throws [InvalidOperation] on illegal [replaying] state.
  void replayEnded() => notify(ReplayEnded());

  @override
  void notify(Message message) {
    if (message is Event) {
      publish(message);
    } else if (message is Command) {
      send(message);
    } else {
      // message is not an event or command, thus inspection of message is only needed here.
      toHandlers(_inspect(message)).forEach((handler) => handler.handle(message));
    }
  }

  @override
  void publish(Event event) => toHandlers(event).forEach((handler) => handler.handle(event));

  @override
  void send(Command command) {
    // Do not send any commands during replay! This will lead to unexpected results.
    // Replay should only reproduce state, no side effects should occur during replay.
    if (replaying == false) {
      toHandler(command).handle(command);
    }
  }

  /// Inspect message for [ReplayStarted] and [ReplayEnded] integration events
  ///
  /// Throws [InvalidOperation] on illegal [replaying] state.
  Message _inspect(Message message) {
    if (message is ReplayStarted) {
      if (_replaying) {
        throw const InvalidOperation("Illegal state. Is already replaying events");
      }
      _replaying = true;
    } else if (message is ReplayEnded) {
      if (_replaying == false) {
        throw const InvalidOperation("Illegal state. Is not replaying events");
      }
      _replaying = false;
    }
    return message;
  }

  /// Get all handlers for given message
  Iterable<MessageHandler> toHandlers(Message message) => _routes[message.runtimeType] ?? [];

  /// Get a single handler for given message.
  ///
  /// If none or more than one is registered, an [InvalidOperation] is thrown.
  MessageHandler toHandler(Message message) {
    final handlers = _routes[message.runtimeType];
    if (handlers == null) {
      throw InvalidOperation("No handler found for $message");
    } else if (handlers.length > 1) {
      throw InvalidOperation("More than one handler found for $message: $handlers");
    }
    return handlers.first;
  }
}

/// Message indication replay in progress.
///
/// Message handlers should not send any commands during replay.
/// This will lead to unexpected results. Replay should only reproduce
/// state from events. No side effects should occur during replay.
@sealed
class ReplayStarted extends Message {}

/// Message indication replay has ended.
///
/// Message handlers can resume sending commands after replay has ended.
@sealed
class ReplayEnded extends Message {}

/// Manages messages over WebSocket connections
class MessageChannel extends MessageHandler<Event> {
  MessageChannel();
  final Logger logger = Logger("MessageChannel");

  /// Websocket connections
  final _sockets = <String, WebSocket>{};

  /// Handled message types
  final _types = <Type>{};

  /// Register message type [T] as managed
  void register<T extends Message>(MessageBus bus) {
    _types.add(typeOf<T>());
    bus.register<T>(this);
  }

  /// Subscribe [appId] to receive messages with [socket]
  void subscribe(String appId, WebSocket socket) {
    _sockets.update(appId, (current) {
      if (current.readyState == WebSocket.open) {
        current.close(
          WebSocketStatus.protocolError,
          _info("Only one connection per application, connection from $appId rejected"),
        );
      }
      socket.listen(
        // TODO: Listen for data from clients
        (_) {},
        onDone: () => _remove(appId, socket),
        onError: () => _remove(appId, socket),
      );
      return socket;
    }, ifAbsent: () => socket);
    _info("Websocket connection from $appId established");
  }

  void _remove(String appId, WebSocket socket) {
    _sockets.remove(socket);
    _info("Removed socket for $appId");
  }

  void unsubscribe(String appId) => _sockets[appId]?.close(
        WebSocketStatus.normalClosure,
        _info("Unsubscribe $appId"),
      );

  /// Dispose all WebSocket connection
  void dispose() {
    _sockets.forEach(
      (appId, socket) => socket.close(
        WebSocketStatus.normalClosure,
        _info("Closed connection to $appId"),
      ),
    );
    _sockets.clear();
  }

  @override
  void handle(Message message) {
    if (_types.contains(message.runtimeType)) {
      _sockets.values.forEach(
        (socket) {
          try {
            final data = _toData(message);
            if (data != null) {
              socket.add(data);
            }
          } catch (e) {
            logger.warning("Failed to publish message $message: $e");
          }
        },
      );
    }
  }

  String _toData(Message message) {
    if (message is Event) {
      return json.encode({message.type: message.data});
    } else {
      return json.encode({'type': "${message.runtimeType}"});
    }
  }

  String _info(String message) {
    logger.info(message);
    return message;
  }
}
