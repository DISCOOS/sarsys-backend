import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:json_patch/json_patch.dart';
import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';

import 'domain.dart';
import 'extension.dart';

/// Message interface
class Message {
  const Message({
    @required this.uuid,
    @required this.local,
    this.created,
    String type,
    this.data,
  }) : _type = type;

  /// Massage uuid
  ///
  final String uuid;

  /// Flag indicating that event has local origin.
  /// Allow handlers to decide if event should be processed0
  ///
  final bool local;

  /// Convenience method for checking if [local == false]
  bool get remote => !local;

  /// Message creation time
  /// *NOTE*: Not stable until read from remote stream
  ///
  final DateTime created;

  /// Message data
  ///
  final Map<String, dynamic> data;

  /// Message type
  ///
  String get type => _type ?? '$runtimeType';
  final String _type;

  /// Get element at given path
  T elementAt<T>(String path) => data.elementAt(path);

  /// Get [List] of type [T] at given path
  List<T> listAt<T>(String path) {
    final list = data.elementAt(path);
    return list == null ? null : List<T>.from(list);
  }

  /// Get [Map] with keys of type [S] and values of type [T] at given path
  Map<S, T> mapAt<S, T>(String path) {
    final map = data.elementAt(path);
    return map == null ? null : Map<S, T>.from(map);
  }

  @override
  String toString() {
    return '$runtimeType{uuid: $uuid, type: $type}';
  }

  @override
  bool operator ==(Object other) => identical(this, other) || other is Message && uuid == other.uuid;
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
  Event({
    @required bool local,
    @required String uuid,
    @required String type,
    @required DateTime created,
    @required Map<String, dynamic> data,
    EventNumber number = EventNumber.none,
  })  : _number = number,
        super(
          uuid: uuid,
          type: type,
          data: data,
          local: local,
          created: created,
        );

  /// Create an event with uuid
  factory Event.unique({
    @required bool local,
    @required String type,
    @required DateTime created,
    @required Map<String, dynamic> data,
    EventNumber number = EventNumber.none,
  }) =>
      Event(
        uuid: Uuid().v4(),
        type: type,
        data: data,
        local: local,
        number: number,
        created: created,
      );

  /// Get [EventNumber] in stream
  EventNumber get number => _number;
  EventNumber _number = EventNumber.none;

  /// Set [EventNumber] in stream.
  ///
  /// Is only allowed to set if [next]
  /// is larger then current [number].
  /// This ensures that event number
  /// can be lazily set after creation
  /// or rebased after catchup.
  set number(EventNumber next) {
    if (_number > next) {
      throw StateError('Event number can only be increased');
    }
    _number = next;
  }

  /// Test if all data is deleted by evaluating if `data['deleted'] == 'true'`
  bool get isDeleted => data['deleted'] == true;

  /// Get list of JSON Patch methods from `data['patches']`
  List<Map<String, dynamic>> get patches => List<Map<String, dynamic>>.from(data['patches'] as List<dynamic>);

  @override
  String toString() {
    return '$runtimeType{uuid: $uuid, type: $type, number: $number, local: $local, created: $created}';
  }
}

/// Base class for domain events
class DomainEvent extends Event {
  DomainEvent({
    @required bool local,
    @required String uuid,
    @required String type,
    @required DateTime created,
    @required Map<String, dynamic> data,
    EventNumber number = EventNumber.none,
  }) : super(
          uuid: uuid,
          type: type,
          data: data,
          local: local,
          number: number,
          created: created ?? DateTime.now(),
        );

  Event rebase(Map<String, dynamic> base, {int delta = 0}) {
    final changed = JsonPatch.apply(base, patches, strict: false);
    return Event(
      uuid: uuid,
      type: type,
      local: local,
      created: created,
      number: number + delta,
      data: data
        ..addAll({
          'previous': base,
          'changed': changed,
        }),
    );
  }

  /// Get element at given path in [changed]. If not found, [previous] is used instead
  @override
  T elementAt<T>(String path) => changed.elementAt(path) ?? previous.elementAt(path);

  /// Get changed fields from `data['changed']`.
  Map<String, dynamic> get changed => data.mapAt<String, dynamic>('changed');

  /// Get changed fields from `data['previous']`.
  /// If empty, `data['changed']`is returned instead
  Map<String, dynamic> get previous => data.mapAt<String, dynamic>('previous');

  @override
  String toString() {
    return '$runtimeType{uuid: $uuid, type: $type, number: $number, local: $local, created: $created}';
  }

