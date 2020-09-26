import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:event_source/src/models/snapshot_model.dart';
import 'package:event_source/src/storage.dart';
import 'package:event_source/src/stream.dart';
import 'package:event_source/src/util.dart';
import 'package:http/http.dart';
import 'package:json_patch/json_patch.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';

import 'bus.dart';
import 'core.dart';
import 'error.dart';
import 'extension.dart';
import 'models/aggregate_root_model.dart';
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

  /// Get repositories
  Iterable<Repository> get repos => _stores.keys;

  /// Get stores
  Iterable<EventStore> get stores => _stores.values;

  /// Check if all repositories are ready
  bool get isReady {
    if (bus.isReplaying) {
      return false;
    }
    return repos.every((repo) => repo.isReady);
  }

  /// Wait for all repositories being ready
  Future<bool> readyAsync() async {
    final callback = Completer<bool>();
    _awaitReady(callback);
    return callback.future;
  }

  void _awaitReady(Completer<bool> completer) async {
    if (isReady == false) {
      Future.delayed(
        const Duration(milliseconds: 100),
        () => _awaitReady(completer),
      );
    } else {
      completer.complete(true);
    }
  }

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
    Storage snapshots,
    bool useInstanceStreams = true,
  }) {
    final store = EventStore(
      bus: bus,
      snapshots: snapshots,
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
    if (!Storage.isInitialized) {
      throw StateError('Storage is not initialized');
    }

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
    } catch (e, stackTrace) {
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
      logger.fine('Paused ${_stores.length} subscriptions');
    }
  }

  /// Resume all subscriptions
  void resume() async {
    if (_isPaused) {
      _isPaused = false;
      _stores.values.forEach(
        (store) => store.resume(),
      );
      logger.fine('Resumed ${_stores.length} subscriptions');
    }
  }

  /// Dispose all [RepositoryManager] instances
  Future dispose() async {
    try {
      await Future.wait(
        _stores.values.map((store) => store.dispose()),
      );
      await Future.wait(
        _stores.keys.map((repo) => repo.dispose()),
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

  void _printDebug(Object message) {
    logger.info(message);
  }

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
    this.maxPushPressure,
    this.uuidFieldName = 'uuid',
    int maxBackoffTimeSeconds = 3,
  })  : _processors = Map.unmodifiable(processors.map(
          (type, process) => MapEntry('$type', process),
        )),
        logger = Logger('Repository[${typeOf<T>()}]'),
        maxBackoffTime = Duration(seconds: maxBackoffTimeSeconds);

  final Logger logger;
  final EventStore store;
  final int maxPushPressure;
  final String uuidFieldName;

  /// Get [AggregateRoot] type
  Type get aggregateType => typeOf<T>();

  /// Flag indicating that [build] succeeded
  /// and that events are not being replayed
  bool get isReady => _ready && !isReplaying;
  bool _ready = false;

  /// Check if events are being replayed for this repository
  bool get isReplaying => store.bus.isReplaying;

  /// Wait for repository becoming ready
  Future<bool> readyAsync() async {
    final callback = Completer<bool>();
    _awaitReady(callback);
    return callback.future;
  }

  void _awaitReady(Completer<bool> completer) async {
    if (_ready == false || isReplaying) {
      Future.delayed(const Duration(milliseconds: 100), () => _awaitReady(completer));
    } else {
      completer.complete(true);
    }
  }

  /// Get current event number.
  /// see [EventStore.current].
  EventNumber get number => store.current();

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
  /// An aggregate exists IFF it repository contains it and is not deleted
  bool exists(String uuid) => _aggregates.containsKey(uuid) && !_aggregates[uuid].isDeleted;

  /// Check if repository contains given aggregate root
  bool contains(String uuid) => _aggregates.containsKey(uuid);

  /// Used in [dispose] to close open subscriptions
  final List<StreamSubscription> _subscriptions = [];

  /// Build repository from [store].
  /// Returns number of events processed.
  Future<int> build() async {
    // Listen for push-queue to finish processing
    _subscriptions
      ..add(_pushQueue.onIdle().listen((event) {
        logger.info('Push queue idle');
        store.resume();
      }))
      ..add(_pushQueue.onTimeout().listen((event) {
        logger.info(
          'Push command timeout: ${event.message} (queue pressure: $pending)',
        );
      }))
      ..add(_pushQueue.onComplete().listen((event) {
        logger.info(
          'Push command complete: ${event.message} (queue pressure: $pending)',
        );
      }));
    _pushQueue.catchError((e, stackTrace) {
      logger.severe(
        'Processing request ${_pushQueue.current} failed with: $e',
        e,
        stackTrace,
      );
      return true;
    });
    if (store.snapshots != null) {
      await store.snapshots.load();
      _suuid = store.snapshots.last?.uuid;
    }
    final count = await replay();
    subscribe();
    willStartProcessingEvents();
    _ready = true;
    return count;
  }

  /// Check if repository has a active snapshot
  bool get hasSnapshot => _suuid != null;

  /// Get current [SnapshotModel]
  SnapshotModel get snapshot => store.snapshots != null ? store.snapshots[_suuid] : null;

  /// Current [SnapshotModel.uuid]
  String _suuid;

  /// Save snapshot of current states
  SnapshotModel save() {
    final snapshot = store.snapshots?.add(this);
    _reset(snapshot?.uuid);
    return snapshot;
  }

  /// Replay events into this [Repository].
  ///
  Future<int> replay() async {
    _reset(store.snapshots?.last?.uuid);
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
    if (event == null) {
      return null;
    }
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
      final base = event.mapAt<String, dynamic>('previous') ?? aggregate?.data ?? {};

      // Prepare REQUIRED fields
      final patches = event.listAt<Map<String, dynamic>>('patches');
      assert(patches != null, 'Patches can not be null');
      final changed = event.mapAt<String, dynamic>('changed') ??
          JsonUtils.apply(
            base,
            patches,
          );
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
      )..number = event.number;
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
  Future<int> catchUp({
    bool master = false,
  }) =>
      isProcessing
          ? Future.value(0)
          : store.catchUp(
              this,
              master: master,
            );

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
    } else if (isMaximumPushPressure) {
      throw RepositoryMaxPressureExceeded(
        '$runtimeType Push exceeded maximum: $maxPushPressure',
      );
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
    if (aggregate.isChanged) {
      try {
        return await _schedulePush(
          aggregate.uuid,
          changes,
          maxAttempts,
        );
      } catch (e) {
        rollback(aggregate);
        rethrow;
      }
    }
    return <DomainEvent>[];
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
  Future<Iterable<DomainEvent>> push(T aggregate, {int maxAttempts = 10}) async {
    var result = <DomainEvent>[];
    if (isMaximumPushPressure) {
      throw RepositoryMaxPressureExceeded(
        '$runtimeType Push exceeded maximum: $maxPushPressure',
      );
    } else if (aggregate.isChanged) {
      result = await _schedulePush(
        aggregate.uuid,
        aggregate.getUncommittedChanges(),
        maxAttempts,
      );
    }
    return result;
  }

  /// Get number of pending [push]
  int get pending => _pushQueue.length;

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
  final _pushQueue = StreamRequestQueue<Iterable<DomainEvent>>();

  /// Schedule [_PushOperation] for execution
  Future<Iterable<DomainEvent>> _schedulePush(
    String uuid,
    Iterable<DomainEvent> changes,
    int maxAttempts,
  ) {
    if (_pushQueue.isEmpty) {
      store.pause();
    }
    final aggregate = _assertExists(uuid);
    final message = '${typeOf<T>()} ${uuid} with ${changes.length} changes';
    final operation = _PushOperation(aggregate, changes, maxAttempts);
    _pushQueue.add(StreamRequest<Iterable<DomainEvent>>(
      execute: () async {
        final result = await _push(operation);
        // Check if snapshot should be saved
        _snapshotWhen(store.snapshots?.threshold);
        return result;
      },
      fail: true,
      message: message,
      timeout: const Duration(seconds: 60),
    ));
    logger.info(
      'Scheduled push of ${aggregate.runtimeType} ${aggregate.uuid} (queue pressure: $pending)',
    );
    return operation.completer.future;
  }

  /// Check if [push] is possible
  bool get isMaximumPushPressure => maxPushPressure != null && pending >= maxPushPressure;

  T _assertExists(String uuid) {
    final aggregate = _aggregates[uuid];
    if (aggregate == null) {
      throw AggregateNotFound('Aggregate $aggregateType $uuid not found');
    }
    return aggregate;
  }

  Future<StreamResult<Iterable<DomainEvent>>> _push(_PushOperation operation) async {
    final aggregate = operation.aggregate;
    try {
      if (debugConflicts) {
        _printDebug('---PUSH---');
        _printDebug('timestamp: ${DateTime.now().toIso8601String()}');
        _printDebug('connection: ${store.connection.host}:${store.connection.port}');
        _printDebug('repository: $this');
        _printDebug('stream: ${store.toInstanceStream(aggregate.uuid)}');
        _printDebug('store.events.count: ${store.events.values.fold(0, (count, events) => count + events.length)}');
        _printDebug('store.number.instance: ${store.current(uuid: aggregate.uuid)}');
        _printDebug('expectedEventNumber: ${store.toExpectedVersion(store.toInstanceStream(aggregate.uuid)).value}');
        _printDebug('store.number.canonical: ${store.current(stream: store.canonicalStream)}');
        _printDebug('aggregate.pending.count: ${aggregate.getUncommittedChanges().length}');
        _printDebug('aggregate.pending.items: ${aggregate.getUncommittedChanges().length}');
      }
      await store.push(aggregate);

      // Only return changes applied by this operation
      operation.completer.complete(operation.changes);

      if (debugConflicts) {
        _printDebug('---DONE---');
        _printDebug('timestamp: ${DateTime.now().toIso8601String()}');
        _printDebug('repository: $this');
        _printDebug('connection: ${store.connection.host}:${store.connection.port}');
        _printDebug('store.events.count: ${store.events.values.fold(0, (count, events) => count + events.length)}');
        _printDebug('store.number.instance: ${store.current(uuid: aggregate.uuid)}');
        _printDebug('store.number.canonical: ${store.current(stream: store.canonicalStream)}');
        _printDebug('aggregate.pending.count: ${aggregate.getUncommittedChanges().length}');
        _printDebug('aggregate.pending.items: ${aggregate.getUncommittedChanges()}');
      }
      return StreamResult(
        value: operation.changes,
      );
    } on WrongExpectedEventVersion {
      return _reconcile(operation);
    } catch (e, stackTrace) {
      logger.severe(
        'Failed to push ${aggregate.runtimeType}{uuid: ${aggregate.uuid}},\n'
        'error: $e, stacktrace: $stackTrace, debug: ${toDebugString(aggregate?.uuid)}',
      );
      operation.completer.completeError(e, stackTrace);
      return StreamResult(
        value: operation.changes,
      );
    } finally {
      // Check if snapshot should be saved
      _snapshotWhen(store.snapshots?.threshold);
    }
  }

  /// Attempts to reconcile conflicts between concurrent modifications
  Future<StreamResult<Iterable<DomainEvent>>> _reconcile(_PushOperation operation) async {
    final aggregate = operation.aggregate;
    if (debugConflicts) {
      _printDebug('---CONFLICT---');
      _printDebug('timestamp: ${DateTime.now().toIso8601String()}');
      _printDebug('repository: $this');
      _printDebug('connection: ${store.connection.host}:${store.connection.port}');
      _printDebug('store.events.count: ${store.events.values.fold(0, (count, events) => count + events.length)}');
      _printDebug('store.events.items: ${store.events.values}');
      _printDebug('aggregate.uuid: ${aggregate.uuid}');
      _printDebug('aggregate.applied.count: ${aggregate.applied.length}');
      _printDebug('aggregate.applied.items: ${aggregate.applied}');
      _printDebug('aggregate.pending.count: ${aggregate.getUncommittedChanges().length}');
      _printDebug('aggregate.pending.items: ${aggregate.getUncommittedChanges()}');
    } // Attempt to automatic merge until maximum attempts
    try {
      final events = await ThreeWayMerge(this).reconcile(
        aggregate,
        operation.maxAttempts,
      );
      operation.completer.complete(events);
      return StreamResult(value: events);
    } on ConflictNotReconcilable catch (e, stackTrace) {
      operation.completer.completeError(e, stackTrace);
    } catch (e, stackTrace) {
      logger.severe(
        'Failed to reconcile before push of ${aggregate.runtimeType}{uuid: ${aggregate.uuid}},\n'
        'error: $e, stacktrace: $stackTrace, debug: ${toDebugString(aggregate?.uuid)}',
      );
      operation.completer.completeError(e, stackTrace);
    }
    return StreamResult(
      value: operation.changes,
    );
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
      aggregate.loadFromHistory(
        this,
        store.get(aggregate.uuid),
      );
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
  }) {
    var aggregate = _aggregates[uuid];
    if (aggregate == null && createNew) {
      aggregate = _aggregates.putIfAbsent(
        uuid,
        () => create(
          _processors,
          uuid,
          JsonPatch.apply(data ?? {}, patches) as Map<String, dynamic>,
        ),
      );
      aggregate.loadFromHistory(this, store.get(uuid));
    }
    return aggregate;
  }

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
          final existing = _aggregates[command.uuid];
          throw AggregateExists(
            '${typeOf<T>()} ${command.uuid} exists',
            existing,
          );
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
          final existing = array[command.entityId];
          throw EntityExists(
            'Entity ${command.aggregateField} ${command.entityId} exists',
            existing,
          );
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

  String toDebugString([String uuid]) {
    final aggregate = _aggregates[uuid];
    final stream = store.toInstanceStream(uuid);
    return '$runtimeType: {\n'
        'ready: $isReady, '
        'count: ${count()}, '
        'stream: $stream,\n'
        'canonicalStream: ${store.canonicalStream}}},\n'
        'aggregate.type: ${aggregate?.runtimeType},\n'
        'aggregate.uuid: ${aggregate?.uuid},\n'
        'aggregate.data: ${aggregate?.data},\n'
        'aggregate.modifications: ${aggregate?.modifications},\n'
        'aggregate.applied.count: ${aggregate?.applied?.length},\n'
        'aggregate.pending.count: ${aggregate?.getUncommittedChanges()?.length},\n'
        'aggregate.pending.items: ${aggregate?.getUncommittedChanges()},\n'
        '}';
  }

  /// Reset current state to
  /// snapshot given by [_suuid].
  /// If no snapshot exists,
  /// nothing is changed by
  /// this method.
  ///
  void _reset(String suuid) {
    if (store.snapshots?.contains(suuid) == true) {
      _suuid = suuid;
      final snapshot = store.snapshots[_suuid];
      // Remove missing
      _aggregates.removeWhere(
        (key, _) => !snapshot.aggregates.containsKey(key),
      );
      // Update existing and add missing
      snapshot.aggregates.forEach((uuid, model) {
        _aggregates.update(uuid, (a) => a.._reset(this), ifAbsent: () {
          final aggregate = create(
            _processors,
            uuid,
            Map.from(model.data),
          );
          aggregate._reset(this);
          return aggregate;
        });
      });
      logger.info('Reset to snapshot $_suuid@${snapshot.number}');
    }
  }

  void _snapshotWhen(int threshold) {
    if (threshold is num && store.snapshots != null) {
      final last = store.snapshots.last?.number?.value ?? EventNumber.first.value;
      if (number.value - last >= threshold) {
        save();
      }
    }
  }

  /// Dispose resources.
  ///
  /// Can not be called after this.
  Future<void> dispose() async {
    _pushQueue.cancel();
    _aggregates.clear();
    await Future.wait(
      _subscriptions.map((s) => s.cancel()),
    );
    if (_ruleController.hasListener) {
      await _ruleController.close();
    }
    return _pushQueue.dispose();
  }
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
    _create(data, created);
  }

  void _create(Map<String, dynamic> data, DateTime created) {
    _createdBy = _change(
      // Ensure data and uuid is given
      (data ?? {})..addAll({uuidFieldName: uuid}),
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

  /// Get event number of [DomainEvent] applied last
  EventNumber get number =>
      applied.isNotEmpty ? applied.last.number : EventNumber(_snapshot?.number?.value ?? EventNumber.none.value);

  /// Get [EventNumber] of next [DomainEvent]
  /// from next modification. Since [EventNumber]
  /// is 0-based, next [EventNumber] is equal to
  /// current number of [modifications].
  EventNumber get nextNumber => EventNumber(modifications);

  /// [Message] to [DomainEvent] processors
  final Map<String, ProcessCallback> _processors;

  /// Aggregate root data (weak schema)
  Map<String, dynamic> get data => Map.from(_data);
  final Map<String, dynamic> _data = {};

  /// Get element at given path
  T elementAt<T>(String path) => _data.elementAt(path) as T;

  /// Get list at given path
  List<T> listAt<T>(String path, {List<T> defaultList}) => _data.listAt<T>(path) ?? defaultList;

  /// Get Map at given path
  Map<S, T> mapAt<S, T>(String path, {Map<S, T> defaultMap}) => _data.mapAt<S, T>(path) ?? defaultMap;

  /// Get number of modifications since creation
  ///
  /// Since [EventNumber] is 0-based, the number
  /// of modifications is equal to [EventNumber]
  /// of [lastEvent] + 1.
  ///
  int get modifications {
    final base = lastEvent;
    return base == null ? 0 : base.number.value + 1;
  }

  /// Get last event patched with [data]
  ///
  /// Is either
  /// 1. last event in pending
  /// 2. last event in applied
  /// 3. [SnapshotModel.changedBy]
  /// 4. [changedBy]
  ///
  DomainEvent get lastEvent => _pending.isNotEmpty
      ? _pending.last
      : (_applied.isNotEmpty ? _applied.values.last : _snapshot?.changedBy ?? _changedBy);

  /// Local uncommitted changes
  final _pending = <DomainEvent>[];

  /// [Message.uuid]s of applied events
  final LinkedHashMap<String, DomainEvent> _applied = LinkedHashMap<String, DomainEvent>();

  /// Get current snapshot if taken
  AggregateRootModel get snapshot => _snapshot;
  AggregateRootModel _snapshot;

  /// Get uuids of applied events
  Iterable<DomainEvent> get applied => List.unmodifiable(_applied.values);

  /// Check if event is applied to
  /// this [AggregateRoot] instance
  /// and can be fetched
  /// Note that this will return
  /// false if it was applied to
  /// current snapshot.
  bool isApplied(Event event) => _applied.containsKey(event.uuid);

  /// Check if event is applied
  DomainEvent getApplied(String uuid) => _applied[uuid];

  /// Get changed not committed to store
  Iterable<DomainEvent> getUncommittedChanges() => List.unmodifiable(_pending);

  /// Check if uncommitted changes exists
  bool get isNew => number.isNone && _applied.isEmpty;

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
  AggregateRoot loadFromHistory(Repository repo, Iterable<Event> events) {
    // Only clear if history exist,
    // otherwise keep the event
    // from construction
    if (events.isNotEmpty || repo.store.snapshots?.contains(uuid) == true) {
      _reset(repo);
    }
    final offset = number;
    events?.where((event) => event.number > offset)?.forEach((event) => _apply(
          repo.toDomainEvent(event),
          isChanged: false,
        ));

    return this;
  }

  /// Reset to initial state
  void _reset(Repository repo) {
    _data.clear();
    _pending.clear();
    _applied.clear();
    _createdBy = null;
    _changedBy = null;
    _deletedBy = null;
    if (repo.hasSnapshot) {
      _snapshot = repo.snapshot.aggregates[uuid];
      if (_snapshot != null) {
        _data.addAll(snapshot.data);
        _createdBy = toDomainEvent(snapshot.createdBy);
        _changedBy = toDomainEvent(snapshot.changedBy);
        _deletedBy = toDomainEvent(snapshot.deletedBy);
      }
    }
  }

  DomainEvent toDomainEvent(Event event) => event != null
      ? _process(
          event.type,
          event.data,
          event.created,
          event.number,
        )
      : null;

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
              timestamp: timestamp,
              previous: isNew ? {} : previous,
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
        emits.toString(),
        DomainEvent.toData(
          uuid,
          uuidFieldName,
          index: index,
          changed: data,
          patches: patches,
          previous: previous,
        ),
        timestamp,
        nextNumber,
      );

  /// Get aggregate deleted event. Invoked from [Repository]
  @protected
  DomainEvent _deleted(DateTime timestamp) => _process(
        typeOf<D>().toString(),
        DomainEvent.toData(
          uuid,
          uuidFieldName,
          deleted: true,
          previous: data,
        ),
        timestamp,
        nextNumber,
      );

  DomainEvent _process(
    String emits,
    Map<String, dynamic> data,
    DateTime timestamp,
    EventNumber number,
  ) {
    final process = _processors['$emits'];
    if (process != null) {
      return process(
        Message(
          uuid: Uuid().v4(),
          type: emits,
          data: data,
          local: true,
          created: timestamp,
        ),
      )..number = number;
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
    return '$runtimeType{$uuidFieldName: $uuid, '
        'modifications: $modifications, '
        'applied.count: ${_applied.length},'
        'pending.count: ${_pending.length}'
        '}';
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
  bool contains(String id) => id != null && _asArray().any((data) => _toId(data) == id);

  /// Next EntityObject id.
  ///
  /// Starts at value `1`
  String get nextId => '${_asArray().where(
        (data) => int.tryParse(_toId(data)) is int,
      ).fold<int>(0, (next, data) => max(next, int.tryParse(_toId(data)) + 1))}';

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
    final existing = entities.where((data) => _toId(data) == actual);
    if (existing.isNotEmpty) {
      throw EntityExists(
        'Entity $entityIdFieldName $actual exists',
        EntityObject(actual, existing.first, entityIdFieldName),
      );
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
        Duration(
          milliseconds: toNextTimeout(attempt, defaultWaitFor),
        ),
      );

      final isNew = aggregate.isNew;
      // Keep local state and rollback
      final events = await merge(aggregate);
      // Was removed by merge?
      if (isNew) {
        // Add again and remove initial event
        aggregate = repository.get(aggregate.uuid).._reset(repository);
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
        'Aborted automatic merge after $max retries on ${aggregate.runtimeType} ${aggregate.uuid}, '
        'error $e with stacktrace: $stacktrace, '
        'debug: ${repository.toDebugString(aggregate?.uuid)}',
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
    final previous = aggregate.number;
    final events = repository.rollback(aggregate);
    if (isNew) {
      // This implies that an instance stream with
      // same id was concurrently created. Since the
      // aggregate was removed from store with rollback
      // above any retry must get a new aggregate
      // instance before another push is attempted
      await _catchup();
      final next = aggregate.number;
      final delta = next.value - previous.value;
      // Append base count
      return events.map((e) => e..number += delta);
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
    // Append base count from catchup
    final next = aggregate.number;
    final delta = next.value - previous.value;
    return events.map((e) => e..number += delta);
  }

  Future _catchup() async => await repository.store.catchUp(
        repository,
        master: true,
      );
}
