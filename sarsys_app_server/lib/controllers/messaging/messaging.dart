import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';
import 'package:stack_trace/stack_trace.dart';

import 'package:event_source/event_source.dart';
import 'package:sarsys_app_server/controllers/messaging/models/subscription_event_model.dart';

import 'package:sarsys_app_server/sarsys_app_server.dart';

import 'messages.dart';
import 'models/subscription_model.dart';
import 'models/subscription_type_model.dart';

class WebSocketMessageHandler {
  Logger logger = Logger("WebSocketMessageHandler");

  WebSocketMessage handle(WebSocketState state, WebSocketMessage message) {
    logger.fine("Received $message");
    return null;
  }
}

/// Manages messages over WebSocket connections
class MessageChannel extends MessageHandler<Event> {
  MessageChannel({
    this.ping = const Duration(seconds: 60),
    this.idle = const Duration(days: 2),
    WebSocketMessageHandler handler,
  }) : _handler = handler;

  /// Time between each ping to a client. If no pong is received
  /// from client within next ping, the connection will be closed
  /// with [WebSocketStatus.goingAway].
  final Duration ping;

  /// Maximum idle time before connection is closed
  final Duration idle;

  /// Named logger used by instances of this class
  final Logger logger = Logger('MessageChannel');

  /// Manager for aggregate state lookup
  RepositoryManager _manager;

  /// Websocket connections
  final _states = <String, WebSocketState>{};

  /// Handled message types
  final _types = <Type>{};

  /// Event handler invoked on with messages from clients
  final WebSocketMessageHandler _handler;

  /// Timer for checking socket states
  Timer _heartbeat;

  /// Timer for periodically check if cached messages are overdue
  Timer _sender;

