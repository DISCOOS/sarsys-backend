import 'dart:async';
import 'dart:io';

import 'package:json_patch/json_patch.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';

import 'bus.dart';
import 'core.dart';
import 'source.dart';

/// [Repository] manager class.
///
/// Use this to manage sourcing of multiple event streams
class RepositoryManager {
  RepositoryManager(
    this.bus,
    this.connection, {
    this.prefix,
  }) : logger = Logger('RepositoryManager');

  final Logger logger;

  /// Prefix all streams with this prefix
  final String prefix;

  /// [MessageBus] instance
  final MessageBus bus;

  /// [EventStoreConnection] instance
  final EventStoreConnection connection;

  /// [Map] of aggregate root repositories and the [EventStore] storing events from it.
  final Map<Repository, EventStore> _stores = {};

  /// Register [Repository] with given [AggregateRoot].
  ///
  /// Parameter [prefix] is concatenated using
  /// `EventStore.toCanonical([this.prefix, prefix])`
  /// which returns a colon-delimited stream prefix.
  ///
  /// Parameter [stream] is optional. It defines which
  /// stream to source events from. If omitted, the stream
  /// name is inferred from the aggregate root type [T] using
  /// `typeOf<T>().toColonCase()` which returns a colon
  /// delimited string of Camel Case words.
  ///
  /// If [useInstanceStreams] is true, eventstore will write
  /// events for each [AggregateRoot] instance to a separate stream.
  ///
  /// Throws [InvalidOperation] if type of [Repository]
  /// returned from [create] is already registered.
  void register<T extends AggregateRoot>(
    Repository<Command, T> create(EventStore store), {
    String prefix,
    String stream,
    bool useInstanceStreams = true,
  }) {
    final store = EventStore(
      bus: bus,
      connection: connection,
      prefix: EventStore.toCanonical([
        this.prefix,
        prefix,
      ]),
      aggregate: stream ?? typeOf<T>().toColonCase(),
      useInstanceStreams: useInstanceStreams ?? true,
    );
    final repository = create(store);
    if (get<Repository<Command, T>>() != null) {
      throw InvalidOperation("Repository [${typeOf<T>()} already registered");
    }
    _stores.putIfAbsent(
      repository,
      () => store,
    );
  }

  /// Build all repositories from event stores
  ///
  /// Throws an [ProjectionNotAvailable] if one
  /// or more [EventStore.useInstanceStreams] are
  /// true and system projection
  /// [$by_category](https://eventstore.org/docs/projections/system-projections/index.html?tabs=tabid-5#by-category)
  ///  is not available.
  Future<void> build() async {
    if (_stores.values.any(
      (store) => store.useInstanceStreams,
    )) {
      await _prepare();
    }
    await Future.wait(_stores.keys.map(
      (repository) => repository.build(),
    ));
  }

  /// Check if projections are enabled
  Future<void> _prepare() async {
    var result = await connection.readProjection(
      name: '\$by_category',
    );
    if (result.isOK) {
      if (result.isRunning == false) {
        // Try to enable command
        result = await connection.projectionCommand(
          name: '\$by_category',
          command: ProjectionCommand.enable,
        );
        if (result.isOK) {
          // TODO: Check projection startup progress and until complete
          const seconds = 5;
          logger.info("Waiting $seconds seconds for projection '\$by_category' to start...");
          // Check status again after 5 seconds
          result = await Future.delayed(
              const Duration(seconds: seconds),
              () => connection.readProjection(
                    name: '\$by_category',
                  ));
        }
      }
    }
    // Give up?
    if (result.isRunning == false) {
      logger.severe("Projections are required but could not be enabled");
      throw ProjectionNotAvailable(
        "EventStore projection '\$by_category' not ${result.isOK ? 'running' : 'found'}",
      );
    }
  }

  /// Get [Repository] from [Type]
  T get<T extends Repository>() {
    final items = _stores.keys.whereType<T>();
    return items.isEmpty ? null : items.first;
  }

  /// Dispose all [RepositoryManager] instances
  void dispose() {
    _stores.values.forEach(
      (manager) => manager.dispose(),
    );
    _stores.clear();
  }
}

/// Repository or [AggregateRoot]s as the single responsible for all transactions on each aggregate
abstract class Repository<S extends Command, T extends AggregateRoot> implements CommandHandler<S> {
  /// Repository constructor
  ///
  /// Parameter [store] is required.
  /// [RepositoryManager.register] will pass
  /// an correctly configured [EventStore] instance
  /// with a anonymous callback method.
  ///
  /// Parameter [uuidFieldName] defines the name of the
  /// required field in [AggregateRoot.data] that contains a
  /// [Universally unique identifier](https://en.wikipedia.org/wiki/Universally_unique_identifier)
  /// for each [AggregateRoot] instance. Default value is 'uui'.
  ///
  Repository({
    @required this.store,
    this.uuidFieldName = 'uuid',
    int maxBackoffTimeSeconds = 10,
  })  : logger = Logger("Repository[${typeOf<T>()}]"),
        maxBackoffTime = Duration(seconds: maxBackoffTimeSeconds);

