import 'package:event_source/event_source.dart';
import 'package:meta/meta.dart';

import 'core.dart';

/// Message bus implementation
class MessageBus implements MessageNotifier, CommandSender, EventPublisher {
  /// Registered message routes from Type to to handlers
  final Map<Type, List<MessageHandler>> _routes = {};

  /// Check if messages are being replayed
  bool get isReplaying => _replaying.values.where((count) => count > 0).isNotEmpty;

  /// Check if replaying given [AggregateRoot] of type [T]
  bool isReplayingType<T extends AggregateRoot>() => _replaying[typeOf<T>()] > 0;

  /// Replay counter incremented by [ReplayStarted] and decremented by [ReplayEnded]
  final Map<Type, int> _replaying = {};

  /// Register message handler with generic type
  void register<T extends Message>(MessageHandler handler) => _routes.update(
        typeOf<T>(),
        (handlers) => handlers..add(handler),
        ifAbsent: () => [handler],
      );

  /// Register message handler with [type]
  void registerType(Type type, MessageHandler handler) => _routes.update(
        type,
        (handlers) => handlers..add(handler),
        ifAbsent: () => [handler],
      );

  /// Invoked before first event is replayed
  ///
  /// Throws [InvalidOperation] on illegal [isReplaying] state.
  void replayStarted<T extends AggregateRoot>() => notify(this, ReplayStarted<T>());

  /// Invoked after last event is replayed
  ///
  /// Throws [InvalidOperation] on illegal [isReplaying] state.
  void replayEnded<T extends AggregateRoot>() => notify(this, ReplayEnded<T>());

  @override
  void notify(Object source, Message message) {
    if (message is Event) {
      publish(source, message);
    } else if (message is Command) {
      send(source, message);
    } else {
      // message is not an event or command, thus inspection of message is only needed here.
      toHandlers(_inspect(message)).forEach(
        (handler) => handler.handle(source, message),
      );
    }
  }

  @override
  void publish(Object source, Event event) => toHandlers(event).forEach(
        (handler) => handler.handle(source, event),
      );

  @override
  void send(Object source, Command command) {
    // Do not send any commands during replay! This will lead to unexpected results.
    // Replay should only reproduce state, no side effects should occur during replay.
    if (isReplaying == false) {
      toHandler(command).handle(source, command);
    }
  }

  /// Inspect message for [ReplayStarted] and [ReplayEnded] integration events
  ///
  /// Throws [InvalidOperation] on illegal [isReplaying] state.
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
