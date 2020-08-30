import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:event_source/event_source.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';

import 'package:sarsys_app_server/sarsys_app_server.dart';

class WebSocketMessageProcessor extends MessageHandler<WebSocketMessage> {
  Logger logger = Logger("WebSocketMessageProcessor");
  @override
  void handle(WebSocketMessage message) {
    logger.fine("Received $message");
  }
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

  /// Listen to stream of messages from [socket] connected to client with [appId].
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
      onDone: () => _remove(
        appId,
        reason: socket.closeReason ?? 'done',
      ),
      onError: (Object error, StackTrace stackTrace) => _remove(
        appId,
        reason: error,
        stackTrace: stackTrace,
      ),
    );
    final state = _SocketState.init(
      socket,
      subscription,
      messages: messages,
      withHeartbeat: withHeartbeat,
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

  Future _remove(String appId, {@required Object reason, StackTrace stackTrace}) async {
    try {
      final state = _states.remove(appId);
      if (state != null) {
        await state.subscription.cancel();
        if (state.socket.readyState != WebSocket.closed) {
          await state.socket.close();
        }
        if (stackTrace == null) {
          _info('Removed socket for client $appId, reason: $reason');
        } else {
          _warning(
            'Removed socket for client $appId, reason: $reason',
            error: reason,
            stackTrace: stackTrace,
          );
        }
      }
    } catch (e, stackTrace) {
      _warning(
        'Failed during websocket removal for app $appId',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  void _warning(String message, {Object error, StackTrace stackTrace}) {
    logger.warning(message, error, stackTrace);
  }

  Future close(String appId) async => _close(
        _states[appId],
        WebSocketStatus.normalClosure,
        'Server closed connection to client $appId',
      );

  /// Dispose all WebSocket connection
  Future dispose() async {
    await Future.forEach(
      _states.entries,
      (MapEntry<String, _SocketState> entry) => _close(
        entry.value,
        WebSocketStatus.normalClosure,
        'Server closed connection to ${entry.key}',
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

  void _send(
    String appId,
    _SocketState state,
    Map<String, dynamic> data,
  ) {
    try {
      final message = Map.from(data)
        ..removeWhere(
          (key, _) => const ['changed', 'previous'].contains(key),
        );
      state.socket.add(json.encode(message));
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

  void _check(Timer timer) async {
    try {
      await _cleanup();
      final now = DateTime.now();
      final idle = _states.entries
          .where(
            (test) => test.value.evaluate(now, this).isIdle,
          )
          .toList();

      logger.fine('Checked liveliness, found ${idle.length} of ${_states.length} idle ');

      await Future.forEach<MapEntry<String, _SocketState>>(
        idle,
        (entry) => _close(
          entry.value,
          WebSocketStatus.goingAway,
          'Closed connection to ${entry.key} because idle timeout',
        ),
      );
      await _removeAll(idle, reason: 'Idle too long');
    } catch (e, stacktrace) {
      logger.severe('Failed to check liveliness with: $e with stacktrace: $stacktrace');
    }
  }

  Future _cleanup() async {
    final closed = _states.entries
        .where(
          (test) => test.value.socket.readyState == WebSocket.closed || test.value.socket.closeCode != null,
        )
        .toList();
    if (closed.isNotEmpty) {
      logger.warning('Checked ready state and close code, found ${closed.length} of ${_states.length} closed');
      await _removeAll(closed, reason: 'Client closed connection');
    }
  }

  Future _removeAll(
    Iterable<MapEntry<String, _SocketState>> entries, {
    @required String reason,
  }) =>
      Future.forEach<MapEntry<String, _SocketState>>(
        entries,
        (entry) => _remove(entry.key, reason: reason),
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
          local: false,
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

class WebSocketController extends Controller {
  WebSocketController(
    this.manager,
    this.channel,
  );
  final MessageChannel channel;
  final RepositoryManager manager;

  @override
  FutureOr<RequestOrResponse> handle(Request request) async {
    if (!manager.isReady) {
      return serviceUnavailable(body: "Status Not ready");
    }
    final socket = await WebSocketTransformer.upgrade(request.raw);
    final xAppId = emptyAsNull(request.raw.headers.value('x-app-id'));
    final appId = xAppId ?? Uuid().v4();
    if (xAppId == null) {
      logger.warning("Header 'x-app-id' not set, using $appId");
    }
    final heartbeat = (request.raw.headers.value('x-with-heartbeat') ?? 'false').toLowerCase() == "true";
    final data = await request.body.decode();
    final messages = data is Map<String, dynamic> && data['message'] is List<String>
        ? (data['message'] as List<String>).toSet()
        : const <String>{};
    channel.listen(
      "$appId",
      socket,
      messages: messages,
      withHeartbeat: heartbeat,
    );
    logger.info("Established message channel for app $appId with heartbeat=$heartbeat");
    return null /* Required by Aqueduct, see https://aqueduct.io/docs/snippets/http/ */;
  }
}
