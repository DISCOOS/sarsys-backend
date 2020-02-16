import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:event_source/event_source.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';

import 'core.dart';

/// Message bus implementation
class MessageBus implements MessageNotifier, CommandSender, EventPublisher {
  /// Registered message routes from Type to to handlers
  final Map<Type, List<MessageHandler>> _routes = {};

  /// Check if messages are being replayed
  bool get replaying => _replaying.values.where((count) => count > 0).isNotEmpty;

  /// Check if messages are being replayed
  bool isReplaying<T extends AggregateRoot>(T aggregateRoot) => (_replaying[aggregateRoot.runtimeType] ?? 0) > 0;

  /// Replay counter incremented by [ReplayStarted] and decremented by [ReplayEnded]
  final Map<Type, int> _replaying = {};

  /// Register message handler
  void register<T extends Message>(MessageHandler handler) => _routes.update(
        typeOf<T>(),
        (handlers) => handlers..add(handler),
        ifAbsent: () => [handler],
      );

  /// Invoked before first event is replayed
  ///
  /// Throws [InvalidOperation] on illegal [replaying] state.
  void replayStarted<T extends AggregateRoot>() => notify(ReplayStarted<T>());

  /// Invoked after last event is replayed
  ///
  /// Throws [InvalidOperation] on illegal [replaying] state.
  void replayEnded<T extends AggregateRoot>() => notify(ReplayEnded<T>());

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
      _replaying.update(
        message.aggregateType,
        (count) => ++count,
        ifAbsent: () => 1,
      );
    } else if (message is ReplayEnded) {
      if (!_replaying.containsKey(message.aggregateType) || _replaying[message.aggregateType] == 0) {
        throw const InvalidOperation('Illegal state. Is not replaying events');
      }
      _replaying.update(
        message.aggregateType,
        (count) => --count,
        ifAbsent: () => 0,
      );
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
      throw InvalidOperation('No handler found for $message');
    } else if (handlers.length > 1) {
      throw InvalidOperation('More than one handler found for $message: $handlers');
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
class ReplayStarted<T extends AggregateRoot> extends Message {
  Type get aggregateType => typeOf<T>();
}

/// Message indication replay has ended.
///
/// Message handlers can resume sending commands after replay has ended.
@sealed
class ReplayEnded<T extends AggregateRoot> extends Message {
  Type get aggregateType => typeOf<T>();
}

/// Manages messages over WebSocket connections
class MessageChannel extends MessageHandler<Event> {
  MessageChannel({
    this.ping = const Duration(seconds: 60),
    this.idle = const Duration(days: 2),
    MessageHandler<WebSocketMessage> handler,
  }) : _handler = handler;

  /// Time between each ping to a client. If no pong is received
  /// from client within next ping, the connection will be closed
  /// with [WebSocketStatus.goingAway].
  final Duration ping;

  /// Maximum idle time before connection is closed
  final Duration idle;

  /// Named logger used by instances of this class
  final Logger logger = Logger('MessageChannel');

  /// Websocket connections
  final _states = <String, _SocketState>{};

  /// Handled message types
  final _types = <Type>{};

  /// Event handler invoked on with messages from clients
  final MessageHandler<WebSocketMessage> _handler;

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
    _info('Checking liveliness with period ${period.inMilliseconds} ms');
  }

  /// Register message type [T] as managed
  void register<T extends Message>(MessageBus bus) {
    _types.add(typeOf<T>());
    bus.register<T>(this);
  }

  /// Listen to stream of from messages from [socket] connected to client with [appId].
  ///
  /// [MessageChannel] supports heartbeat using opcodes specified in
  /// [RFC6455](https://tools.ietf.org/html/rfc6455).
  ///
  /// If [messages] is empty, client will receive all messages.
  ///
  /// If [messages] is not empty, client will only receive messages of given types.
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
  void listen(
    String appId,
    WebSocket socket, {
    Set<String> messages = const {},
    bool withHeartbeat = false,
  }) {
    if (socket.readyState != WebSocket.open) {
      throw InvalidOperation('WebSocket is not open, was in ready state ${socket.readyState}');
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
      messages: messages,
    );
    _states.update(
      appId,
      (current) {
        if (current.socket.readyState == WebSocket.open) {
          _close(
            current,
            WebSocketStatus.protocolError,
            'Only one connection per application, closing current connection from $appId',
          );
        }
        return state;
      },
      ifAbsent: () => state,
    );
    if (withHeartbeat) {
      socket.pingInterval = ping;
    }
    _info(
      'Websocket connection from client $appId established: Subscribes to '
      "${messages.isEmpty ? 'all messages' : "messages: {${messages.join(',')}}"}",
    );
  }

  void _remove(String appId) {
    final state = _states.remove(appId);
    if (state != null) {
      state.subscription.cancel();
      if (state.socket.readyState != WebSocket.closed) {
        state.socket.close(WebSocketStatus.abnormalClosure);
      }
      _info('Removed socket for client $appId');
    }
  }

  void close(String appId) => _close(
        _states[appId],
        WebSocketStatus.normalClosure,
        'Server closed connection to client $appId',
      );

  /// Dispose all WebSocket connection
  void dispose() {
    _states.forEach(
      (appId, state) => _close(
        state,
        WebSocketStatus.normalClosure,
        'Server closed connection to $appId',
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
      final data = _toData(message);
      _states.forEach(
        (appId, state) {
          if (state.messages.isEmpty || state.messages.contains(data['type'])) {
            _send(appId, state, data);
          }
        },
      );
    }
  }

  void _send(String appId, _SocketState state, Map<String, dynamic> data) {
    try {
      state.socket.add(json.encode(data));
      final type = data['type'];
      if (type != 'Error') {
        logger.fine("Sent ${data['type']} to client $appId");
        logger.finer('>> $data');
      } else {
        logger.warning("Sent ${data['type']} to client $appId >> $data");
      }
    } catch (e, stacktrace) {
      logger.warning("Failed to send message ${data['type']} to client $appId: $e with stacktrace: $stacktrace");
    }
  }

  Map<String, dynamic> _toData(Message message) {
    if (message is Event) {
      return {'uuid': message.uuid, 'type': message.type, 'data': message.data};
    } else {
      return {'type': '${message.runtimeType}'};
    }
  }

  void _onReceived(String appId, event) {
    final state = _states[appId];
    if (state == null) {
      logger.warning('Client $appId not found in states');
    } else {
      _states[appId] = state.alive();
      final message = _toMessage(appId, event);
      if (message is WebSocketError) {
        _send(appId, state, _toData(message));
      } else {
        _handler?.handle(message);
      }
    }
  }

  WebSocketMessage _toMessage(String appId, event) {
    WebSocketMessage message;
    try {
      if (event is String) {
        final data = json.decode(event);
        if (_isWebSocketMessage(data)) {
          message = WebSocketMessage(
            appId: appId,
            uuid: data['uuid'] as String,
            type: data['type'] as String,
            data: data['data'] as Map<String, dynamic>,
          );
        }
      }
      message ??= WebSocketError(
        appId: appId,
        uuid: Uuid().v4(),
        code: WebSocketError.invalidFormat,
        reason: 'Invalid WebSocketMessage: $event',
      );
    } on FormatException catch (e, stacktrace) {
      message = WebSocketError(
        appId: appId,
        uuid: Uuid().v4(),
        code: WebSocketError.invalidFormat,
        reason: 'Invalid json format in $event: $e with stacktrace: $e with stacktrace: $stacktrace',
      );
    }
    return message;
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

      logger.fine('Checked liveliness, found ${idle.length} of ${_states.length} idle ');

      idle.forEach(
        (entry) => _close(
          entry.value,
          WebSocketStatus.goingAway,
          'Closed connection to ${entry.key} because idle timeout',
        ),
      );
      _removeAll(idle);
    } catch (e, stacktrace) {
      logger.severe('Failed to check liveliness with: $e with stacktrace: $stacktrace');
    }
  }

  void _cleanup() {
    final closed = _states.entries
        .where(
          (test) => test.value.socket.readyState == WebSocket.closed || test.value.socket.closeCode != null,
        )
        .toList();
    if (closed.isNotEmpty) {
      logger.warning('Checked ready state and close code, found ${closed.length} of ${_states.length} closed');
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

  bool _isWebSocketMessage(event) {
    if (event is Map<String, dynamic>) {
      final required = event['uuid'] is String && event['type'] is String;
      final optional = event['data'] == null || event['data'] is Map<String, dynamic>;
      return required && optional;
    }
    return false;
  }
}

class WebSocketMessage extends Event {
  WebSocketMessage({
    @required this.appId,
    @required String uuid,
    @required String type,
    @required Map<String, dynamic> data,
  }) : super(
          uuid: uuid,
          type: type,
          data: data,
          created: DateTime.now(),
        );
  final String appId;

  @override
  String toString() {
    return 'WebSocketMessage{appId: $appId, uuid: $uuid, type: $type, data: $data}';
  }
}

class WebSocketError extends WebSocketMessage {
  WebSocketError({
    @required String appId,
    @required String uuid,
    @required int code,
    @required String reason,
  }) : super(
          appId: appId,
          uuid: uuid,
          type: 'Error',
          data: {
            'code': code,
            'reason': reason,
          },
        );

  static const invalidFormat = 4001;

  @override
  String toString() {
    return 'WebSocketError{uuid: $uuid, type: $type, data: $data}';
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
    this.messages = const {},
  });

  factory _SocketState.init(
    WebSocket socket,
    StreamSubscription subscription, {
    bool withHeartbeat = false,
    Set<String> messages = const {},
  }) =>
      _SocketState(
        socket: socket,
        status: _Liveliness.alive,
        lastTime: DateTime.now(),
        withHeartbeat: withHeartbeat,
        subscription: subscription,
        messages: messages,
      );

  final WebSocket socket;
  final DateTime lastTime;
  final _Liveliness status;
  final bool withHeartbeat;
  final Set<String> messages;
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

  _SocketState subscribe(Set<String> messages) => _SocketState(
        socket: socket,
        status: _Liveliness.alive,
        lastTime: DateTime.now(),
        withHeartbeat: withHeartbeat,
        subscription: subscription,
        messages: messages ?? const {},
      );

  _SocketState alive() => _SocketState(
        socket: socket,
        status: _Liveliness.alive,
        lastTime: DateTime.now(),
        withHeartbeat: withHeartbeat,
        subscription: subscription,
        messages: messages,
      );

  _SocketState idle() => _SocketState(
        socket: socket,
        status: _Liveliness.idle,
        lastTime: lastTime,
        withHeartbeat: withHeartbeat,
        subscription: subscription,
        messages: messages,
      );
}
