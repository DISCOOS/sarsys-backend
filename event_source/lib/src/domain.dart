import 'dart:async';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:json_patch/json_patch.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';

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
    Repository<Command, T> Function(EventStore) create, {
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
      throw InvalidOperation('Repository [${typeOf<T>()} already registered');
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
  Future<void> build({List<String> withProjections = const []}) async {
    final projections = Set.from(withProjections);
    if (_stores.values.any(
      (store) => store.useInstanceStreams,
    )) {
      projections.add('\$by_category');
    }
    await Future.wait(
      projections.map((command) => _prepare(command)),
    );
    await Future.wait(_stores.keys.map(
      (repository) => repository.build(),
    ));
  }

  /// Check if projections are enabled
  Future<void> _prepare(String projection) async {
    var result = await connection.readProjection(
      name: projection,
    );
    if (result.isOK) {
      if (result.isRunning == false) {
        // Try to enable command
        result = await connection.projectionCommand(
          name: projection,
          command: ProjectionCommand.enable,
        );
        if (result.isOK) {
          // TODO: Check projection startup progress and until complete
          const seconds = 5;
          logger.info("Waiting $seconds seconds for projection $projection' to start...");
          // Check status again after 5 seconds
          result = await Future.delayed(
              const Duration(seconds: seconds),
              () => connection.readProjection(
                    name: projection,
                  ));
        }
      }
    }
    // Give up?
    if (result.isRunning == false) {
      logger.severe('Projections are required but could not be enabled');
      throw ProjectionNotAvailable(
        "EventStore projection '$projection' not ${result.isOK ? 'running' : 'found'}",
      );
    } else {
      logger.info("EventStore projection '$projection' is running");
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

/// [Message] type name to [DomainEvent] processor method
typedef Process = DomainEvent Function(Message message);

/// [Message] type name to [DomainEvent] processor method
typedef Enforcer = Command Function(AggregateRoot root, DomainEvent event);

/// Create invariant for given [repository]
typedef CreateInvariant<T extends Repository> = Invariant<T> Function(T repository);

/// Interface for invariant execution
abstract class Invariant<T extends Repository> {
  Invariant(this.field, this.enforcer, this.repository);
  final String field;
  final Enforcer enforcer;
  final T repository;

  Type get aggregateType => repository.aggregateType;

  void call(DomainEvent event);
}

/// Invariant for foreign uuids in list with name [field]
class AggregateListInvariant<T extends Repository> extends Invariant<T> {
  AggregateListInvariant(
    String field,
    Enforcer enforcer,
    T repository, {
    this.multiple = false,
  }) : super(field, enforcer, repository);

  final bool multiple;

  @override
  void call(DomainEvent event) async => toUuids(event)
      .where(
        repository.contains,
      )
      .forEach(
        (uuid) async => await repository.execute(
          enforcer(repository.get(uuid), event),
        ),
      );

  Iterable<String> toUuids(DomainEvent event) {
    final uuids = <String>[];
    final reference = event.data[aggregateType.toLowerCase()];
    if (reference is Map<String, dynamic>) {
      if (reference.containsKey('uuid')) {
        uuids.add(reference['uuid'] as String);
      }
    }
    if (uuids.isEmpty || multiple) {
      // TODO: Implement test that fails when number of open aggregates are above threshold
      // Do a full search for foreign id. This will be efficient
      // as long as number of incidents are reasonable low
      final foreign = event.data[repository.uuidFieldName] as String;
      uuids.addAll(
        repository.aggregates
            .where(
              (aggregate) => !aggregate.isDeleted,
            )
            .where(
              (aggregate) => aggregate.data[field] is List,
            )
            .where(
              (aggregate) => List<String>.unmodifiable(aggregate.data[field] as List).contains(foreign),
            )
            .map(
              (aggregate) => aggregate.uuid,
            ),
      );
    }
    return uuids;
  }
}

/// Repository or [AggregateRoot]s as the single responsible for all transactions on each aggregate
abstract class Repository<S extends Command, T extends AggregateRoot>
    implements CommandHandler<S>, MessageHandler<DomainEvent> {
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
  /// for each [AggregateRoot] instance. Default value is 'uuid'.
  ///
  Repository({
    @required this.store,
    @required Map<Type, Process> processors,
    this.uuidFieldName = 'uuid',
    int maxBackoffTimeSeconds = 10,
  })  : _processors = Map.unmodifiable(processors.map(
          (type, process) => MapEntry('$type', process),
        )),
        logger = Logger('Repository[${typeOf<T>()}]'),
        maxBackoffTime = Duration(seconds: maxBackoffTimeSeconds);

  final Logger logger;
  final EventStore store;
  final String uuidFieldName;

  /// Get [AggregateRoot] type
  Type get aggregateType => typeOf<T>();

  /// Flag indicating that [build] succeeded
  bool _ready = false;
  bool get ready => _ready;

  Future<bool> readyAsync() async {
    final callback = Completer<bool>();
    _awaitReady(callback);
    return callback.future;
  }

  void _awaitReady(Completer<bool> completer) async {
    if (_ready == false) {
      Future.delayed(const Duration(milliseconds: 100), () => _awaitReady(completer));
    } else {
      completer.complete(true);
    }
  }

  /// Maximum backoff duration between reconnect attempts
  final Duration maxBackoffTime;

  /// [Message] type name to [DomainEvent] processors
  final Map<String, Process> _processors;

  /// Map of aggregate roots
  final Map<String, T> _aggregates = {};
  Iterable<T> get aggregates => List.unmodifiable(_aggregates.values);

  /// Get number of aggregates
  int get count => _aggregates.length;

  /// Get aggregate uuid from event
  String toAggregateUuid(Event event) => event.data[uuidFieldName] as String;

  /// Create aggregate root with given id. Should only called from within [Repository].
  @protected
  T create(Map<String, Process> processors, String uuid, Map<String, dynamic> data);

  /// Check if repository contains given aggregate root
  bool contains(String uuid) => _aggregates.containsKey(uuid);

  /// Build repository from local events.
  Future build() async {
    await replay();
    subscribe();
    willStartProcessingEvents();
    _ready = true;
  }

  /// Replay events into this [Repository]
  Future<int> replay() async {
    final events = await store.replay<T>(this);
    if (events == 0) {
      logger.info("Stream '${store.canonicalStream}' is empty");
    } else {
      logger.info('Repository loaded with ${_aggregates.length} aggregates');
    }
    return events;
  }

  /// Subscribe this [repository] to compete for changes from [store]
  void compete({
    int consume = 20,
    ConsumerStrategy strategy = ConsumerStrategy.RoundRobin,
    Duration maxBackoffTime = const Duration(seconds: 10),
  }) =>
      store.compete(
        this,
        consume: consume,
        strategy: strategy,
        maxBackoffTime: maxBackoffTime,
      );

  /// Subscribe this [repository] to receive all changes from [store]
  void subscribe({
    Duration maxBackoffTime = const Duration(seconds: 10),
  }) =>
      store.subscribe(
        this,
        maxBackoffTime: maxBackoffTime,
      );

  /// Called after [build()] is completed.
  void willStartProcessingEvents() => {};

  /// Get domain event from given event
  DomainEvent toDomainEvent(Event event) {
    if (event is DomainEvent) {
      return event;
    }
    final process = _processors['${event.type}'];
    if (process != null) {
      return process(event);
    }
    throw InvalidOperation('Message ${event.type} not recognized');
  }

  /// [DomainEvent] type to constraint definitions
  final Map<Type, CreateInvariant> _constraints = {};

  /// Register invariant for given DomainEvent [E]
  void constraint<E extends DomainEvent>(CreateInvariant creator, {bool unique = true}) {
    final type = typeOf<E>();
    if (unique && _constraints.containsKey(type)) {
      throw InvalidOperation('Invariant for event $type already registered');
    }
    store.bus.register<E>(this);
    _constraints.putIfAbsent(type, () => creator);
  }

  @override
  void handle(DomainEvent message) async {
    if (_constraints.isNotEmpty) {
      try {
        final creator = _constraints[message.runtimeType];
        if (creator != null) {
          final invariant = creator(this);
          invariant(message);
        }
      } on Exception catch (e) {
        logger.severe('Failed to enforce invariant for $message, failed with: $e');
      }
    }
  }

  /// Execute command on given aggregate root.
  ///
  /// SHALL NOT be overridden by subclasses. For custom commands override the [custom] method instead.
  ///
  /// Throws an [InvalidOperation] exception if [prepare] on [command] fails.
  ///
  /// Throws an [MultipleAggregatesWithChanges] if other aggregates have changes.
  /// This failure is recoverable, but with side effect of losing data.
  ///
  /// Throws an [WrongExpectedEventVersion] if [EventStore.current] event number is not
  /// equal to the last event number in  [EventStore.canonicalStream]. This failure is
  /// recoverable when the store has caught up with [EventStore.canonicalStream]. Push
  /// will attempt to catchup to head of stream [maxAttempts] before giving up by
  /// throwing [WrongExpectedEventVersion].
  ///
  /// Throws an [ConflictNotReconcilable] if concurrent changes was made on same
  /// [AggregateRoot.data], which implies a manual merge must be performed.
  /// This failure is not recoverable.
  ///
  /// Throws an [SocketException] failure if calls on [EventStore.connection] fails.
  /// This failure is not recoverable.
  ///
  /// Throws [WriteFailed] for all other failures. This failure is not recoverable.
  @override
  FutureOr<Iterable<DomainEvent>> execute(S command, {int maxAttempts = 10}) async {
    final data = prepare(command);
    final isEntity = command is EntityCommand;
    final action = isEntity ? Action.update : command.action;

    T aggregate;
    switch (action) {
      case Action.create:
        aggregate = get(command.uuid, data: data);
        break;
      case Action.update:
        aggregate = get(command.uuid)..patch(data, emits: command.emits, timestamp: command.created);
        break;
      case Action.delete:
        aggregate = get(command.uuid)..delete();
        break;
      case Action.custom:
        aggregate = custom(command);
    }
    return aggregate.isChanged ? await push(aggregate, maxAttempts: maxAttempts) : [];
  }

  /// Check if this [Repository] contains any aggregates with [AggregateRoot.isChanged]
  bool get isChanged => _aggregates.values.any((aggregate) => aggregate.isChanged);

  /// Handler for custom commands.
  ///
  /// MUST BE overridden by subclasses if [Command]s with action [Action.custom] are implemented.
  T custom(S command) => throw InvalidOperation('Custom command $command not handled');

  /// Push aggregate changes to remote storage
  ///
  /// Returns pushed events is saved, empty list otherwise
  ///
  /// Throws an [MultipleAggregatesWithChanges] if other aggregates have changes.
  /// This failure is recoverable, but with side effect of losing data.
  ///
  /// Throws an [WrongExpectedEventVersion] if [EventStore.current] event number is not
  /// equal to the last event number in  [EventStore.canonicalStream]. This failure is
  /// recoverable when the store has caught up with [EventStore.canonicalStream]. Push
  /// will attempt to catchup to head of stream [maxAttempts] before giving up by
  /// throwing [WrongExpectedEventVersion].
  ///
  /// Throws an [ConflictNotReconcilable] if concurrent changes was made on same
  /// [AggregateRoot.data], which implies a manual merge must be performed.
  /// This failure is not recoverable.
  ///
  /// Throws an [SocketException] failure if calls on [EventStore.connection] fails.
  /// This failure is not recoverable.
  ///
  /// Throws [WriteFailed] for all other failures. This failure is not recoverable.
  Future<Iterable<DomainEvent>> push(T aggregate, {int maxAttempts = 10}) async {
    // Are the other aggregates with uncommitted changes?
    _assertSingleAggregateChanged(aggregate);

    try {
      return aggregate.isChanged ? await store.push(aggregate) : [];
    } on WrongExpectedEventVersion {
      // Attempt catchup to head and automatic merge until maximum attempts
      return await _reconcile(aggregate, maxAttempts);
    }
  }

  /// Attempts to reconcile conflicts between concurrent modifications
  Future<Iterable<DomainEvent>> _reconcile(T aggregate, int max) => ThreeWayMerge(this).reconcile(aggregate, max);

  /// Rollback all changes
  Iterable<Function> rollbackAll() => _aggregates.values.where((aggregate) => aggregate.isChanged).map(
        (aggregate) => rollback,
      );

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
      throw MultipleAggregatesWithChanges('Found uncommitted changes that will be lost in $other');
    }
  }

  /// Rollback all pending changes in aggregate
  Iterable<DomainEvent> rollback(T aggregate) {
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
  T get(
    String uuid, {
    Map<String, dynamic> data = const {},
    List<Map<String, dynamic>> patches = const [],
  }) =>
      _aggregates[uuid] ??
      _aggregates.putIfAbsent(
        uuid,
        () => create(
          _processors,
          uuid,
          JsonPatch.apply(data ?? {}, patches) as Map<String, dynamic>,
        )..loadFromHistory(
            store.get(uuid).map(toDomainEvent),
          ),
      );

  /// Get all aggregate roots.
  Iterable<T> getAll({
    int offset = 0,
    int limit = 20,
  }) =>
      _aggregates.values.toPage(offset: offset, limit: limit);

  /// Commit aggregate changes to local storage
  ///
  /// Returns true if changes was saved, false otherwise
  Iterable<Event> commit(T aggregate) => store.commit(aggregate);

  /// Validate data
  ///
  /// Subclasses MAY override this method to add additional validation
  ///
  /// Throws [InvalidOperation] if [Message.data] does not contain [Repository.uuidFieldName]
  @mustCallSuper
  Map<String, dynamic> prepare(S command) {
    if (command.uuid == null) {
      throw const UUIDIsNull('Field [uuid] is null');
    }
    return command is EntityCommand ? _asEntityData(command) : _asAggregateData(command);
  }

  Map<String, dynamic> _asAggregateData(S command) {
    switch (command.action) {
      case Action.create:
        if (_aggregates.containsKey(command.uuid)) {
          throw AggregateExists('Aggregate ${command.uuid} exists');
        }
        break;
      case Action.update:
      case Action.delete:
      case Action.custom:
        if (!_aggregates.containsKey(command.uuid)) {
          throw AggregateNotFound('Aggregate ${command.uuid} does not exists');
        }
        break;
    }
    return command.data;
  }

  Map<String, dynamic> _asEntityData(EntityCommand command) {
    if (!_aggregates.containsKey(command.uuid)) {
      throw AggregateNotFound('Aggregate ${command.uuid} does not exist');
    }
    final root = get(command.uuid);
    final data = Map<String, dynamic>.from(root.data);
    final array = root.asEntityArray(command.aggregateField);
    switch (command.action) {
      case Action.create:
        if (array.contains(command.entityId)) {
          throw EntityExists('Entity ${command.entityId} exists');
        }
        data[command.aggregateField] = array.patch(command.data).toList();
        break;

      case Action.update:
        if (!array.contains(command.entityId)) {
          throw EntityNotFound('Entity ${command.entityId} does not exists');
        }
        data[command.aggregateField] = array.patch(command.data).toList();
        break;

      case Action.delete:
        if (!array.contains(command.entityId)) {
          throw EntityNotFound('Entity ${command.entityId} does not exists');
        }
        data[command.aggregateField] = array.remove(command.data).toList();
        break;

      case Action.custom:
        if (!array.contains(command.entityId)) {
          throw EntityNotFound('Entity ${command.entityId} does not exists');
        }
        break;
    }
    return data;
  }
}

/// Base class for [aggregate roots](https://martinfowler.com/bliki/DDD_Aggregate.html).
///
/// The type parameter [C] is the [DomainEvent] emitted after creating this [AggregateRoot]
/// The type parameter [D] is the [DomainEvent] emitted after deleting this [AggregateRoot]
abstract class AggregateRoot<C extends DomainEvent, D extends DomainEvent> {
  @mustCallSuper
  AggregateRoot(
    this.uuid,
    Map<String, Process> processors,
    Map<String, dynamic> data, {
    this.uuidFieldName = 'uuid',
    this.entityIdFieldName = 'id',
    DateTime created,
  }) : _processors = Map.unmodifiable(processors) {
    _createdWhen = created ?? DateTime.now();
    _changedWhen = _createdWhen;
    _change(
      data ?? {},
      ops,
      typeOf<C>(),
      DateTime.now(),
      true,
    );
  }

  /// Aggregate uuid
  ///
  /// Not the same as [Message.uuid], which is unique for each [Event].
  final String uuid;

  /// Field name in [Message.data] for [AggregateRoot.uuid].
  final String uuidFieldName;

  /// Field name in [Message.data] for [EntityObject.id].
  final String entityIdFieldName;

  /// [Message] to [DomainEvent] processors
  final Map<String, Process> _processors;

  /// Aggregate root data (weak schema)
  final Map<String, dynamic> _data = {};
  Map<String, dynamic> get data => Map.unmodifiable(_data);

  /// Local uncommitted changes
  final _pending = <DomainEvent>[];

  /// [Message.uuid]s of applied events
  final _applied = <String>{};

  /// Check if event is applied
  bool isApplied(Event event) => _applied.contains(event.uuid);

  /// Get changed not committed to store
  Iterable<DomainEvent> getUncommittedChanges() => List.unmodifiable(_pending);

  /// Check if uncommitted changes exists
  bool get isNew => _applied.isEmpty;

  /// Check if uncommitted changes exists
  bool get isChanged => _pending.isNotEmpty;

  /// Get [DateTime] of when this [AggregateRoot] was created
  DateTime get createdWhen => _createdWhen;
  DateTime _createdWhen;

  /// Get [DateTime] of when this [AggregateRoot] was changed
  DateTime get changedWhen => _changedWhen;
  DateTime _changedWhen;

  /// Get [DateTime] of when this [AggregateRoot] was deleted
  DateTime get deletedWhen => _deletedWhen;
  DateTime _deletedWhen;

  /// Check if uncommitted changes exists
  bool get isDeleted => _isDeleted;
  bool _isDeleted = false;

  /// Get aggregate uuid from event
  String toAggregateUuid(Event event) => event.data[uuidFieldName] as String;

  /// Load events from history.
  @protected
  AggregateRoot loadFromHistory(Iterable<DomainEvent> events) {
    // Only clear if history exist, otherwise keep the event from construction
    if (events.isNotEmpty) {
      _data.clear();
      _pending.clear();
      _applied.clear();
    }
    events?.forEach((event) => _apply(
          event,
          isChanged: false,
          isNew: false,
        ));
    return this;
  }

  /// Patch [AggregateRoot.data] with given [data].
  ///
  /// This method only applies the following JSON Patch methods:
  /// * [JSON Patch add method](https://tools.ietf.org/html/rfc6902#section-4.1)
  /// * [JSON Patch remove method](https://tools.ietf.org/html/rfc6902#section-4.2)
  /// * [JSON Patch replace method](https://tools.ietf.org/html/rfc6902#section-4.3)
  /// * [JSON Patch move method](https://tools.ietf.org/html/rfc6902#section-4.4)
  ///
  /// Returns a [DomainEvent] if data was changed, null otherwise.
  DomainEvent patch(
    Map<String, dynamic> data, {
    @required Type emits,
    DateTime timestamp,
    List<String> ops = ops,
  }) =>
      _change(data, ops, emits, timestamp, isNew);

  static const ops = ['add', 'replace', 'move'];

  DomainEvent _change(
    Map<String, dynamic> data,
    List<String> ops,
    Type emits,
    DateTime timestamp,
    bool isNew,
  ) {
    // Remove all unsupported operations
    final patches = JsonPatch.diff(_data, data)..removeWhere((diff) => !ops.contains(diff['op']));
    return isNew || patches.isNotEmpty
        ? _apply(
            _changed(
              data,
              emits: emits,
              patches: patches,
              timestamp: timestamp,
            ),
            isChanged: true,
            isNew: isNew,
          )
        : null;
  }

  // TODO: Add support for detecting tombstone (delete) events
  /// Delete aggregate root
  DomainEvent delete() => _apply(
        _deleted(),
        isChanged: true,
        isNew: false,
      );

  /// Get uncommitted changes and clear internal cache
  Iterable<DomainEvent> commit() {
    final changes = _pending.toList();
    _pending.clear();
    _applied.addAll(changes.map((e) => e.uuid));
    return changes;
  }

  /// Get aggregate updated event.
  ///
  /// Invoked from [Repository], SHOULD NOT be overridden
  @protected
  DomainEvent _changed(
    Map<String, dynamic> data, {
    Type emits,
    DateTime timestamp,
    List<Map<String, dynamic>> patches = const [],
  }) =>
      _process(
        uuid,
        emits,
        _asDataPatch(
          patches: patches,
        ),
        timestamp,
      );

  /// Get aggregate deleted event. Invoked from [Repository]
  @protected
  DomainEvent _deleted() => _process(
        uuid,
        typeOf<D>(),
        _asDataPatch(
          deleted: true,
        ),
        DateTime.now(),
      );

  Map<String, dynamic> _asDataPatch({
    List<Map<String, dynamic>> patches = const [],
    bool deleted = false,
  }) =>
      {
        uuidFieldName: uuid,
        'patches': patches,
        'deleted': deleted,
      };

  DomainEvent _process(
    String uuid,
    Type emits,
    Map<String, dynamic> data,
    DateTime timestamp,
  ) {
    final process = _processors['$emits'];
    if (process != null) {
      return process(Message(
        uuid: Uuid().v4(),
        type: '$emits',
        data: data,
        created: timestamp,
      ));
    }
    throw InvalidOperation('Message ${emits} not recognized');
  }

  /// Apply change to [data].
  ///
  /// This will be applied directly.
  void apply(DomainEvent event) => _apply(
        event,
        isChanged: false,
        isNew: false,
      );

  // Apply implementation for internal use
  DomainEvent _apply(
    DomainEvent event, {
    bool isChanged,
    bool isNew,
  }) {
    if (toAggregateUuid(event) != uuid) {
      throw InvalidOperation(
        'Aggregate has $uuid, '
        'event $event contains ${toAggregateUuid(event)}',
      );
    }

    // Already applied?
    if (_applied.contains(event.uuid)) {
      return event;
    }

    // Set timestamps
    if (_applied.isEmpty || isNew) {
      _createdWhen = event.created;
      _changedWhen = _createdWhen;
    } else {
      _changedWhen = event.created;
    }

    // Applying events in order is REQUIRED for this to work!
    if (event.isDeleted) {
      _isDeleted = true;
      _deletedWhen = event.created;
    } else {
      final patches = event.patches;
      if (patches.isNotEmpty) {
        final next = JsonPatch.apply(
          _data,
          patches,
          strict: false,
        ) as Map<String, dynamic>;
        _data.clear();
        _data.addAll(next);
      }
    }
    if (isChanged) {
      _pending.add(event);
    } else {
      _applied.add(event.uuid);
    }

    return event;
  }

  /// Get array of value objects
  List<T> asValueArray<T>(String field) => List<T>.from(data[field] as List);

  /// Get array of [EntityObject]
  EntityArray asEntityArray(String field) => EntityArray.from(field, _ensureList(field));

  AggregateRoot _ensureList(String field) {
    _data.putIfAbsent(field, () => []);
    return this;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AggregateRoot && runtimeType == other.runtimeType && uuid == other.uuid;

  @override
  int get hashCode => uuid.hashCode;

  @override
  String toString() {
    return '$runtimeType{$uuidFieldName: $uuid}';
  }
}

/// This class implements validated entity object array operations
class EntityArray {
  EntityArray(
    this.aggregateField,
    this.entityIdFieldName,
    Map<String, dynamic> data,
  ) : data = Map.from(data);

  factory EntityArray.from(String field, AggregateRoot root) => EntityArray(
        field,
        root.entityIdFieldName,
        _verify(field, root.data),
      );

  final String aggregateField;
  final String entityIdFieldName;
  final Map<String, dynamic> data;

  int get length => _asArray().length;
  bool get isEmpty => _asArray().isEmpty;
  bool get isNotEmpty => _asArray().isNotEmpty;

  /// Check if id exists
  bool contains(String id) => _asArray().any((data) => _toId(data) == id);

  /// Next EntityObject id.
  ///
  /// Starts at value `1`
  String get nextId => '${_asArray().where(
        (data) => _toId(data) is int,
      ).fold<int>(0, (next, data) => max(next, _toId(data) as int)) + 1}';

  /// Get [EntityObject.data] as [List]
  List<Map<String, dynamic>> toList() => _asArray().toList();

  /// Get [data] as next [EntityObject] in this array
  EntityObject nextObject(Map<String, dynamic> data, {String id}) {
    final actual = id ?? nextId;
    final next = Map<String, dynamic>.from(data);
    next[entityIdFieldName] = id;
    return EntityObject(actual, next, entityIdFieldName);
  }

  /// Add entity to array.
  ///
  /// Id must be unique if given. Throws [EntityExists] if id exists already
  EntityArray add(Map<String, dynamic> data, {String id}) {
    final actual = id ?? nextId;
    final entities = _asArray();
    final entity = Map<String, dynamic>.from(data);
    if (entities.where((data) => _toId(data) == actual).isNotEmpty) {
      throw EntityExists('Entity $actual exists');
    }
    entity[entityIdFieldName] = actual;
    final array = entities.toList();
    array.add(entity);
    return _fromArray(array);
  }

  /// Add entity if not found, replace existing otherwise.
  ///
  /// If entity was not found, id must be unique if given or else [EntityExists] is thrown.
  EntityArray patch(Map<String, dynamic> data, {String id}) {
    final id = _toId(data);
    final array = _asArray().toList();
    final current = array.indexWhere((data) => _toId(data) == id);
    if (current == -1) {
      array.add(data);
    } else {
      array[current] = data;
    }
    return _fromArray(array);
  }

  /// Remove [EntityObject] with [EntityObject.data]
  EntityArray remove(Map<String, dynamic> data) {
    final id = _toId(data);
    final array = _asArray().toList()
      ..removeWhere(
        (data) => _toId(data) == id,
      );
    return _fromArray(array);
  }

  EntityArray _fromArray(List<Map<String, dynamic>> array) {
    final root = Map<String, dynamic>.from(data);
    root[aggregateField] = array;
    return EntityArray(aggregateField, entityIdFieldName, root);
  }

  /// Get [EntityObject] with given [id]
  EntityObject elementAt(String id) => this[id];

  /// Set entity object with given [id]
  void operator []=(String id, EntityObject entity) {
    final data = entity.data;
    data[entityIdFieldName] = id;
    final array = _asArray().toList();
    final current = array.indexWhere((data) => _toId(data) == id);
    if (current == -1) {
      array.add(data);
    } else {
      array[current] = data;
    }
    data[aggregateField] = array;
  }

  /// Get entity object with given [id]
  EntityObject operator [](String id) {
    final found = _asArray().where(
      (data) => (data[entityIdFieldName] as String) == id,
    );
    if (found.isEmpty) {
      throw EntityNotFound('Entity $id not found');
    }
    return EntityObject(id, found.first, entityIdFieldName);
  }

  String _toId(Map<String, dynamic> data) {
    if (data[entityIdFieldName] is String) {
      return data[entityIdFieldName] as String;
    }
    throw ArgumentError(
      'Field data[${entityIdFieldName}] is not a String: '
      'is type: ${data[entityIdFieldName]?.runtimeType}',
    );
  }

  List<Map<String, dynamic>> _asArray() {
    return List.from(data[aggregateField] as List<dynamic>);
  }

  static Map<String, dynamic> _verify(String field, Map<String, dynamic> data) {
    if (data[field] is List<dynamic> == false) {
      throw ArgumentError(
        'Field data[$field] is not an array of json objects: '
        'is type: ${data[field]?.runtimeType}',
      );
    }
    return data;
  }
}

class EntityObject {
  EntityObject(this.id, this.data, this.idFieldName);

  /// Entity id
  final String id;

  /// Field name in [Message.data] for [EntityObject.id].
  final String idFieldName;

  /// Entity object data (weak schema)
  Map<String, dynamic> data;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is EntityObject && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

extension IterableX<T> on Iterable<T> {
  Iterable<T> toPage({
    int offset = 0,
    int limit = 20,
  }) {
    if (offset < 0 || limit < 0) {
      throw const InvalidOperation('Offset and limit can not be negative');
    } else if (offset > length) {
      throw InvalidOperation('Index out of bounds: offset $offset > length $length');
    } else if (offset == 0 && limit == 0) {
      return toList();
    }
    return skip(offset).take(limit);
  }
}

/// Class for implementing a strategy for merging concurrent modifications
abstract class MergeStrategy<T extends AggregateRoot> {
  MergeStrategy(this.repository);
  Repository<Command, T> repository;

  Future<Iterable<DomainEvent>> merge(T aggregate);
  Future<Iterable<DomainEvent>> reconcile(T aggregate, int max) => _reconcileWithRetry(aggregate, max, 1);
  Future<Iterable<DomainEvent>> _reconcileWithRetry(T aggregate, int max, int attempt) async {
    try {
      // Keep local state and rollback
      final events = await merge(aggregate);
      // Reapply events as local changes
      events.forEach((event) => aggregate._apply(
            event,
            isChanged: true,
            isNew: false,
          ));
      return repository.push(aggregate);
    } on WrongExpectedEventVersion catch (e, stacktrace) {
      // Try again?
      if (attempt < max) {
        return _reconcileWithRetry(aggregate, max, attempt + 1);
      }
      repository.logger.warning('Aborted automatic merge after $max retries: $e with stacktrace: $stacktrace');
      rethrow;
    }
  }
}

/// Implements a three-way merge algorithm of concurrent modifications
class ThreeWayMerge<T extends AggregateRoot> extends MergeStrategy<T> {
  ThreeWayMerge(Repository<Command<DomainEvent>, T> repository) : super(repository);

  @override
  Future<Iterable<DomainEvent>> merge(T aggregate) async {
    final local = aggregate.data;
    final events = repository.rollback(aggregate);

    // Keep base state and catchup to remote state
    final base = aggregate.data;
    final count = await repository.store.catchUp(repository);
    repository.logger.info('Caught up with $count events from ${repository.store.canonicalStream}');

    // Get local and remote patches
    final remote = aggregate.data;
    final head = JsonPatch.diff(base, remote);
    final mine = JsonPatch.diff(base, local);
    final yours = head.map((op) => op['path']);
    final concurrent = mine.where((op) => yours.contains(op['path']));

    // Automatic merge not possible?
    if (concurrent.isNotEmpty) {
      // Check if operations are the same on both sides
      final eq = const MapEquality().equals;
      final conflicts = concurrent.where(
        (op1) => head.where((op2) => op2['path'] == op1['path'] && !eq(op1, op2)).isNotEmpty,
      );
      // Conflicting operations found?
      if (conflicts.isNotEmpty) {
        throw ConflictNotReconcilable(
          'Unable to reconcile ${conflicts.length} conflicts',
          local: conflicts.map((op) => op['path']).map((path) => head.firstWhere((op) => op['path'] == path)),
          remote: conflicts,
        );
      }
    }
    return events;
  }
}