import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:event_source/event_source.dart';
import 'package:http/http.dart';
import 'package:json_patch/json_patch.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';

import 'bus.dart';
import 'core.dart';
import 'error.dart';
import 'extension.dart';
import 'rule.dart';
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
    Repository<Command, T> Function(EventStore store) create, {
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

  Timer _timer;

  /// Prepare projections required by repositories that uses instance streams
  ///
  /// Throws an [ProjectionNotAvailable] if one
  /// or more [EventStore.useInstanceStreams] are
  /// true and system projection
  /// [$by_category](https://eventstore.org/docs/projections/system-projections/index.html?tabs=tabid-5#by-category)
  ///  is not available.
  Future prepare({
    List<String> withProjections = const [],
    int maxAttempts = 10,
    Duration maxBackoffTime = const Duration(seconds: 10),
  }) async {
    if (_timer != null) {
      throw InvalidOperation('Build is pending');
    }
    final projections = Set<String>.from(withProjections);
    if (_stores.values.any(
      (store) => store.useInstanceStreams,
    )) {
      projections.add('\$by_category');
    }
    final completer = Completer();
    _prepareWithRetries(projections, maxAttempts, 0, maxBackoffTime, completer);
    return completer.future;
  }

  void _prepareWithRetries(
    Iterable<String> projections,
    int max,
    int attempt,
    Duration maxBackoffTime,
    Completer completer,
  ) async {
    final backlog = projections.toSet();
    try {
      await Future.wait(
        backlog.map((command) => _prepare(command)),
        cleanUp: (prepared) => backlog.removeAll(prepared),
      );
      _timer?.cancel();
      _timer = null;
      completer.complete();
    } on Exception catch (e, stackTrace) {
      if (attempt < max) {
        final wait = toNextTimeout(attempt++, maxBackoffTime, exponent: 8);
        logger.info('Wait ${wait}ms before retrying prepare again (attempt: $attempt)');
        _timer?.cancel();
        _timer = Timer(
          Duration(milliseconds: wait),
          () => _prepareWithRetries(backlog, max, attempt, maxBackoffTime, completer),
        );
      } else {
        completer.completeError(
          ProjectionNotAvailable(
            'Failed to prepare projections $backlog with error: $e: $stackTrace',
          ),
          StackTrace.current,
        );
      }
    } on Error catch (e, stackTrace) {
      completer.completeError(e, stackTrace);
    }
  }

  /// Check if projections are enabled
  Future _prepare(String projection) async {
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

  /// Build all repositories from event stores
  ///
  /// Throws an [RepositoryNotAvailable] if one
  /// or more [Repository] instances failed to build.
  ///
  /// Returns number of events processed
  Future<int> build({
    int maxAttempts = 10,
    Duration maxBackoffTime = const Duration(seconds: 10),
  }) async {
    if (_timer != null) {
      logger.severe('Build not allowed, prepare is pending');
      throw InvalidOperation('Build not allowed, prepare is pending');
    }
    final completer = Completer<int>();
    _buildWithRetries(
      _stores.keys,
      maxAttempts,
      0,
      maxBackoffTime,
      completer,
    );
    return completer.future;
  }

  void _buildWithRetries(
    Iterable<Repository> repositories,
    int max,
    int attempt,
    Duration maxBackoffTime,
    Completer<int> completer,
  ) async {
    final backlog = repositories.toSet();
    try {
      final counts = await Future.wait<int>(
        repositories.map(
          (repository) => repository.build(),
        ),
      );
      _timer?.cancel();
      _timer = null;
      final processed = counts.fold<int>(0, (processed, count) => processed + count);
      completer.complete(Future.value(
        processed,
      ));
    } on Exception catch (e, stackTrace) {
      if (attempt < max) {
        backlog.removeWhere((repo) => repo.isReady);
        final wait = toNextTimeout(attempt++, maxBackoffTime, exponent: 8);
        logger.info('Wait ${wait}ms before retrying build again (attempt: $attempt)');
        _timer?.cancel();
        _timer = Timer(
          Duration(milliseconds: wait),
          () => _buildWithRetries(backlog, max, attempt, maxBackoffTime, completer),
        );
      } else {
        completer.completeError(
          ProjectionNotAvailable(
            'Failed to build repositories ${backlog.map((repo) => repo.aggregateType)} with error: $e: $stackTrace',
          ),
          StackTrace.current,
        );
      }
    } on Error catch (e, stackTrace) {
      completer.completeError(e, stackTrace);
    }
  }

  /// Get [Repository] from [Type]
  T get<T extends Repository>() {
    final items = _stores.keys.whereType<T>();
    return items.isEmpty ? null : items.first;
  }

  bool _isPaused = false;
  bool get isPaused => _isPaused;

  /// Pause all subscriptions
  void pause() async {
    if (!_isPaused) {
      _isPaused = true;
      _stores.values.forEach(
        (store) => store.pause(),
      );
      logger.info('Paused ${_stores.length} subscriptions');
    }
  }

  /// Resume all subscriptions
  void resume() async {
    if (_isPaused) {
      _isPaused = false;
      _stores.values.forEach(
        (store) => store.resume(),
      );
      logger.info('Resumed ${_stores.length} subscriptions');
    }
  }

  /// Dispose all [RepositoryManager] instances
  Future dispose() async {
    try {
      await Future.forEach<EventStore>(
        _stores.values,
        (store) => store.dispose(),
      );
    } on ClientException catch (e, stackTrace) {
      logger.warning(
        'Failed to dispose one or more stores: error: $e, stacktrace: $stackTrace',
      );
    }
    _stores.clear();
  }
}

/// [Message] type name to [DomainEvent] processor method
typedef ProcessCallback = DomainEvent Function(Message change);

/// Repository or [AggregateRoot]s as the single responsible for all transactions on each aggregate
abstract class Repository<S extends Command, T extends AggregateRoot>
    implements CommandHandler<S>, MessageHandler<DomainEvent> {
  /// Internal - for local debugging
  bool debugConflicts = false;

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
    @required Map<Type, ProcessCallback> processors,
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
  bool get isReady => _ready;

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
  final Map<String, ProcessCallback> _processors;
  Map<String, ProcessCallback> get processors => Map.unmodifiable(_processors);

  /// Map of aggregate roots
  final Map<String, T> _aggregates = {};
  Iterable<T> get aggregates => List.unmodifiable(_aggregates.values);

  /// Get number of aggregates
  int count({bool deleted = false}) => _aggregates.values.where((test) => deleted || !test.isDeleted).length;

  /// Get aggregate uuid from event
  String toAggregateUuid(Event event) => event.data[uuidFieldName] as String;

  /// Create aggregate root with given id. Should only called from within [Repository].
  @protected
  @visibleForOverriding
  T create(Map<String, ProcessCallback> processors, String uuid, Map<String, dynamic> data);

  /// Check given aggregate root exists.
  /// An aggregate exists IFF it repository contains it and it is not deleted
  bool exists(String uuid) => _aggregates.containsKey(uuid) && !_aggregates[uuid].isDeleted;

  /// Check if repository contains given aggregate root
  bool contains(String uuid) => _aggregates.containsKey(uuid);

  /// Build repository from local events.
  /// Returns number of events processed.
  Future<int> build() async {
    final count = await replay();
    subscribe();
    willStartProcessingEvents();
    _ready = true;
    return count;
  }

  /// Replay events into this [Repository]
  /// Returns number of events processed.
  Future<int> replay() async {
    final events = await store.replay<T>(this);
    if (events == 0) {
      logger.info("Stream '${store.canonicalStream}' is empty");
    } else {
      logger.info('Repository loaded with ${_aggregates.length} aggregates');
    }
    return events;
  }

  /// Subscribe this [source] to compete for changes from [store]
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

  /// Subscribe this [source] to receive all changes from [store]
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
    final process = _processors['${event.type}'];
    if (process != null) {
      final uuid = toAggregateUuid(event);

      // Check if event is already applied
      final aggregate = _aggregates[uuid];
      if (aggregate?.isApplied(event) == true) {
        final applied = aggregate.getApplied(event.uuid);
        if (applied?.created == event.created) {
          return aggregate.getApplied(event.uuid);
        }
      }

      // Get base if exists
      final base = event.mapAt<String, dynamic>('previous') ?? aggregate?.data;

      // Prepare REQUIRED fields
      final patches = event.listAt<Map<String, dynamic>>('patches');
      final changed = event.mapAt<String, dynamic>('changed') ??
          JsonUtils.apply(
            aggregate?.data ?? {},
            patches,
          );
      assert(patches != null, 'Patches can not be null');
      assert(changed != null, 'Changed can not be null');

      return process(
        Message(
          uuid: event.uuid,
          type: event.type,
          local: event.local,
          created: event.created,
          data: DomainEvent.toData(
            uuid,
            uuidFieldName,
            previous: base,
            patches: patches,
            changed: changed,
            index: event.elementAt<int>('index'),
            deleted: event.elementAt<bool>('deleted') ?? aggregate?.isDeleted,
          ),
        ),
      );
    }
    final message = 'Message ${event.type} not recognized';
    logger.severe(message);
    throw InvalidOperation(message);
  }

  /// [DomainEvent] type to constraint definitions
  final Map<Type, List<RuleBuilder>> _rules = {};
  final StreamController<Event> _ruleController = StreamController.broadcast();

  /// Get stream of rule results
  Stream<Event> get onRuleResult => _ruleController.stream;

  /// Register rule (invariant) for given DomainEvent [E]
  void rule<E extends DomainEvent>(RuleBuilder builder, {bool unique = false}) {
    final type = typeOf<E>();
    if (unique && _rules.containsKey(type)) {
      final message = 'Rule for event $type already registered';
      logger.severe(message);
      throw InvalidOperation(message);
    }
    final builders = _rules.update(
      type,
      (builders) => builders..add(builder),
      ifAbsent: () => [builder],
    );
    if (builders.length == 1) {
      store.bus.register<E>(this);
    }
  }

  @override
  void handle(DomainEvent message) async {
    if (message.local && _rules.isNotEmpty) {
      try {
        final builders = _rules[message.runtimeType];
        if (builders?.isNotEmpty == true) {
          builders.forEach((builder) async {
            final handler = builder(this);
            final events = await handler(message);
            events?.forEach(_ruleController.add);
          });
        }
      } catch (e, stackTrace) {
        logger.severe(
          'Failed to enforce invariant for $message in $runtimeType, failed with: $e, stackTrace: $stackTrace',
        );
      }
    }
  }

  /// Force a catch-up against head of [EventStore.canonicalStream]
  Future<int> catchUp() => store.catchUp(this);

  /// Execute command on given aggregate root.
  ///
  /// Throws an [InvalidOperation] exception if [prepare] on [command] fails.
  ///
  /// Throws an [WrongExpectedEventVersion] if [EventStore.current] event number is not
  /// equal to the last event number in  [EventStore.canonicalStream]. This failure is
  /// recoverable when the store has caught up with [EventStore.canonicalStream]. Push
  /// will attempt to catchup to head of stream [maxAttempts] before giving up by
  /// throwing [WrongExpectedEventVersion].
  ///
  /// Throws an [ConflictNotReconcilable] if concurrent changes was made on same
  /// [AggregateRoot.data], which implies a manual merge must be performed by then
  /// consumer. This failure is not recoverable.
  ///
  /// Throws an [SocketException] failure if calls on [EventStore.connection] fails.
  /// This failure is not recoverable.
  ///
  /// Throws [WriteFailed] for all other failures. This failure is not recoverable.
  @override
  FutureOr<Iterable<DomainEvent>> execute(S command, {int maxAttempts = 10}) async {
    T aggregate;
    final changes = <DomainEvent>[];
    if (command.uuid == null) {
      throw UUIDIsNull('Field [${command.uuidFieldName}] is null in $command');
    }
    final exists = contains(command.uuid);
    if (command is EntityCommand) {
      final next = _asEntityData(command);
      aggregate = get(command.uuid);
      if (!exists) {
        changes.addAll(aggregate.getUncommittedChanges());
      }
      changes.add(aggregate.patch(
        Map<String, dynamic>.from(next['data']),
        index: next['index'] as int,
        emits: command.emits,
        timestamp: command.created,
        previous: Map<String, dynamic>.from(next['previous']),
      ));
    } else {
      final data = _asAggregateData(command);
      switch (command.action) {
        case Action.create:
          aggregate = get(command.uuid, data: data);
          changes.addAll(aggregate.getUncommittedChanges());
          break;
        case Action.update:
          aggregate = get(command.uuid);
          changes.add(aggregate.patch(
            data,
            emits: command.emits,
            timestamp: command.created,
          ));
          break;
        case Action.delete:
          aggregate = get(command.uuid);
          changes.add(aggregate.delete(
            timestamp: command.created,
          ));
          break;
      }
    }
    return aggregate.isChanged
        ? await _schedulePush(
            aggregate.uuid,
            changes,
            maxAttempts,
          )
        : <DomainEvent>[];
  }

  /// Check if this [Repository] contains any aggregates with [AggregateRoot.isChanged]
  bool get isChanged => _aggregates.values.any((aggregate) => aggregate.isChanged);

  /// Check if [Repository] is processing changes
  bool get isProcessing => _pushQueue.isNotEmpty;

  /// Push aggregate changes to remote storage
  ///
  /// Scheduling multiple push operations without waiting for the result
  /// will throw a [ConcurrentWriteOperation] exception. This prevents
  /// partial writes and commits which will result in an [EventNumberMismatch]
  /// being thrown by the [EventStoreConnection].
  ///
  /// Throws an [WrongExpectedEventVersion] if [EventStore.current] event number is not
  /// equal to the last event number in [EventStore.canonicalStream] after [maxAttempts]
  /// of catching up with [EventStore.canonicalStream].
  ///
  /// Throws an [ConflictNotReconcilable] if concurrent changes was made on same
  /// [AggregateRoot.data], which implies a manual merge must be performed.
  /// This failure is not recoverable.
  ///
  /// Throws an [AggregateNotFound] if an [AggregateRoot.uuid] is not found in this
  /// [Repository]. This failure is not recoverable. If one is found the instance
  /// in this repository is pushed, not the instance given.
  ///
  /// Throws an [SocketException] failure if calls on [EventStore.connection] fails.
  /// This failure is not recoverable.
  ///
  /// Throws [WriteFailed] for all other failures. This failure is not recoverable.
  Future<Iterable<DomainEvent>> push(T aggregate, {int maxAttempts = 10}) {
    return aggregate.isChanged
        ? _schedulePush(
            aggregate.uuid,
            aggregate.getUncommittedChanges(),
            maxAttempts,
          )
        : <DomainEvent>[];
  }

  /// Queue of push operations performed in FIFO manner.
  ///
  /// Multiple attempts might be required until it is completed due to
  /// [WrongExpectedEventVersion] exceptions thrown by [EventStoreConnection].
  ///
  /// Each push is an async operation. If a push is invoked
  /// concurrently with multiple remote push operations and it fails with
  /// [WrongExpectedEventVersion] (a concurrent modification has occurred),
  /// the [MergeStrategy] will attempt to reconcile by preforming a catchup
  /// to head of stream before an second push is scheduled for async execution.
  ///
  /// Scheduling multiple push operations without waiting for the result
  /// will throw a [ConcurrentWriteOperation] exception. This prevents
  /// partial writes and commits which will result in an [EventNumberMismatch]
  /// being thrown by the [EventStoreConnection].
  final _pushQueue = ListQueue<_PushOperation>();

  /// Schedule [_PushOperation] for execution
  Future<Iterable<DomainEvent>> _schedulePush(
    String uuid,
    Iterable<DomainEvent> changes,
    int maxAttempts,
  ) {
    final aggregate = _assertExists(uuid);
    final operation = _PushOperation(aggregate, changes, maxAttempts);
    if (_pushQueue.isEmpty) {
      // Process LATER but BEFORE any asynchronous
      // events like Future, Timer or DOM Event
      scheduleMicrotask(_processPushQueue);
    }
    _pushQueue.add(operation);
    return operation.completer.future;
  }

  T _assertExists(String uuid) {
    final aggregate = _aggregates[uuid];
    if (aggregate == null) {
      throw AggregateNotFound('Aggregate $aggregateType $uuid not found');
    }
    return aggregate;
  }

  /// Execute push operations in FIFO-manner until empty
  void _processPushQueue() async {
    while (_pushQueue.isNotEmpty) {
      final operation = await _push(_pushQueue.first);
      _pushQueue.remove(operation);
    }
  }

  Future<_PushOperation> _push(_PushOperation operation) async {
    final aggregate = operation.aggregate;
    try {
      if (debugConflicts) {
        logger.info('Push > ${aggregate.runtimeType} ${store.toInstanceStream(aggregate.uuid)}');
        logger.info('events: ${store.events.values.fold(0, (count, events) => count + events.length)}');
        logger.info('pending: ${aggregate.getUncommittedChanges().length}');
        logger.info('instanceEventNumber: ${store.current(uuid: aggregate.uuid)}');
        logger.info('expectedEventNumber: ${store.toExpectedVersion(store.toInstanceStream(aggregate.uuid)).value}');
        logger.info('canonicalEventNumber: ${store.current(stream: store.canonicalStream)}');
      }
      await store.push(aggregate);

      // Only return changes applied by this operation
      operation.completer.complete(operation.changes);

      if (debugConflicts) {
        logger.info('---DONE---');
        logger.info('events: ${store.events.values.fold(0, (count, events) => count + events.length)}');
        logger.info('instanceEventNumber: ${store.current(uuid: aggregate.uuid)}');
        logger.info('canonicalEventNumber: ${store.current(stream: store.canonicalStream)}');
      }
    } on WrongExpectedEventVersion {
      return _reconcile(operation);
    } catch (e, stackTrace) {
      operation.completer.completeError(e, stackTrace);
      logger.severe(
        'Failed to push aggregate $aggregate: $e, stacktrace: $stackTrace',
      );
      logger.severe(toDebugString());
    }
    return operation;
  }

  /// Attempts to reconcile conflicts between concurrent modifications
  Future<_PushOperation> _reconcile(_PushOperation operation) async {
    final aggregate = operation.aggregate;
    if (debugConflicts) {
      logger.info('---CONFLICT---');
      logger.info('$e');
      logger.info('$aggregate');
      logger.info('---DEBUG---');
      logger.info(toDebugString());
    } // Attempt to automatic merge until maximum attempts
    try {
      final events = await ThreeWayMerge(this).reconcile(
        aggregate,
        operation.maxAttempts,
      );
      operation.completer.complete(events);
    } on ConflictNotReconcilable catch (e, stackTrace) {
      operation.completer.completeError(e, stackTrace);
    } catch (e, stackTrace) {
      operation.completer.completeError(e, stackTrace);
      logger.severe(
        'Failed to push aggregate $aggregate: $e, stacktrace: $stackTrace',
      );
      logger.severe(toDebugString());
    }
    return operation;
  }

  /// Rollback all changes
  Iterable<Function> rollbackAll() => _aggregates.values.where((aggregate) => aggregate.isChanged).map(
        (aggregate) => rollback,
      );

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
  /// Will by default create a new aggregate if not found by
  /// applying a left fold from [SourceEvent] to [DomainEvent].
  /// Each [DomainEvent] is then processed by applying changes
  /// to [AggregateRoot.data] in accordance to the business value
  /// of to each [DomainEvent].
  T get(
    String uuid, {
    Map<String, dynamic> data = const {},
    List<Map<String, dynamic>> patches = const [],
    bool createNew = true,
  }) =>
      _aggregates[uuid] ??
      (createNew
          ? _aggregates.putIfAbsent(
              uuid,
              () => create(
                _processors,
                uuid,
                JsonPatch.apply(data ?? {}, patches) as Map<String, dynamic>,
              )..loadFromHistory(
                  store.get(uuid).map(toDomainEvent),
                ),
            )
          : null);

  /// Get all aggregate roots.
  Iterable<T> getAll({int offset = 0, int limit = 20, bool deleted = false}) =>
      _aggregates.values.where((test) => deleted || !test.isDeleted).toPage(
            offset: offset,
            limit: limit,
          );

  Map<String, dynamic> _asAggregateData(S command) {
    switch (command.action) {
      case Action.create:
        if (_aggregates.containsKey(command.uuid)) {
          throw AggregateExists('${typeOf<T>()} ${command.uuid} exists');
        }
        break;
      case Action.update:
      case Action.delete:
        if (!_aggregates.containsKey(command.uuid)) {
          throw AggregateNotFound('${typeOf<T>()} ${command.uuid} does not exists');
        }
        break;
    }
    return command.data;
  }

  Map<String, dynamic> _asEntityData(EntityCommand command) {
    if (!_aggregates.containsKey(command.uuid)) {
      throw AggregateNotFound('${typeOf<T>()} ${command.uuid} does not exist');
    }
    var index;
    final data = {};
    final root = get(command.uuid);
    final array = root.asEntityArray(
      command.aggregateField,
      entityIdFieldName: command.entityIdFieldName,
    );
    switch (command.action) {
      case Action.create:
        if (array.contains(command.entityId)) {
          throw EntityExists('Entity ${command.aggregateField} ${command.entityId} exists');
        }
        var id = command.entityId ?? array.nextId;
        final entities = array.add(command.data, id: id);
        index = entities.indexOf(id);
        data[command.aggregateField] = entities.toList();
        break;

      case Action.update:
        if (!array.contains(command.entityId)) {
          throw EntityNotFound('Entity ${command.entityId} does not exists');
        }
        index = array.indexOf(command.entityId);
        final entities = array.patch(command.data);
        data[command.aggregateField] = entities.toList();
        break;

      case Action.delete:
        if (!array.contains(command.entityId)) {
          throw EntityNotFound('Entity ${command.aggregateField} ${command.entityId} does not exists');
        }
        index = array.indexOf(command.entityId);
        final entities = array.remove(command.entityId);
        data[command.aggregateField] = entities.toList();
        break;
    }
    return {
      'data': data,
      'index': index,
      'previous': {
        command.aggregateField: array.toList(),
      },
    };
  }

  String toDebugString() => '$runtimeType: {'
      'ready: $isReady, '
      'count: ${count()}, '
      'canonicalStream: ${store.canonicalStream}}, '
      'aggregates: {${_aggregates.values.map((value) => '{'
          'uuid: ${value.uuid}, '
          'instanceStream: ${store.toInstanceStream(value.uuid)}, '
          'currentEventNumber: ${store.current(uuid: value.uuid)}, '
          '}').join(', ')}}';
}

