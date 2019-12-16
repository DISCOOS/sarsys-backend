import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:sarsys_app_server/eventstore/eventstore.dart';
import 'package:uuid/uuid.dart';

/// Message interface
abstract class Message {
  const Message();
}

/// Event class
class Event implements Message {
  const Event({
    @required this.uuid,
    @required this.type,
    @required this.data,
  });

  /// Create an event with uuid
  factory Event.unique({
    @required String type,
    @required Map<String, dynamic> data,
  }) =>
      Event(
        uuid: Uuid().v4(),
        type: type,
        data: data,
      );

  final String uuid;
  final String type;
  final Map<String, dynamic> data;
}

/// Command interface
abstract class Command extends Message {}

/// Command handler interface
abstract class CommandHandler {
  WriteResult execute(Command command);
}

/// Message notifier interface
abstract class MessageNotifier {
  void notify(Message message);
}

/// Event publisher interface
abstract class EventPublisher {
  void publish(Event event);
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
  const EventNumber({this.value});

  static const first = EventNumber(value: 0);
  static const last = EventNumber(value: -1);

  bool get isFirst => this == first;
  bool get isLast => this == last;

  final int value;

  @override
  List<Object> get props => [value];

  @override
  String toString() {
    return 'EventNumber{current: $value}';
  }
}

/// Event traversal direction
enum Direction { forward, backward }

/// When you write to a stream you often want to use Expected Version to allow for
/// optimistic concurrency with a stream. You commonly use this for a domain object projection.
class ExpectedVersion {
  const ExpectedVersion(this.number);

  /// Stream should exist but be empty when writing.
  static const int empty = 0;

  /// Stream should not exist when writing.
  static const int none = -1;

  /// Write should not conflict with anything and should always succeed.
  /// This disables the optimistic concurrency check.
  static const int any = -2;

  /// Stream should exist, but does not expect the stream to be at a specific event version number.
  static const int exists = -4;

  /// The event version number that you expect the stream to currently be at.
  final int number;
}

/// Base class for failures
abstract class Failure {
  const Failure(this.message);
  final String message;

  @override
  String toString() {
    return 'Failure{message: $message}';
  }
}

/// Thrown when an invalid operation is attempted
class InvalidOperation extends Failure {
  const InvalidOperation(String message) : super(message);
}

/// Thrown when an push to remote event store failed
class PushFailed extends Failure {
  const PushFailed(String message) : super(message);
}

/// Type helper class
Type typeOf<T>() => T;

extension TypeX on Type {
  /// Convert [Type] string into kebab-case
  String toKebabCase() {
    return "${this}".split(RegExp('(?<=[a-z0-9])(?=[A-Z0-9])')).join('-').toLowerCase();
  }
}
