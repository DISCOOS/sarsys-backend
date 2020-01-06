import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';

import 'domain.dart';
import 'models/AtomFeed.dart';

/// Message interface
abstract class Message {
  const Message();
  @override
  String toString() {
    return '$runtimeType{}';
  }
}

/// Event class
class Event implements Message {
  const Event({
    @required this.uuid,
    @required this.type,
    @required this.data,
    @required this.created,
  });

  /// Create an event with uuid
  factory Event.unique({
    @required String type,
    @required DateTime created,
    @required Map<String, dynamic> data,
  }) =>
      Event(
        uuid: Uuid().v4(),
        type: type,
        data: data,
        created: created,
      );

  final String uuid;
  final String type;
  final DateTime created;
  final Map<String, dynamic> data;

  @override
  String toString() {
    return '$runtimeType{uuid: $uuid, type: $type}';
  }
}

/// Base class for domain events
class DomainEvent extends Event {
  DomainEvent({
    @required String uuid,
    @required String type,
    @required DateTime created,
    @required Map<String, dynamic> data,
  }) : super(
          uuid: uuid,
          type: type,
          data: data,
          created: created ?? DateTime.now(),
        );

  @override
  String toString() {
    return '$runtimeType{uuid: $uuid, type: $type, data: $data}';
  }
}

/// Base class for events sourced from an event stream.
///
/// A [Repository] folds [SourceEvent]s into [DomainEvent]s with [Repository.get].
class SourceEvent extends Event {
  SourceEvent({
    @required String uuid,
    @required String type,
    @required this.number,
    @required DateTime created,
    @required Map<String, dynamic> data,
  }) : super(
          uuid: uuid,
          type: type,
          data: data,
          created: created ?? DateTime.now(),
        );
  final EventNumber number;

  @override
  String toString() {
    return '$runtimeType{uuid: $uuid, type: $type, number: $number, data: $data}';
  }
}

/// Command action types
enum Action {
  create,
  update,
  delete,
  custom,
}

/// Command interface
abstract class Command extends Message {
  Command(
    this.action, {
    String uuid,
    this.uuidFieldName = 'uuid',
    this.data = const {},
  }) : _uuid = uuid;

  /// Command action
  final Action action;

  /// [AggregateRoot.uuid] field name in [data]
  final String uuidFieldName;

  /// Command data
  final Map<String, dynamic> data;

  /// Aggregate uuid
  final String _uuid;

  /// Get [AggregateRoot.uuid] value
  String get uuid => _uuid ?? data[uuidFieldName] as String;

  @override
  String toString() {
    return '$runtimeType{uuid: $uuid, action: $action}';
  }
}

/// Command handler interface
abstract class CommandHandler<T extends Command> {
  FutureOr<Iterable<Event>> execute(T command);
}

/// Message notifier interface
abstract class MessageNotifier {
  void notify(Message message);
}

/// Event publisher interface
abstract class EventPublisher<T extends Event> {
  void publish(T event);
}

/// Command sender interface
abstract class CommandSender {
  void send(Command command);
}

/// Message handler interface
abstract class MessageHandler<T extends Message> {
  void handle(T message);
}

/// Event number in stream
class EventNumber extends Equatable {
  const EventNumber(this.value);

  factory EventNumber.from(ExpectedVersion current) => EventNumber(current.value);

  // First event in stream
  static const first = EventNumber(0);

  // Empty stream
  static const none = EventNumber(-1);

  // Last event in stream
  static const last = EventNumber(-2);

  /// Test if event number is NONE
  bool get isNone => this == none;

  /// Test if first event number in stream
  bool get isFirst => this == first;

  /// Test if last event number in stream
  bool get isLast => this == last;

  /// Event number value
  final int value;

  @override
  List<Object> get props => [value];

  EventNumber operator +(int number) => EventNumber(value + number);
  bool operator >(EventNumber number) => value > number.value;
  bool operator <(EventNumber number) => value < number.value;
  bool operator >=(EventNumber number) => value >= number.value;
  bool operator <=(EventNumber number) => value <= number.value;