class _PushOperation {
  _PushOperation(
    this.aggregate,
    this.changes,
    this.maxAttempts,
  ) : offset = aggregate.modifications;
  final int offset;
  final int maxAttempts;
  final AggregateRoot aggregate;
  final Iterable<DomainEvent> changes;
  final completer = Completer<Iterable<DomainEvent>>();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _PushOperation && runtimeType == other.runtimeType && aggregate.uuid == other.aggregate.uuid;

  @override
  int get hashCode => aggregate.uuid.hashCode;

  @override
  String toString() {
    return '{'
        'changes: ${changes.map((e) => '${e.type}: ${e.uuid}')}, '
        'aggregate: {'
        'uuid: ${aggregate.uuid}, '
        'modifications: ${aggregate.modifications}, '
        'pending: ${aggregate._pending.map((e) => '${e.type}: ${e.uuid}')}}'
        '}';
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
    Map<String, ProcessCallback> processors,
    Map<String, dynamic> data, {
    this.uuidFieldName = 'uuid',
    this.entityIdFieldName = 'id',
    DateTime created,
  }) : _processors = Map.from(processors) {
    _createdBy = _change(
      data ?? {},
      ops,
      typeOf<C>(),
      created ?? DateTime.now(),
      true,
    );
    _changedBy = _createdBy;
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
  final Map<String, ProcessCallback> _processors;

  /// Aggregate root data (weak schema)
  final Map<String, dynamic> _data = {};
  Map<String, dynamic> get data => Map.from(_data);

  /// Get element at given path
  T elementAt<T>(String path) => _data.elementAt(path) as T;

  /// Get number of modifications since creations
  ///
  /// Number of modifications is the sum of
  /// applied and pending events
  int get modifications => _applied.length + _pending.length;

  /// Local uncommitted changes
  final _pending = <DomainEvent>[];

  /// [Message.uuid]s of applied events
  final _applied = <String, DomainEvent>{};

  /// Get uuids of applied events
  Iterable<DomainEvent> get applied => List.from(_applied.values);

  /// Check if event is applied
  bool isApplied(Event event) => _applied.containsKey(event.uuid);

  /// Check if event is applied
  DomainEvent getApplied(String uuid) => _applied[uuid];

  /// Get changed not committed to store
  Iterable<DomainEvent> getUncommittedChanges() => List.from(_pending);

  /// Check if uncommitted changes exists
  bool get isNew => _applied.isEmpty;

  /// Check if uncommitted changes exists
  bool get isChanged => _pending.isNotEmpty;

  /// Get [DomainEvent] that created this aggregate
  DomainEvent get createdBy => _createdBy;
  DomainEvent _createdBy;

  /// Get [DateTime] of when this [AggregateRoot] was created
  DateTime get createdWhen => _createdBy?.created;

  /// Get [DomainEvent] that last changed this aggregate
  DomainEvent get changedBy => _changedBy;
  DomainEvent _changedBy;

  /// Get [DateTime] of when this [AggregateRoot] was changed
  DateTime get changedWhen => _changedBy?.created;

  /// Get [DomainEvent] that deleted this aggregate
  DomainEvent get deletedBy => _deletedBy;
  DomainEvent _deletedBy;

  /// Get [DateTime] of when this [AggregateRoot] was deleted
  DateTime get deletedWhen => _deletedBy?.created;

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
      _clear();
    }
    events?.forEach((event) => _apply(
          event,
          isChanged: false,
        ));
    return this;
  }

  /// Clear to initial state
  void _clear() {
    _data.clear();
    _pending.clear();
    _applied.clear();
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
    int index,
    DateTime timestamp,
    List<String> ops = ops,
    Map<String, dynamic> previous,
  }) =>
      _change(
        data,
        ops,
        emits,
        timestamp,
        isNew,
        index: index,
        previous: previous ?? this.data,
      );

  /// Append-only operations allowed
  static const ops = ['add', 'replace', 'move'];

  DomainEvent _change(
    Map<String, dynamic> data,
    List<String> ops,
    Type emits,
    DateTime timestamp,
    bool isNew, {
    int index,
    Map<String, dynamic> previous,
  }) {
    // Remove all unsupported operations
    final patches = JsonPatch.diff(_data, data)
      ..removeWhere(
        (diff) => !ops.contains(diff['op']),
      );
    return isNew || patches.isNotEmpty
        ? _apply(
            _changed(
              data,
              emits: emits,
              index: index,
              patches: patches,
              previous: previous,
              timestamp: timestamp,
            ),
            isChanged: true,
          )
        : null;
  }

  // TODO: Add support for detecting tombstone (delete) events
  /// Delete aggregate root
  DomainEvent delete({DateTime timestamp}) => _apply(
        _deleted(timestamp ?? DateTime.now()),
        isChanged: true,
      );

  /// Apply changes and clear internal cache
  Iterable<DomainEvent> commit({Iterable<DomainEvent> changes}) {
    // Partial commit?
    if (changes?.isNotEmpty == true) {
      // Already applied?
      final duplicates = changes.where((e) => _applied.containsKey(e.uuid));
      if (duplicates.isNotEmpty) {
        throw InvalidOperation(
          'Failed to commit $changes to $this: events $duplicates already committed',
        );
      }
      // Not starting successively from head of changes?
      if (_pending.take(changes.length).map((e) => e.uuid) == changes.map((e) => e.uuid)) {
        throw WriteFailed(
          'Failed to commit $changes to $this: did not match head of uncommitted changes $_pending',
        );
      }
    }
    final committed = changes ?? _pending;
    _pending.removeWhere((e) => committed.contains(e));
    _applied.addEntries(committed.map((e) => MapEntry(e.uuid, e)));
    return committed;
  }

  /// Get aggregate updated event.
  ///
  /// Invoked from [Repository], SHOULD NOT be overridden
  @protected
  DomainEvent _changed(
    Map<String, dynamic> data, {
    int index,
    Type emits,
    DateTime timestamp,
    Map<String, dynamic> previous,
    List<Map<String, dynamic>> patches = const [],
  }) =>
      _process(
        emits,
        DomainEvent.toData(
          uuid,
          uuidFieldName,
          index: index,
          changed: data,
          patches: patches,
          previous: previous,
        ),
        timestamp,
      );

  /// Get aggregate deleted event. Invoked from [Repository]
  @protected
  DomainEvent _deleted(DateTime timestamp) => _process(
        typeOf<D>(),
        DomainEvent.toData(
          uuid,
          uuidFieldName,
          deleted: true,
          previous: data,
        ),
        timestamp,
      );

  DomainEvent _process(
    Type emits,
    Map<String, dynamic> data,
    DateTime timestamp,
  ) {
    final process = _processors['$emits'];
    if (process != null) {
      return process(
        Message(
          uuid: Uuid().v4(),
          type: '$emits',
          data: data,
          local: true,
          created: timestamp,
        ),
      );
    }
    throw InvalidOperation('Message ${emits} not recognized');
  }

  /// Apply change to [data].
  ///
  /// This will be applied directly.
  void apply(DomainEvent event) => _apply(
        event,
        isChanged: false,
      );

  // Apply implementation for internal use
  DomainEvent _apply(
    DomainEvent event, {
    bool isChanged,
  }) {
    _assertUuid(event);

    // Already applied?
    if (_applied.containsKey(event.uuid)) {
      if (_applied[event.uuid].created != event.created) {
        _applied[event.uuid] = event;
        _setModifier(event);
      }
      return _applied[event.uuid];
    }

    // Set timestamps
    _setModifier(event);

    // Applying events in order is REQUIRED for this to work!
    if (!event.isDeleted) {
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
      _applied.update(
        event.uuid,
        (_) => event,
        ifAbsent: () => event,
      );
    }

    return event;
  }

  void _setModifier(DomainEvent event) {
    if (_createdBy == null || _createdBy?.uuid == event.uuid) {
      _createdBy = event;
      _changedBy = event;
    } else {
      _changedBy = event;
    }
    if (event.isDeleted) {
      _isDeleted = true;
      _deletedBy = event;
    }
  }

  void _assertUuid(DomainEvent event) {
    if (toAggregateUuid(event) != uuid) {
      throw InvalidOperation(
        'Aggregate has $uuid, '
        'event $event contains ${toAggregateUuid(event)}',
      );
    }
  }

  /// Get array of value objects
  List<T> asValueArray<T>(String field) => List<T>.from(data[field] as List);

  /// Get array of [EntityObject]
  EntityArray asEntityArray(
    String field, {
    String entityIdFieldName,
  }) =>
      EntityArray.from(
        field,
        _ensureList(field),
        entityIdFieldName: entityIdFieldName,
      );

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
    return '$runtimeType{$uuidFieldName: $uuid, modifications: $modifications, pending: $_pending, applied: $_applied}';
  }
}

