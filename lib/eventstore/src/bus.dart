import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

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
  MessageChannel({
    this.ping = const Duration(seconds: 60),
    this.idle = const Duration(days: 2),
  });

  /// Time between each ping to a client. If no pong is received
  /// from client within next ping, the connection will be closed
  /// with [WebSocketStatus.goingAway].
  final Duration ping;

  /// Maximum idle time before connection is closed
  final Duration idle;

  /// Named logger used by instances of this class
  final Logger logger = Logger("MessageChannel");

  /// Websocket connections
  final _states = <String, _SocketState>{};

  /// Handled message types
  final _types = <Type>{};

  /// Timer for checking socket states
  Timer _heartbeat;

  /// Will start heartbeat checking all socket connections.
  void build() {
    final period = Duration(
      milliseconds: min(
        ping.inMilliseconds,
        idle.inMilliseconds,
      ),
    );
    _heartbeat ??= Timer.periodic(period, _check);
    _info("Checking liveliness with period ${period.inMilliseconds} ms");
  }

  /// Register message type [T] as managed
  void register<T extends Message>(MessageBus bus) {
    _types.add(typeOf<T>());
    bus.register<T>(this);
  }

  /// Subscribe client with [appId] to receive messages on [socket].
  ///
  /// [MessageChannel] supports heartbeat using opcodes specified in
  /// [RFC6455](https://tools.ietf.org/html/rfc6455).
  ///
  /// If [withHeartbeat] is true, a message with opcode [0x9] (ping)
  /// will be sent, which the client is expected to respond to with a
  /// message with opcode [0xA] (pong) within [MessageChannel.ping].
  ///
  /// If [withHeartbeat] is false, the connection will be closed
  /// automatically after duration given by [MessageChannel.idle].
  ///
  /// Each time the client sends data over the channel an internal
  /// timestamp is updated. This timestamp is used to determine if the
  /// connection is alive or not each liveliness check cycle.
  void subscribe(String appId, WebSocket socket, {bool withHeartbeat = false}) {
    if (socket.readyState != WebSocket.open) {
      throw InvalidOperation("WebSocket is not open, was in ready state ${socket.readyState}");
    }
    // ignore: cancel_subscriptions, is cancelled in _remove(appId)
    final subscription = socket.listen(
      (event) => _onReceived(appId, event),
      onDone: () => _remove(appId),
      onError: (_) => _remove(appId),
      cancelOnError: true,
    );
    final state = _SocketState.init(
      socket,
      subscription,
      withHeartbeat: withHeartbeat,
    );
    _states.update(
      appId,
      (current) {
        if (current.socket.readyState == WebSocket.open) {
          _close(
            current,
            WebSocketStatus.protocolError,
            "Only one connection per application, closing current connection from $appId",
          );
        }
        return state;
      },
      ifAbsent: () => state,
    );
    if (withHeartbeat) {
      socket.pingInterval = ping;
    }
    _info("Websocket connection from $appId established");
  }

  void _remove(String appId) {
    final state = _states.remove(appId);
    if (state != null) {
      state.subscription.cancel();
      if (state.socket.readyState != WebSocket.closed) {
        state.socket.close(WebSocketStatus.abnormalClosure);
      }
      _info("Removed socket for $appId");
    }
  }

  void unsubscribe(String appId) => _close(
        _states[appId],
        WebSocketStatus.normalClosure,
        "Unsubscribe $appId",
      );

  /// Dispose all WebSocket connection
  void dispose() {
    _states.forEach(
      (appId, state) => _close(
        state,
        WebSocketStatus.normalClosure,
        "Closed connection to $appId",
      ),
    );
    _states.clear();
    _heartbeat?.cancel();
  }

  Future _close(_SocketState state, int code, String reason) => state.socket.close(
        code,
        _info(reason),
      );

  @override
  void handle(Message message) {
    if (_types.contains(message.runtimeType)) {
      _states.forEach(
        (appId, state) {
          try {
            final data = _toData(message);
            if (data != null) {
              state.socket.add(data);
              logger.fine("Published $message to client $appId");
              logger.finer(">> $data");
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

  void _onReceived(String appId, event) {
    final state = _states[appId];
    if (state == null) {
      logger.warning("Client $appId not found in states");
    } else {
      _states[appId] = state.alive();
    }
  }

  void _check(Timer timer) {
    try {
      _cleanup();
      final now = DateTime.now();
      final idle = _states.entries
          .where(
            (test) => test.value.evaluate(now, this).isIdle,
          )
          .toList();

      logger.info("Checked liveliness, found ${idle.length} of ${_states.length} idle ");

      idle.forEach(
        (entry) => _close(
          entry.value,
          WebSocketStatus.goingAway,
          "Closed connection to ${entry.key} because idle timeout",
        ),
      );
      _removeAll(idle);
    } catch (e) {
      logger.severe("Failed to check liveliness with: $e");
    }
  }

  void _cleanup() {
    final closed = _states.entries
        .where(
          (test) => test.value.socket.readyState == WebSocket.closed || test.value.socket.closeCode != null,
        )
        .toList();
    if (closed.isNotEmpty) {
      logger.info("Checked ready state, found ${closed.length} of ${_states.length} closed");
      _removeAll(closed);
    }
  }

  void _removeAll(Iterable<MapEntry<String, _SocketState>> entries) => entries.forEach(
        (entry) => _remove(entry.key),
      );

  String _info(String message) {
    logger.info(message);
    return message;
  }
}

enum _Liveliness { alive, idle }

class _SocketState {
  _SocketState({
    @required this.socket,
    @required this.status,
    @required this.lastTime,
    @required this.withHeartbeat,
    @required this.subscription,
  });

  factory _SocketState.init(
    WebSocket socket,
    StreamSubscription subscription, {
    bool withHeartbeat = false,
  }) =>
      _SocketState(
        socket: socket,
        status: _Liveliness.alive,
        lastTime: DateTime.now(),
        withHeartbeat: withHeartbeat,
        subscription: subscription,
      );

  final WebSocket socket;
  final DateTime lastTime;
  final _Liveliness status;
  final bool withHeartbeat;
  final StreamSubscription subscription;

  bool get isAlive => _Liveliness.alive == status;
  bool get isIdle => _Liveliness.idle == status;

  _SocketState evaluate(DateTime timestamp, MessageChannel channel) {
    final delta = timestamp.difference(lastTime);
    if (delta > channel.idle) {
      return idle();
    }
    return this;
  }

  _SocketState alive() => _SocketState(
        socket: socket,
        status: _Liveliness.alive,
        lastTime: DateTime.now(),
        withHeartbeat: withHeartbeat,
        subscription: subscription,
      );

  _SocketState idle() => _SocketState(
        socket: socket,
        status: _Liveliness.idle,
        lastTime: lastTime,
        withHeartbeat: withHeartbeat,
        subscription: subscription,
      );
}