  @override
  String toString() {
    return (isLast ? 'HEAD' : value).toString();
  }
}

/// Event traversal direction
enum Direction { forward, backward }

/// When you write to a stream you often want to use
/// [ExpectedVersion] to allow for optimistic concurrency
/// with a stream. You commonly use this for a domain
/// object projection.
class ExpectedVersion {
  const ExpectedVersion(this.value);

  factory ExpectedVersion.from(EventNumber number) => ExpectedVersion(number.value);

  /// Stream should exist but be empty when writing.
  static const empty = ExpectedVersion(0);

  /// Stream should not exist when writing.
  static const none = ExpectedVersion(-1);

  /// Write should not conflict with anything and should always succeed.
  /// This disables the optimistic concurrency check.
  static const any = ExpectedVersion(-2);

  /// Stream should exist, but does not expect the stream to be at a specific event version number.
  static const exists = ExpectedVersion(-4);

  /// The event version number that you expect the stream to currently be at.
  final int value;

  /// Adds [other] to [value] and returns new Expected version
  ExpectedVersion operator +(int other) => ExpectedVersion(value + other);

  @override
  String toString() {
    return 'ExpectedVersion{value: $value}';
  }
}

/// Base class for failures
abstract class Failure {
  const Failure(this.message);
  final String message;

  @override
  String toString() {
    return '$runtimeType{message: $message}';
  }
}

/// Thrown when an invalid operation is attempted
class InvalidOperation extends Failure {
  const InvalidOperation(String message) : super(message);
}

/// Thrown when an required projection is not available
class ProjectionNotAvailable extends InvalidOperation {
  const ProjectionNotAvailable(String message) : super(message);
}

/// Thrown when an uuid is null
class UUIDIsNull extends InvalidOperation {
  const UUIDIsNull(String message) : super(message);
}

/// Thrown when an [Command] is attempted on an [AggregateRoot] not found
class AggregateNotFound extends InvalidOperation {
  const AggregateNotFound(String message) : super(message);
}

/// Thrown when an [Command.action] with [Action.create] is attempted on an existing [AggregateRoot]
class AggregateExists extends InvalidOperation {
  const AggregateExists(String message) : super(message);
}

/// Thrown when writing events and 'ES-ExpectedVersion' differs from 'ES-CurrentVersion'
class WrongExpectedEventVersion extends InvalidOperation {
  const WrongExpectedEventVersion(
    String message, {
    @required this.expected,
    @required this.actual,
  }) : super(message);
  final ExpectedVersion expected;
  final EventNumber actual;

  @override
  String toString() {
    return 'WrongExpectedEventVersion{expected: ${expected.value}actual: ${actual.value}, message: $message}';
  }
}

/// Thrown when an write failed
class WriteFailed extends Failure {
  const WriteFailed(String message) : super(message);
}

/// Thrown when more then one [AggregateRoot] has changes concurrently
class MultipleAggregatesWithChanges extends WriteFailed {
  const MultipleAggregatesWithChanges(String message) : super(message);
}

/// Thrown when an stream [AtomFeed] operation failed
class FeedFailed extends Failure {
  const FeedFailed(String message) : super(message);
}

/// Thrown when an stream [Event] subscription failed
class SubscriptionFailed extends Failure {
  const SubscriptionFailed(String message) : super(message);
}

/// Get enum value name
String enumName(Object o) => o.toString().split('.').last;

/// Type helper class
Type typeOf<T>() => T;

extension TypeX on Type {
  /// Convert [Type] string into colon delimited lower case string
  String toColonCase() {
    return toDelimiterCase(':');
  }

  /// Convert [Type] string into kebab case string
  String toKebabCase() {
    return toDelimiterCase('-');
  }

  /// Convert [Type] string into delimited lower case string
  String toDelimiterCase(String delimiter) {
    return "${this}".split(RegExp('(?<=[a-z0-9])(?=[A-Z0-9])')).join(delimiter).toLowerCase();
  }
}