  Event toEvent(uuidFieldName) => Event(
      uuid: uuid,
      type: type,
      local: local,
      number: number,
      created: created,
      data: SourceEvent.toData(
        data?.elementAt<String>('uuid'),
        uuidFieldName,
        patches: patches,
        deleted: isDeleted,
        index: data?.elementAt<int>('index'),
      ));

  SourceEvent toSourceEvent({
    @required String streamId,
    @required EventNumber number,
    @required String uuidFieldName,
  }) =>
      SourceEvent(
        uuid: uuid,
        type: type,
        local: local,
        created: created,
        streamId: streamId,
        data: SourceEvent.toData(
          data?.elementAt<String>('uuid'),
          uuidFieldName,
          patches: patches,
          deleted: isDeleted,
          index: data?.elementAt<int>('index'),
        ),
        number: number ?? this.number,
      );

  static Map<String, dynamic> toData(
    String uuid,
    String uuidFieldName, {
    int index,
    Map<String, dynamic> previous,
    Map<String, dynamic> changed = const {},
    List<Map<String, dynamic>> patches = const [],
    bool deleted = false,
  }) =>
      {
        uuidFieldName: uuid,
        'changed': changed,
        'patches': patches,
        'deleted': deleted,
        if (index != null) 'index': index,
        if (previous != null) 'previous': previous,
      };
}

class EntityObjectEvent extends DomainEvent {
  EntityObjectEvent({
    @required bool local,
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
          local: local,
          created: created,
          data: {'index': index}..addAll(data),
        );

  final String idFieldName;
  final String aggregateField;

  int get index => data['index'];
  String get id => entity.elementAt(idFieldName);
  Map<String, dynamic> get entity => elementAt('$aggregateField/$index');
  EntityObject get entityObject => EntityObject(id, entity, idFieldName);
}

class ValueObjectEvent<T> extends DomainEvent {
  ValueObjectEvent({
    @required bool local,
    @required String uuid,
    @required String type,
    @required DateTime created,
    @required this.valueField,
    @required Map<String, dynamic> data,
  }) : super(
          uuid: uuid,
          type: type,
          local: local,
          created: created,
          data: data,
        );

  final String valueField;

  T get value => elementAt(valueField) as T;
}

/// Base class for events sourced from an event stream.
///
/// A [Repository] folds [SourceEvent]s into [DomainEvent]s with [Repository.get].
class SourceEvent extends Event {
  SourceEvent({
    @required String uuid,
    @required String type,
    @required this.streamId,
    @required DateTime created,
    @required EventNumber number,
    @required Map<String, dynamic> data,
    bool local,
  }) : super(
          uuid: uuid,
          type: type,
          data: data,
          number: number,
          local: local ?? false,
          created: created ?? DateTime.now(),
        );
  final String streamId;

  @override
  String toString() {
    return '$runtimeType{uuid: $uuid, type: $type, number: $number, local: $local, created: $created}';
  }

  static Map<String, dynamic> toData(
    String uuid,
    String uuidFieldName, {
    int index,
    bool deleted = false,
    List<Map<String, dynamic>> patches = const [],
  }) =>
      {
        uuidFieldName: uuid,
        'patches': patches,
        'deleted': deleted,
        if (index != null) 'index': index,
      };
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
        super(
          uuid: uuid,
          data: data,
          local: true,
        );

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
  static Map<String, dynamic> addToList<T>(
    Map<String, dynamic> data,
    String field,
    Iterable<T> items,
  ) =>
      Map.from(data)
        ..update(
          field,
          (current) => List<T>.from(current as List)..addAll(items),
          ifAbsent: () => items,
        );

  /// Remove value from list in given field
  static Map<String, dynamic> removeFromList<T>(
    Map<String, dynamic> data,
    String field,
    Iterable<T> items,
  ) =>
      Map.from(data)
        ..update(
          field,
          (operations) => List<T>.from(operations as List)
            ..removeWhere(
              (item) => items.contains(item),
            ),
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
  void notify(Object source, Message message);
}

/// Event publisher interface
abstract class EventPublisher<T extends Event> {
  void publish(Object source, T event);
}

/// Command sender interface
abstract class CommandSender {
  void send(Object source, Command command);
}

/// Message handler interface
abstract class MessageHandler<T extends Message> {
  void handle(Object source, T message);
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

  EventNumber toNumber() => EventNumber(value);
}

/// Get enum value name
String enumName(Object o) => o.toString().split('.').last;

/// Type helper class
Type typeOf<T>() => T;
