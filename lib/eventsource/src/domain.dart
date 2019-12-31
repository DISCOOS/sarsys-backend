import 'dart:async';
import 'dart:io';

import 'package:json_patch/json_patch.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';

import 'core.dart';
import 'source.dart';

/// Base class for domain events
class DomainEvent extends Event {
  const DomainEvent({
    @required String uuid,
    @required String type,
    @required Map<String, dynamic> data,
  }) : super(
          uuid: uuid,
          type: type,
          data: data,
        );
}

/// Repository or [AggregateRoot]s as the single responsible for all transactions on each aggregate
abstract class Repository<S extends Command, T extends AggregateRoot> implements CommandHandler<S> {
  Repository({
    @required this.store,
    this.uuidFieldName = 'uuid',
    int maxBackoffTimeSeconds = 10,
  })  : logger = Logger("${typeOf<T>()}"),
        maxBackoffTime = Duration(seconds: maxBackoffTimeSeconds);

  final EventStore store;
  final Logger logger;
  final String uuidFieldName;

  /// Maximum backoff duration between reconnect attempts
  final Duration maxBackoffTime;

  /// Map of aggregate roots
  final Map<String, T> _aggregates = {};

  /// Build repository from local events
  Future build() async {
    final events = await store.replay(this);
    if (events == 0) {
      logger.info("Stream '${store.canonicalStream}' is empty");
    } else {
      logger.info("Repository loaded with ${_aggregates.length} aggregates");
    }
    store.subscribe(this);
  }

  /// Get number of aggregates
  int get count => _aggregates.length;

  /// Execute command on given aggregate root.
  ///
  /// SHALL NOT be overridden by subclasses. For custom commands override the [custom] method instead.
  ///
  /// Throws an [InvalidOperation] exception if [validate] on [command] fails.
  /// Throws an [SocketException] exception if calls on [store] fails.
  @override
  FutureOr<Iterable<Event>> execute(S command) async => _executeWithRetry(command, 10, 0);

  /// Execute command on given aggregate given times before giving up
  ///
  FutureOr<Iterable<Event>> _executeWithRetry(S command, int max, int attempt) async {
    try {
      T aggregate;
      final data = validate(command);
      switch (command.action) {
        case Action.create:
          aggregate = get(command.uuid, data: data);
          break;
        case Action.update:
          aggregate = get(command.uuid)..patch(data);
          break;
        case Action.delete:
          aggregate = get(command.uuid)..delete();
          break;
        case Action.custom:
          aggregate = custom(command);
      }
      return await push(aggregate);
    } on WrongExpectedEventVersion catch (e) {
      // TODO: Detect and reconcile merge conflicts
      // Try again?
      if (attempt < max) {
        return _executeWithRetry(command, max, count + 1);
      }
      logger.warning("Aborted execution of $command after $max retries: $e");
      rethrow;
    } on SocketException catch (e) {
      logger.severe("Failed to execute $command: $e");
      rethrow;
    }
  }

  /// Handler for custom commands.
  ///
  /// MUST BE overridden by subclasses if [Command]s with action [Action.custom] are implemented.
  T custom(S command) => throw InvalidOperation("Custom command $command not handled");

  /// Get aggregate with given id.
  ///
  /// Will create a new aggregate if not found.
  T get(String uuid, {Map<String, dynamic> data = const {}}) =>
      _aggregates[uuid] ??
      _aggregates.putIfAbsent(
        uuid,
        () => create(uuid, data)..loadFromHistory(store.get(uuid).map(toDomainEvent)),
      );

  /// Get all aggregate roots.
  Iterable<T> getAll({
    int offset = 0,
    int limit = 20,
  }) {
    if (offset < 0 || limit < 0) {
      throw const InvalidOperation("Offset and limit can not be negative");
    } else if (offset > _aggregates.length) {
      throw InvalidOperation("Index out of bounds: offset $offset > length ${_aggregates.length}");
    } else if (offset == 0 && limit == 0) {
      return _aggregates.values.toList();
    }
    return _aggregates.values.skip(offset).take(limit);
  }

  /// Commit aggregate changes to local storage
  ///
  /// Returns true if changes was saved, false otherwise
  Iterable<Event> commit(T aggregate) => store.commit(aggregate);

  /// Commit all changes and return pending events
  Iterable<Event> commitAll() => _aggregates.values.map(store.commit).fold(
        <Event>[],
        (events, items) => <Event>[...events, ...items],
      );

  /// Push aggregate changes to remote storage
  ///
  /// Returns pushed events is saved, empty list otherwise
  Future<Iterable<Event>> push(T aggregate) async {
    try {
      return await store.push([aggregate]);
    } on WrongExpectedEventVersion {
      // Are the other aggregates with uncommitted changes?
      final other = _aggregates.values.firstWhere(
        (test) => test != aggregate && test.isChanged,
        orElse: () => null,
      );
      if (other != null) {
        throw WriteFailed("Found uncommitted changes that will be lost in $other");
      }
      // Rollback all changes, catch up with stream and rethrow error
      if (aggregate.isNew) {
        _aggregates.remove(aggregate.uuid);
      } else {
        aggregate.loadFromHistory(store.get(aggregate.uuid).map(toDomainEvent));
      }
      final count = await store.catchUp(this);
      logger.info("Caught up with $count events from ${store.canonicalStream}");
      rethrow;
    }
  }

