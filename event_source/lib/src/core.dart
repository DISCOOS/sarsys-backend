import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';

import 'domain.dart';
import 'models/AtomFeed.dart';

/// Message interface
class Message {
  const Message({
    @required this.uuid,
    this.created,
    String type,
    this.data,
  }) : _type = type;

  /// Massage
  final String uuid;

  /// Message creation time
  ///
  /// *NOTE*: Not stable until read from remote stream
  final DateTime created;

  /// Message data
  final Map<String, dynamic> data;

  /// Message type
  String get type => _type ?? '$runtimeType';
  final String _type;

  @override
  String toString() {
    return '$runtimeType{uuid: $uuid, type: $type}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Message && runtimeType == other.runtimeType && uuid == other.uuid;
  /* &&
          // DO NOT COMPARE - equality is guaranteed by type and uuid
          // data == other.data &&
          // _type == other._type &&
          // DO NOT COMPARE - is not stable until read from remote stream
          // created == other.created;
   */

  @override
  int get hashCode => uuid.hashCode; /* ^ data.hashCode ^ _type.hashCode ^ created.hashCode; */
}

/// Event class
class Event extends Message {
  const Event({
    @required String uuid,
    @required String type,
    @required DateTime created,
    @required Map<String, dynamic> data,
  }) : super(
          uuid: uuid,
          type: type,
          data: data,
          created: created,
        );

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

  /// Get element at given path in [changed]. If not found, [previous] is used instead
  Map<String, dynamic> elementAt(String path) => changed.elementAt(path) ?? previous.elementAt(path);

  /// Test if all data is deleted by evaluating if `data['deleted'] == 'true'`
  bool get isDeleted => data['deleted'] == true;

  /// Get changed fields from `data['changed']`
  Map<String, dynamic> get changed => Map<String, dynamic>.from(data['changed']);

  /// Get changed fields from `data['previous']`
  Map<String, dynamic> get previous => Map<String, dynamic>.from(data['previous'] ?? {});

  /// Get list of JSON Patch methods from `data['patches']`
  List<Map<String, dynamic>> get patches => List<Map<String, dynamic>>.from(data['patches'] as List<dynamic>);

  @override
  String toString() {
    return '$runtimeType{uuid: $uuid, type: $type, created: $created}';
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
    return '$runtimeType{uuid: $uuid, type: $type, created: $created, data: $data}';
  }
}

class EntityObjectEvent extends DomainEvent {
  EntityObjectEvent({
    @required String uuid,
    @required String type,
    @required DateTime created,
    @required this.aggregateField,
    @required Map<String, dynamic> data,
    int index,
    this.idFieldName = 'id',
  }) : super(
          uuid: uuid,
          type: type,
          created: created,
          data: {'index': index}..addAll(data),
        );

  final String idFieldName;
  final String aggregateField;

  int get index => data['index'];
  String get id => entity.elementAt('id');
  Map<String, dynamic> get entity => elementAt('$aggregateField/$index');
  EntityObject get entityObject => EntityObject(id, entity, idFieldName);
}

class ValueObjectEvent<T> extends DomainEvent {
  ValueObjectEvent({
    @required String uuid,
    @required String type,
    @required DateTime created,
    @required this.valueField,
    @required Map<String, dynamic> data,
  }) : super(
          uuid: uuid,
          type: type,
          created: created,
          data: data,
        );

  final String valueField;

  T get value => elementAt('$valueField') as T;
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
}

/// Command interface
abstract class Command<T extends DomainEvent> extends Message {
  Command(
    this.action, {
    String uuid,
    this.uuidFieldName = 'uuid',
    Map<String, dynamic> data = const {},
  })  : _uuid = uuid,
        super(uuid: uuid, data: data);

  /// Command action
  final Action action;

  /// Aggregate uuid
  final String _uuid;

  /// Get [AggregateRoot.uuid] value
  @override
  String get uuid => _uuid ?? data[uuidFieldName] as String;

  /// [AggregateRoot.uuid] field name in [data]
  final String uuidFieldName;

  /// Get [DomainEvent] type emitted after command is executed
  Type get emits => typeOf<T>();