  final EventStore store;

  final Logger logger;
  final String uuidFieldName;

  /// Maximum backoff duration between reconnect attempts
  final Duration maxBackoffTime;

  /// Map of aggregate roots
  final Map<String, T> _aggregates = {};

  /// Flag indicating that [build] succeeded
  bool _ready = false;
  bool get ready => _ready;

  /// Build repository from local events.
  Future build() async {
    final events = await store.replay(this);
    if (events == 0) {
      logger.info("Stream '${store.canonicalStream}' is empty");
    } else {
      logger.info("Repository loaded with ${_aggregates.length} aggregates");
    }
    store.subscribe(this);
    _ready = true;
  }

  /// Get number of aggregates
  int get count => _aggregates.length;

  /// Execute command on given aggregate root.
  ///
  /// SHALL NOT be overridden by subclasses. For custom commands override the [custom] method instead.
  ///
  /// Throws an [InvalidOperation] exception if [validate] on [command] fails.
  ///
  /// Throws an [WrongExpectedEventVersion] if [EventStore.current] event number is not
  /// equal to the last event number in  [EventStore.canonicalStream]. This failure is
  /// recoverable when the store has caught up with [EventStore.canonicalStream].
  ///
  /// Throws an [SocketException] failure if calls on [EventStore.connection] fails.
  /// This failure is not recoverable.
  ///
  /// Throws an [MultipleAggregatesWithChanges] if other aggregates have changes.
  /// This failure is recoverable, but with side effect of losing data.
  ///
  /// Throws [WriteFailed] for all other failures. This failure is not recoverable.
  @override
  FutureOr<Iterable<Event>> execute(S command) async => _executeWithRetry(command, 10, 0);

  /// Execute command on given aggregate given times before giving up
  ///
  FutureOr<Iterable<Event>> _executeWithRetry(S command, int max, int attempt) async {
    T aggregate;
    try {
      final data = validate(command);
      switch (command.action) {
        case Action.create:
          aggregate = get(command.uuid, data: data);
          break;
        case Action.update:
          aggregate = get(command.uuid)..patch(data, type: typeOf<S>().toString(), command: true);
          break;
        case Action.delete:
          aggregate = get(command.uuid)..delete();
          break;
        case Action.custom:
          aggregate = custom(command);
      }
      return aggregate.isChanged ? await push(aggregate) : [];
    } on WrongExpectedEventVersion catch (e, stacktrace) {
      // TODO: Detect and reconcile merge conflicts
      // Try again?
      if (attempt < max) {
        return _executeWithRetry(command, max, attempt + 1);
      }
      logger.warning("Aborted execution of $command after $max retries: $e with stacktrace: $stacktrace");
      rethrow;
    } on MultipleAggregatesWithChanges catch (e, stacktrace) {
      // This will remove all pending changes
      final events = rollback(aggregate);
      logger.severe("Rolled back ${events.length} uncommitted events: $e with stacktrace: $stacktrace");
      // Try again?
      if (attempt < max) {
        return _executeWithRetry(command, max, attempt + 1);
      }
      logger.warning("Aborted execution of $command after $max retries: $e");
      rethrow;
    } catch (e, stacktrace) {
      if (aggregate != null) {
        final events = rollback(aggregate);
        logger.severe(
          "Failed to execute $command. ${events.length} events rolled back: $e with stacktrace: $stacktrace",
        );
      }
      rethrow;
    }
  }

  /// Check if this [Repository] contains any aggregates with [AggregateRoot.isChanged]
  bool get isChanged => _aggregates.values.any((aggregate) => aggregate.isChanged);

  /// Handler for custom commands.
  ///
  /// MUST BE overridden by subclasses if [Command]s with action [Action.custom] are implemented.
  T custom(S command) => throw InvalidOperation("Custom command $command not handled");