/// This class implements validated entity object array operations
class EntityArray {
  EntityArray(
    this.aggregateField,
    this.entityIdFieldName,
    Map<String, dynamic> data,
  ) : data = Map.from(data);

  factory EntityArray.from(
    String field,
    AggregateRoot root, {
    String entityIdFieldName,
  }) =>
      EntityArray(
        field,
        entityIdFieldName ?? root.entityIdFieldName,
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
  EntityArray remove(String id) {
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

  /// Get index of given [EntityObject]
  int indexOf(String id) => _asArray().indexWhere((data) => _toId(data) == id);

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
    return EntityObject(id, Map.from(found.first), entityIdFieldName);
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

/// Class for implementing a strategy for merging concurrent modifications
abstract class MergeStrategy {
  MergeStrategy(this.repository);
  Repository repository;

  Future<Iterable<DomainEvent>> merge(AggregateRoot aggregate);
  Future<Iterable<DomainEvent>> reconcile(AggregateRoot aggregate, int max) => _reconcileWithRetry(aggregate, max, 1);
  Future<Iterable<DomainEvent>> _reconcileWithRetry(AggregateRoot aggregate, int max, int attempt) async {
    try {
      // Wait with exponential backoff
      // until default waitFor is reached
      await Future.delayed(
        Duration(milliseconds: toNextTimeout(attempt, defaultWaitFor)),
      );

      final isNew = aggregate.isNew;
      // Keep local state and rollback
      final events = await merge(aggregate);
      // Was removed by merge?
      if (isNew) {
        // Add again and remove initial event
        aggregate = repository.get(aggregate.uuid).._clear();
      }

      // Rebase 'previous' and 'changed' by
      // applying patches to them again before
      // reapplying events as local changes
      final base = aggregate.data;
      var previous = base;
      events.forEach((event) {
        final next = repository.toDomainEvent(event.rebase(previous));
        aggregate._apply(
          next,
          isChanged: true,
        );
        previous = next.changed;
      });

      // IMPORTANT: Do not call Repository.push here
      // as this will add the operation to the queue
      // resulting in a live-lock situation where two
      // async operations are waiting on each other to
      // complete
      return await repository.store.push(aggregate);
    } on WrongExpectedEventVersion catch (e, stacktrace) {
      // Try again?
      if (attempt < max) {
        return await _reconcileWithRetry(aggregate, max, attempt + 1);
      }
      repository.logger.severe(
        'Aborted automatic merge after $max retries: $e with stacktrace: $stacktrace',
      );
      repository.logger.severe(
        repository.toDebugString(),
      );
      throw EventVersionReconciliationFailed(e, attempt);
    }
  }
}

/// Implements a three-way merge algorithm of concurrent modifications
class ThreeWayMerge extends MergeStrategy {
  ThreeWayMerge(Repository repository) : super(repository);

  @override
  Future<Iterable<DomainEvent>> merge(AggregateRoot aggregate) async {
    final local = aggregate.data;
    final isNew = aggregate.isNew;
    final events = repository.rollback(aggregate);
    if (isNew) {
      // This implies that an instance stream with
      // same id was concurrently created. Since the
      // aggregate was removed from store with rollback
      // above any retry must get a new aggregate
      // instance before another push is attempted
      await _catchup();
      return events;
    }

    // Keep base state and catchup to remote state
    final base = aggregate.data;
    await _catchup();

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
          base: base,
          mine: conflicts
              .map((op) => op['path'])
              .map((path) => head.firstWhere(
                    (op) => op['path'] == path,
                  ))
              .toList(),
          yours: conflicts.toList(),
        );
      }
    }
    return events;
  }

  Future _catchup() async => await repository.store.catchUp(repository);
}