  /// Add value to list in given field
  static Map<String, dynamic> addToList<T>(Map<String, dynamic> data, String field, T value) => Map.from(data)
    ..update(
      field,
      (operations) => List<T>.from(operations as List)..add(value),
      ifAbsent: () => [value],
    );

  /// Remove value from list in given field
  static Map<String, dynamic> removeFromList<T>(Map<String, dynamic> data, String field, T value) => Map.from(data)
    ..update(
      field,
      (operations) => List<T>.from(operations as List)..remove(value),
    );

  @override
  String toString() {
    return '$runtimeType{uuid: $uuid, action: $action}';
  }
}

/// Command interface
abstract class EntityCommand<T extends DomainEvent> extends Command<T> {
  EntityCommand(
    Action action,
    this.aggregateField, {
    String uuid,
    String entityId,
    String uuidFieldName = 'uuid',
    this.entityIdFieldName = 'id',
    Map<String, dynamic> data = const {},
  })  : _id = entityId,
        super(
          action,
          uuid: uuid,
          uuidFieldName: uuidFieldName,
          data: data,
        );

  /// Aggregate field name storing entities
  final String aggregateField;

  /// [EntityObject.id] value
  final String _id;

  /// Get [EntityObject.id] value
  String get entityId => _id ?? data[entityIdFieldName] as String;

  /// [EntityObject.id] field name in [data]
  final String entityIdFieldName;

  @override
  String toString() {
    return '$runtimeType{uuid: $uuid, action: $action, entityId: $entityId}';
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

/// Thrown when an [Command] is attempted on an [EntityObject] not found
class EntityNotFound extends InvalidOperation {
  const EntityNotFound(String message) : super(message);
}

/// Thrown when an [Command.action] with [Action.create] is attempted on an existing [EntityObject]
class EntityExists extends InvalidOperation {
  const EntityExists(String message) : super(message);
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
    return '$runtimeType{expected: ${expected.value}, actual: ${actual.value}, message: $message}';
  }
}

/// Thrown when automatic merge resolution is not possible
class ConflictNotReconcilable extends InvalidOperation {
  const ConflictNotReconcilable(
    String message, {
    @required this.local,
    @required this.remote,
  }) : super(message);
  final Iterable<Map<String, dynamic>> local;
  final Iterable<Map<String, dynamic>> remote;

  @override
  String toString() {
    return '$runtimeType{local: $local, remote: $remote}';
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
  /// Convert [Type] into lower case string
  String toLowerCase() {
    return '${this}'.toLowerCase();
  }

  /// Convert [Type] into colon delimited lower case string
  String toColonCase() {
    return '${this}'.toColonCase();
  }

  /// Convert [Type] into kebab case string
  String toKebabCase() {
    return '${this}'.toKebabCase();
  }

  /// Convert [Type] into delimited lower case string
  String toDelimiterCase(String delimiter) {
    return '${this}'.toDelimiterCase(delimiter);
  }
}

extension StringX on String {
  /// Convert [String] into colon delimited lower case string
  String toColonCase() {
    return toDelimiterCase(':');
  }

  /// Convert [String] into kebab case string
  String toKebabCase() {
    return toDelimiterCase('-');
  }

  /// Convert [String] into delimited lower case string
  String toDelimiterCase(String delimiter) {
    return '${this}'.split(RegExp('(?<=[a-z0-9])(?=[A-Z0-9])')).join(delimiter).toLowerCase();
  }
}

extension MapX on Map {
  /// Check if map contains data at given path
  bool hasPath(String ref) => elementAt(ref) != null;

  /// Get element with given reference on format '/name1/name2/name3'
  /// equivalent to map['name1']['name2']['name3'].
  ///
  /// Returns [null] if not found
  dynamic elementAt(String path) {
    final parts = path.split('/');
    dynamic found = parts.skip(parts.first.isEmpty ? 1 : 0).fold(this, (parent, name) {
      if (parent is Map<String, dynamic>) {
        if (parent.containsKey(name)) {
          return parent[name];
        }
      }
      final element = (parent ?? {});
      return element is Map ? element[name] : element is List && element.isNotEmpty ? element[int.parse(name)] : null;
    });
    return found;
  }
}