  /// Push aggregate changes to remote storage
  ///
  /// Returns pushed events is saved, empty list otherwise
  ///
  /// Throws an [WrongExpectedEventVersion] if [EventStore.current] event number is not
  /// equal to the last event number in  [EventStore.canonicalStream]. This failure is
  /// recoverable when the store has caught up with [EventStore.canonicalStream].
  ///
  /// Throws an [SocketException] failure if calls on [EventStore.connection] fails.
  /// This failure is not recoverable.
  ///
  /// Throws [WriteFailed] for all other failures. This failure is not recoverable.
  Future<Iterable<Event>> push(T aggregate) async {
    try {
      return aggregate.isChanged ? await store.push(aggregate) : [];
    } on WrongExpectedEventVersion {
      // Are the other aggregates with uncommitted changes?
      _assertSingleAggregateChanged(aggregate);
      // Rollback all changes, catch up with stream and rethrow error
      rollback(aggregate);
      final count = await store.catchUp(this);
      logger.info("Caught up with $count events from ${store.canonicalStream}");
      rethrow;
    }
  }

  /// Assert that only a given [AggregateRoot] has changes.
  ///
  /// Every [Command.action] on a [Repository] should be
  /// committed or rolled back before next command is executed.
  void _assertSingleAggregateChanged(aggregate) {
    final other = _aggregates.values.firstWhere(
      (test) => test != aggregate && test.isChanged,
      orElse: () => null,
    );
    if (other != null) {
      throw MultipleAggregatesWithChanges("Found uncommitted changes that will be lost in $other");
    }
  }

  /// Rollback all pending changes in aggregate
  Iterable<DomainEvent> rollback(T aggregate) {
    // TODO: Roll back changes to Event.data - keep delta until commit.
    final events = aggregate.getUncommittedChanges();
    if (aggregate.isNew) {
      _aggregates.remove(aggregate.uuid);
    } else if (aggregate.isChanged) {
      aggregate.loadFromHistory(store.get(aggregate.uuid).map(toDomainEvent));
    }
    return events;
  }

  /// Get aggregate with given id.
  ///
  /// Will create a new aggregate if not found by applying a left
  /// fold from [SourceEvent] to [DomainEvent]. Each [DomainEvent]
  /// is then processed by applying changes to [AggregateRoot.data]
  /// in accordance to the business value of to each [DomainEvent].
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
  Iterable<DomainEvent> getUncommittedChanges() => _pending;

  /// Check if uncommitted changes exists
  bool get isNew => _applied.isEmpty;

  /// Check if uncommitted changes exists
  bool get isChanged => _pending.isNotEmpty;

  DateTime _createdWhen;
  DateTime _changedWhen;

  /// Get [DateTime] of when this [AggregateRoot] was created
  DateTime get createdWhen => _createdWhen;

  /// Get [DateTime] of when this [AggregateRoot] was changed
  DateTime get changedWhen => _changedWhen;

  /// Get aggregate uuid from event
  String toAggregateUuid(Event event) => event.data[uuidFieldName] as String;

  /// Load events from history.
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
  DomainEvent patch(Map<String, dynamic> data, {DateTime timestamp, String type, bool command}) {
    final diffs = JsonPatch.diff(this.data, data);
    // TODO: Add support for strict validation of data (fields and values)
    // Replace and add is supported by patch (put will introduce remove)
    final willChange = diffs.where((diff) => const ['add', 'replace'].contains(diff['op'])).isNotEmpty;
    // Remove read-only fields
    return willChange
        ? _apply(
            updated(
              data,
              type: type,
              command: command,
              timestamp: timestamp,
            ),
            true,
            false,
          )
        : null;
  }

  // TODO: Add support for detecting tombstone (delete) events
  /// Delete aggregate root
  DomainEvent delete() {
    data.clear();
    return _apply(deleted(), true, false);
  }

  /// Get uncommitted changes and clear internal cache
  Iterable<DomainEvent> commit() {
    final changes = _pending.toList();
    _pending.clear();
    return changes;
  }

  /// Get aggregate created event. Only invoked from constructor.
  @protected
  DomainEvent created(Map<String, dynamic> data, {String type, DateTime timestamp}) =>
      throw UnimplementedError("created() not implemented");

  /// Get aggregate updated event. Invoked from [Repository]
  @protected
  DomainEvent updated(
    Map<String, dynamic> data, {
    String type,
    bool command,
    DateTime timestamp,
  }) =>
      throw UnimplementedError("updated() not implemented");

  /// Get aggregate deleted event. Invoked from [Repository]
  @protected
  DomainEvent deleted({String type, DateTime timestamp}) => throw UnimplementedError("deleted() not implemented");

  /// Applies changed to [data].
  ///
  /// If [isChanged] is true, the event is added as [_pending] commit to store
  DomainEvent _apply(DomainEvent event, bool isChanged, bool isNew) {
    if (toAggregateUuid(event) != uuid) {
      throw InvalidOperation("Aggregate has $uuid, event $event contains ${toAggregateUuid(event)}");
    }

    // Set timestamps
    if (_applied.isEmpty || isNew) {
      _createdWhen = event.created;
      _changedWhen = _createdWhen;
    } else {
      _changedWhen = event.created;
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