  /// Will start heartbeat checking all socket connections.
  void build(RepositoryManager manager) {
    _manager = manager;
    final period = Duration(
      milliseconds: min(
        ping.inMilliseconds,
        idle.inMilliseconds,
      ),
    );
    _heartbeat ??= Timer.periodic(
      period,
      _checkStatus,
    );
    _sender ??= Timer.periodic(
      const Duration(milliseconds: 1),
      _checkOverdue,
    );
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
  /// If [types] is empty, client will receive all messages.
  ///
  /// If [types] is not empty, client will only receive messages of given types.
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
    OAuth2Token token,
    bool withHeartbeat = false,
    Authorization authorization,
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
    final state = WebSocketState.init(
      appId,
      socket,
      subscription,
      token: token,
      authorization: authorization,
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
      'Websocket connection from client $appId established',
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
    for (var entry in List<MapEntry<String, WebSocketState>>.from(_states.entries)) {
      await _close(
        entry.value,
        WebSocketStatus.normalClosure,
        'Server closed connection to ${entry.key}',
      );
    }
    _states.clear();
    _sender?.cancel();
    _heartbeat?.cancel();
  }

  Future _close(WebSocketState state, int code, String reason) => state.socket.close(
        code,
        _info(reason),
      );

  @override
  void handle(Object source, Message message) {
    // Only process remote events
    if (message.remote && _types.contains(message.runtimeType)) {
      Map<String, WebSocketState>.from(_states).forEach(
        (appId, state) {
          final type = _findSubscriptionType(source, message, state);
          if (type != null) {
            final handled = <String, dynamic>{};
            final eventType = message.type.toLowerCase();
            final event = type.events.firstWhere((e) => e.name.toLowerCase() == eventType, orElse: () => null);

            if (event != null || type.events.isEmpty) {
              // Create response and apply to state
              handled['type'] = type.name;
              final json = _toData(message);
              final data = json['data'] as Map<String, dynamic>;
              final uuid = data['uuid'] as String;
              final repo = _manager?.getFromTypeName(type.name);
              data['changed'] = repo?.peek(data['uuid'] as String)?.data;

              final process = istTypeMatch(type, uuid, data['changed'] as Map<String, dynamic>);

              if (process) {
                if (!(type.statePatches == true || event?.statePatches == true)) {
                  data.remove('patches');
                }

                if (!(type.changedState == true || event?.changedState == true)) {
                  data.remove('changed');
                }

                if (!(type.previousState == true || event?.previousState == true)) {
                  data.remove('previous');
                }

                handled['event'] = json;
                final overdue = <Map<String, dynamic>>[];
                _states[appId] = state.apply(handled, overdue);

                if (overdue.isNotEmpty) {
                  _send(
                    appId,
                    state: state,
                    data: _toEntries(
                      appId,
                      overdue,
                    ),
                  );
                }
              }
            }
          }
        },
      );
    }
  }

  bool istTypeMatch(SubscriptionTypeModel type, String uuid, Map<String, dynamic> data) {
    if (data != null && type.filters.isNotEmpty) {
      switch (type.match) {
        case FilterMatch.any:
          return type.filters.any((f) => QueryUtils.isMatch(
                f.pattern,
                data,
              ));
        case FilterMatch.all:
          return type.filters.every((f) => QueryUtils.isMatch(
                f.pattern,
                data,
              ));
      }
    }
    return type.filters.isEmpty;
  }

  SubscriptionTypeModel _findSubscriptionType(Object source, Message message, WebSocketState state) {
    if (message is Event && source is EventStore) {
      final stateType = source.aggregate.toLowerCase();
      return state.config.types.firstWhere((type) => type.name.toLowerCase() == stateType, orElse: () => null);
    }
    final eventType = message.type.toLowerCase();
    return state.config.types
        .firstWhere((type) => type.events.any((e) => e.name.toLowerCase() == eventType), orElse: () => null);
  }

  void _checkOverdue(Timer timer) async {
    try {
      Map<String, WebSocketState>.from(_states).forEach((appId, state) {
        final overdue = <Map<String, dynamic>>[];
        _states[appId] = state.consume(overdue);
        if (overdue.isNotEmpty) {
          _send(
            appId,
            state: state,
            data: _toEntries(
              appId,
              overdue,
            ),
          );
        }
      });
    } catch (error, stackTrace) {
      logger.severe(
        'Failed to check overdue messages: $error with stacktrace: $stackTrace',
        error,
        Trace.from(stackTrace),
      );
    }
  }

  Map<String, dynamic> _toEntries(String appId, List<Map<String, dynamic>> overdue) => {
        'type': 'Changes',
        'entries': overdue,
        'uuid': Uuid().v4(),
        'count': overdue.length,
        'number': EventNumber.none.value,
        'pending': _states[appId].messages.length,
        'created': DateTime.now().toIso8601String(),
      };

  void _send(
    String appId, {
    @required WebSocketState state,
    @required Map<String, dynamic> data,
  }) {
    try {
      // Cache or send
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
      return {
        'uuid': message.uuid,
        'type': message.type,
        'data': message.data,
        'number': message.number.value,
        'created': message.created.toIso8601String(),
      };
    }
    return {
      'uuid': message.uuid,
      'type': message.type,
      'data': message.data,
      'created': message.created.toIso8601String(),
    };
  }

  void _onReceived(String appId, event) {
    WebSocketMessage response;
    final state = _states[appId];
    if (state == null) {
      logger.warning('Client $appId not found in states');
    } else {
      final message = _toMessage(appId, event);
      switch (message.runtimeType) {
        case WebSocketErrorMessage:
          response = _onError(
            appId,
            state,
            message,
          );
          break;
        case WebSocketSubscribeMessage:
          response = _onSubscribe(
            appId,
            state,
            message as WebSocketSubscribeMessage,
          );
          break;
        default:
          response = _onHandle(
            appId,
            state,
            message,
          );
          break;
      }
    }
    if (response != null) {
      _send(
        appId,
        state: state,
        data: _toData(response),
      );
    }
  }

  WebSocketMessage _onHandle(String appId, WebSocketState state, WebSocketMessage message) {
    _states[appId] = state.alive();
    return _handler?.handle(
      _states[appId],
      message,
    );
  }

  WebSocketMessage _onSubscribe(String appId, WebSocketState state, WebSocketSubscribeMessage message) {
    try {
      final config = message.config;
      final events = _types.map((type) => type.toString()).toList();
      final eventsNotFound = <SubscriptionEventModel>[];
      config.types.fold<List<SubscriptionEventModel>>(
        eventsNotFound,
        (previous, type) => previous..addAll(type.events.where((e) => !events.contains(e.name))),
      );

      if (eventsNotFound.isNotEmpty) {
        return WebSocketErrorMessage(
          appId: appId,
          uuid: message.uuid,
          code: HttpStatus.notFound,
          reason: 'Unsupported event types',
          data: {
            'events': eventsNotFound.map((e) => e.toJson()).toList(),
          },
        );
      }

      _states[appId] = state.subscribe(config);
      return WebSocketStatusMessage(
        uuid: message.uuid,
        appId: appId,
        data: message.config.toJson(),
      );
    } catch (e) {
      return WebSocketErrorMessage(
        appId: appId,
        reason: '$e',
        uuid: message.uuid,
        code: HttpStatus.internalServerError,
      );
    }
  }

  WebSocketMessage _onError(
    String appId,
    WebSocketState state,
    WebSocketMessage message,
  ) {
    _states[appId] = state.alive();
    return message;
  }

  WebSocketMessage _toMessage(String appId, event) {
    try {
      if (event is String) {
        final data = json.decode(event);
        if (_isWebSocketMessage(data)) {
          switch (data['type'].toString().toLowerCase()) {
            case 'subscribe':
              return WebSocketSubscribeMessage(
                appId: appId,
                uuid: data['uuid'] as String,
                data: data['data'] as Map<String, dynamic>,
              );
            default:
              return WebSocketMessage(
                appId: appId,
                uuid: data['uuid'] as String,
                type: data['type'] as String,
                data: data['data'] as Map<String, dynamic>,
              );
          }
        }
      }
      return WebSocketErrorMessage(
        appId: appId,
        uuid: Uuid().v4(),
        code: WebSocketErrorMessage.invalidFormat,
        reason: 'Invalid WebSocketMessage: $event',
      );
    } on FormatException catch (e, stacktrace) {
      return WebSocketErrorMessage(
        appId: appId,
        uuid: Uuid().v4(),
        code: WebSocketErrorMessage.invalidFormat,
        reason: 'Invalid json format in $event: $e with stacktrace: $e with stacktrace: $stacktrace',
      );
    }
  }

  void _checkStatus(Timer timer) async {
    try {
      await _cleanup();
      final now = DateTime.now();
      final apps = _states.values.where((test) => !test.evaluate(now, this).isAlive).toList();
      await _closeAll(apps.where((app) => app.isIdle), 'idle');
      await _closeAll(apps.where((app) => app.isExpired), 'token');
    } catch (error, stackTrace) {
      logger.severe(
        'Failed to check liveliness: $error with stacktrace: $stackTrace',
        error,
        Trace.from(stackTrace),
      );
    }
  }

  Future _closeAll(
    Iterable<WebSocketState> apps,
    String reason,
  ) async {
    logger.fine('Checked liveliness, found ${apps.length} of ${_states.length} $reason');
    for (var app in apps) {
      await _close(
        app,
        WebSocketStatus.goingAway,
        'Closed connection to ${app.appId} because $reason timeout',
      );
    }
    return _removeAll(apps, reason: '$reason too long');
  }

  Future _cleanup() async {
    final closed = _states.values
        .where(
          (test) => test.socket.readyState == WebSocket.closed || test.socket.closeCode != null,
        )
        .toList();
    if (closed.isNotEmpty) {
      logger.warning('Checked ready state and close code, found ${closed.length} of ${_states.length} closed');
      await _removeAll(closed, reason: 'Client closed connection');
    }
  }

  Future _removeAll(
    Iterable<WebSocketState> apps, {
    @required String reason,
  }) async {
    for (var app in apps) {
      await _remove(app.appId, reason: reason);
    }
    return Future.value();
  }

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

enum _Liveliness { alive, idle }

@immutable
class WebSocketState {
  const WebSocketState({
    @required this.appId,
    @required this.socket,
    @required this.status,
    @required this.lastTime,
    @required this.lastPush,
    @required this.subscription,
    @required this.withHeartbeat,
    this.token,
    this.authorization,
    this.messages = const [],
    this.config = SubscriptionModel.defaultModel,
  });

  factory WebSocketState.init(
    String appId,
    WebSocket socket,
    StreamSubscription subscription, {
    OAuth2Token token,
    bool withHeartbeat = false,
    Authorization authorization,
    SubscriptionModel config = SubscriptionModel.defaultModel,
  }) =>
      WebSocketState(
        appId: appId,
        token: token,
        socket: socket,
        config: config,
        lastTime: DateTime.now(),
        authorization: authorization,
        lastPush: DateTime.fromMicrosecondsSinceEpoch(0),
        status: _Liveliness.alive,
        subscription: subscription,
        withHeartbeat: withHeartbeat,
      );

  final String appId;
  final WebSocket socket;
  final DateTime lastTime;
  final DateTime lastPush;
  final OAuth2Token token;
  final _Liveliness status;
  final bool withHeartbeat;
  final SubscriptionModel config;
  final Authorization authorization;
  final StreamSubscription subscription;
  final List<Map<String, dynamic>> messages;

  bool get isAlive => _Liveliness.alive == status;
  bool get isIdle => _Liveliness.idle == status;
  bool get isExpired => token?.isExpired == true;

  WebSocketState evaluate(DateTime timestamp, MessageChannel channel) {
    final delta = timestamp.difference(lastTime);
    final isIdle = delta > channel.idle;
    if (isExpired) {
      return expired(
        isIdle: isIdle,
      );
    }
    if (isIdle) {
      return idle();
    }
    return this;
  }

  WebSocketState subscribe(SubscriptionModel config) => WebSocketState(
        appId: appId,
        token: token,
        socket: socket,
        messages: messages,
        lastPush: lastPush,
        lastTime: DateTime.now(),
        status: _Liveliness.alive,
        subscription: subscription,
        withHeartbeat: withHeartbeat,
        authorization: authorization,
        config: config ?? SubscriptionModel.defaultModel,
      );

  WebSocketState alive() => WebSocketState(
        appId: appId,
        token: token,
        config: config,
        socket: socket,
        messages: messages,
        lastPush: lastPush,
        lastTime: DateTime.now(),
        status: _Liveliness.alive,
        subscription: subscription,
        withHeartbeat: withHeartbeat,
        authorization: authorization,
      );

  WebSocketState idle() => WebSocketState(
        appId: appId,
        token: token,
        config: config,
        socket: socket,
        lastTime: lastTime,
        lastPush: lastPush,
        messages: messages,
        status: _Liveliness.idle,
        subscription: subscription,
        withHeartbeat: withHeartbeat,
        authorization: authorization,
      );

  WebSocketState expired({bool isIdle}) => WebSocketState(
        appId: appId,
        token: token,
        config: config,
        socket: socket,
        lastTime: lastTime,
        lastPush: lastPush,
        messages: messages,
        subscription: subscription,
        withHeartbeat: withHeartbeat,
        authorization: authorization,
        status: isIdle == null ? status : (isIdle ? _Liveliness.idle : _Liveliness.alive),
      );

  WebSocketState apply(Map<String, dynamic> message, List<Map<String, dynamic>> out) {
    final _config = config;
    final messages = List<Map<String, dynamic>>.from(this.messages)..add(message);
    if (_isOverdue(_config, messages.isEmpty)) {
      final length = min(messages.length, _config.maxCount);
      out.addAll(messages.sublist(0, length));
      return WebSocketState(
        appId: appId,
        token: token,
        config: config,
        socket: socket,
        lastPush: lastPush,
        lastTime: DateTime.now(),
        status: _Liveliness.alive,
        subscription: subscription,
        withHeartbeat: withHeartbeat,
        authorization: authorization,
        messages: messages..removeRange(0, length),
      );
    }
    return WebSocketState(
      appId: appId,
      token: token,
      config: config,
      socket: socket,
      lastPush: lastPush,
      lastTime: lastTime,
      messages: messages,
      status: _Liveliness.alive,
      subscription: subscription,
      withHeartbeat: withHeartbeat,
      authorization: authorization,
    );
  }

  WebSocketState consume(List<Map<String, dynamic>> out) {
    final _config = config;
    if (_isOverdue(_config, messages.isEmpty)) {
      final length = min(messages.length, _config.maxCount);
      out.addAll(messages.sublist(0, length));
      return WebSocketState(
        appId: appId,
        token: token,
        config: config,
        socket: socket,
        lastPush: lastPush,
        lastTime: DateTime.now(),
        status: _Liveliness.alive,
        subscription: subscription,
        withHeartbeat: withHeartbeat,
        authorization: authorization,
        messages: List<Map<String, dynamic>>.from(messages)..removeRange(0, length),
      );
    }
    return this;
  }

  bool _isOverdue(SubscriptionModel _config, bool isEmpty) =>
      !isEmpty && (DateTime.now().difference(lastPush) > _config.minPeriod || messages.length > _config.maxCount);
}

class WebSocketController extends Controller {
  WebSocketController(
    this.manager,
    this.channel,
    this.validator,
  );
  final MessageChannel channel;
  final RepositoryManager manager;
  final AccessTokenValidator validator;

  @override
  final Logger logger = Logger('WebSocketController');

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
    final token = await getToken(appId, request);
    if (token == null && validator?.config?.enabled == true) {
      return Response.unauthorized();
    }
    channel.listen(
      appId,
      socket,
      token: token,
      withHeartbeat: heartbeat,
      authorization: request.authorization,
    );
    logger.info("Established message channel for app $appId with heartbeat=$heartbeat");
    return null /* Required by Aqueduct, see https://aqueduct.io/docs/snippets/http/ */;
  }

  Future<OAuth2Token> getToken(String appId, Request request) async {
    final parts = request.raw.headers.value('Authorization')?.split(' ');
    final token = parts?.last;
    try {
      return validator != null ? await validator.parseToken(token) : null;
    } on Exception catch (e) {
      logger.warning("Failed to parse token $token for app $appId >> error $e");
    }
    return null;
  }
}