  /// Push all aggregate changes to remote storage
  ///
  /// Returns pushed events is saved, empty list otherwise
  Future<Iterable<Event>> pushAll() => store.push(_aggregates.values);

  /// Validate data
  ///
  /// Subclasses MAY override this method to add additional validation
  ///
  /// Throws [InvalidOperation] if [Event.data] does not contain [Repository.uuidFieldName]
  @mustCallSuper
  Map<String, dynamic> validate(S command) {
    if (command.uuid == null) {
      throw const UUIDIsNull("Field [uuid] is null");
    }
    switch (command.action) {
      case Action.create:
        if (_aggregates.containsKey(command.uuid)) {
          throw AggregateExists("Aggregate ${command.uuid} exists");
        }
        break;
      case Action.update:
      case Action.delete:
      case Action.custom:
        if (!_aggregates.containsKey(command.uuid)) {
          throw AggregateNotFound("Aggregate ${command.uuid} does not exists");
        }
        break;
    }
    return command.data;
  }

  /// Get domain event from event source
  DomainEvent toDomainEvent(Event event);

  /// Get aggregate uuid from event
  String toAggregateUuid(Event event) => event.data[uuidFieldName] as String;

  /// Create aggregate root with given id. Should only called from within [Repository].
  @protected
  T create(String uuid, Map<String, dynamic> data);

  /// Check if repository contains given aggregate root
  bool contains(String uuid) => _aggregates.containsKey(uuid);
}

/// Base class for [aggregate roots](https://martinfowler.com/bliki/DDD_Aggregate.html).
abstract class AggregateRoot {
  @mustCallSuper
  AggregateRoot(
    this.uuid,
    Map<String, dynamic> data, {
    this.uuidFieldName = 'uuid',
  }) : data = Map.from(data) {
    _apply(
      created(
        Map.from(data)
          ..putIfAbsent(
            uuidFieldName,
            () => uuid,
          ),
      ),
      true,
      true,
    );
  }

  /// Aggregate uuid
  ///
  /// Not the same as [Event.uuid], which is unique for each [Event].
  final String uuid;

  /// Field name in [Event.data] for [AggregateRoot.uuid].
  final String uuidFieldName;

  /// Aggregate root data (weak schema)
  final Map<String, dynamic> data;

  /// Local uncommitted changes
  final _pending = <DomainEvent>[];

  /// [Event.uuid]s of applied events
  final _applied = <String>{};

  /// Check if event is applied
  bool isApplied(Event event) => _applied.contains(event.uuid);

  /// Get changed not committed to store
  Iterable<Event> getUncommittedChanges() => _pending;

  /// Check if uncommitted changes exists
  bool get isNew => _applied.isEmpty;

  /// Check if uncommitted changes exists
  bool get isChanged => _pending.isNotEmpty;

  /// Get aggregate uuid from event
  String toAggregateUuid(Event event) => event.data[uuidFieldName] as String;

  /// Load events from history
  @protected
  AggregateRoot loadFromHistory(Iterable<DomainEvent> events) {
    // Only clear if history exist, otherwise keep the event from construction
    if (events.isNotEmpty) {
      _pending.clear();
      _applied.clear();
    }
    events?.forEach((event) => _apply(event, false, false));
    return this;
  }

  /// Patch aggregate root with data (free-form json compatible data).
  ///
  /// Returns a [DomainEvent] if data was changed, null otherwise.
  DomainEvent patch(Map<String, dynamic> data) {
    final diffs = JsonPatch.diff(this.data, data);
    // TODO: Add support for strict validation of data (fields and values)
    // Replace and add is supported by patch (put will introduce remove)
    final willChange = diffs.where((diff) => const ['add', 'replace'].contains(diff['op'])).isNotEmpty;
    // Remove read-only fields
    return willChange ? _apply(updated(data), true, false) : null;
  }

  /// Delete aggregate root
  DomainEvent delete() {
    data.clear();
    return _apply(deleted(), true, false);
  }

  /// Get uncommitted changes and clear internal cache
  Iterable<DomainEvent> commit() {
    final changes = _pending.toSet();
    _pending.clear();
    return changes;
  }

  /// Get aggregate created event. Only invoked from constructor.
  @protected
  DomainEvent created(Map<String, dynamic> data);

  /// Get aggregate updated event. Invoked from [Repository]
  @protected
  DomainEvent updated(Map<String, dynamic> data) => throw UnsupportedError("Delete not implemented");

  /// Get aggregate deleted event. Invoked from [Repository]
  @protected
  DomainEvent deleted() => throw UnsupportedError("Delete not implemented");

  /// Applies changed to [data].
  ///
  /// If [isChanged] is true, the event is added as [_pending] commit to store
  DomainEvent _apply(DomainEvent event, bool isChanged, bool isNew) {
    if (toAggregateUuid(event) != uuid) {
      throw InvalidOperation("Aggregate has $uuid, event $event contains ${toAggregateUuid(event)}");
    }
    data.addAll(event.data);
    if (isChanged) {
      _pending.add(event);
    }
    if (!isNew) {
      _applied.add(event.uuid);
    }
    return event;
  }
}
