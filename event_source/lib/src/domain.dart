import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:http/http.dart';
import 'package:json_patch/json_patch.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:stack_trace/stack_trace.dart';
import 'package:uuid/uuid.dart';

import 'package:event_source/src/storage.dart';
import 'package:event_source/src/stream.dart';
import 'package:event_source/src/util.dart';

import 'bus.dart';
import 'core.dart';
import 'error.dart';
import 'extension.dart';
import 'models/aggregate_root_model.dart';
import 'models/snapshot_model.dart';
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
      // Will not on each command
      // before executing the next
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
            'Failed to prepare projections $backlog '
            'with error: $e\n,'
            'stackTrace: ${Trace.format(stackTrace)}',
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
      // Will not on each command
      // before executing the next
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
            'Failed to build repositories ${backlog.map((repo) => repo.aggregateType)} '
            'with error: $e, '
            'stackTrace: ${Trace.format(stackTrace)}',
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

  /// Get [Repository] from given [type] name
  Repository getFromTypeName(String type) {
    final match = type.toLowerCase();
    final items = _stores.keys.where(
      (e) => '${e.aggregateType}'.toLowerCase() == match,
    );
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
      // Will not on each command
      // before executing the next
      await Future.wait(
        _stores.values.map((store) => store.dispose()),
      );
      // Will not on each command
      // before executing the next
      await Future.wait(
        _stores.keys.map((repo) => repo.dispose()),
      );
    } on ClientException catch (e, stackTrace) {
      logger.warning(
        'Failed to dispose one or more stores with error: $e,\n'
        'stacktrace: ${Trace.format(stackTrace)}',
      );
    }
    _stores.clear();
  }
}

/// Class for transactional change handling
class Transaction<S extends Command, T extends AggregateRoot> {
  Transaction(
    this.uuid,
    this.repository,
  ) : seqnum = _seqnum.update(
          typeOf<T>(),
          (seqnum) => ++seqnum,
          ifAbsent: () => 1,
        );

  /// Sequence number since first creation of this class
  final int seqnum;
  static final Map<Type, int> _seqnum = {};

  /// Get [AggregateRoot.uuid] this [Transaction] applies to
  final String uuid;

  /// Maximum number of retries
  int get maxAttempts => _maxAttempts;
  int _maxAttempts = 10;

  /// Called when transactions is completed
  final _completer = Completer<Iterable<DomainEvent>>();

  /// Get caller [Object] when this [Transaction] was started by
  Object get startedBy => _startedBy;
  Object _startedBy;

  /// Get [StackTrace] where this [Transaction] was started at
  StackTrace get startedAt => _startedAt;
  StackTrace _startedAt;

  /// Get [Future] of push result
  Future<Iterable<DomainEvent>> get onPush => _completer.future;

  /// Get [Repository] which this [Transaction] applies to
  final Repository<S, T> repository;

  /// Check if [aggregate] with [uuid] exists in [repository]
  bool get exists => repository.contains(uuid);

  /// Get [aggregate] of type [T] from [repository].
  /// Returns null if not exist
  T get aggregate => repository.get(uuid, createNew: false);

  /// Check if transaction allows modification of [aggregate]
  bool get isModifiable => !isStarted;

  /// Check if transaction is currently being committed
  bool get isStarted => _changes.isNotEmpty;

  /// Check if conflicts exists
  bool get hasConflicts => conflicting.isNotEmpty;

  /// Changes currently being pushed.
  Iterable<DomainEvent> get changes {
    return isStarted ? _changes.toList() : aggregate.getLocalEvents();
  }

  /// Changes in this transaction
  Iterable<DomainEvent> _changes = <DomainEvent>[];

  /// Changes that will result in a merge conflict
  Iterable<DomainEvent> get conflicting => (aggregate?._remoteEvents ?? <DomainEvent>[]);

  /// Changes not pushed yet
  Iterable<DomainEvent> get remaining {
    final local = (aggregate?._localEvents ?? <DomainEvent>[]).skipWhile(
      (e) => _changes.contains(e),
    );
    final remaining = exists
        ? local.skipWhile(
            (e) => aggregate._applied.containsKey(e),
          )
        : local;
    return remaining.toList();
  }

  /// Get concurrent modifications
  Iterable<DomainEvent> get concurrent => (exists && isStarted
          ? (aggregate?._localEvents?.where((e) => !_changes.contains(e)) ?? <DomainEvent>[])
          : <DomainEvent>[])
      .toList();

  /// Check if concurrent modifications has occurred
  bool get hasConcurrentModifications => concurrent.isNotEmpty;

  /// Get [StreamRequest.tag]
  String get tag => '${aggregate.runtimeType} ${uuid} in transaction ${seqnum} with ${_changes.length} changes';

  /// Execute command on given [aggregate]
  /// root. Changes are not pushed to
  /// [Repository.store] until [push] is
  /// called. See also [Repository.push].
  ///
  FutureOr<Iterable<DomainEvent>> execute(S command) async {
    _assertTrx();
    return repository.execute(command);
  }

  /// Push aggregate changes to remote
  /// storage. Changes are committed when
  /// on successful push. On failure,
  /// changes are rolled back. See also
  /// [Repository.push].
  ///
  /// If aggregate does not [exists] an
  /// [AggregateNotFound] exception is  thrown.
  ///
  Future<Iterable<DomainEvent>> push({
    int maxAttempts = 10,
    Duration timeout = const Duration(seconds: 60),
  }) {
    _assertTrx();
    _assertExists();
    return repository.push(aggregate);
  }

  /// Start push operation
  Iterable<DomainEvent> _start(Object caller, int maxAttempts) {
    _assertStart();
    _maxAttempts = maxAttempts;
    return _restart(caller);
  }

  /// Restart transaction for push operation
  Iterable<DomainEvent> _restart(Object caller) {
    _assertRestart();
    final restart = _startedBy != null;
    _startedBy = caller;
    _startedAt = StackTrace.current;
    _changes = List.unmodifiable(
      aggregate._localEvents,
    );
    repository.logger.fine(
      'Transaction on ${repository.aggregateType} $uuid is ${restart ? 'restarted' : 'started'}',
    );
    return _changes;
  }

  /// Rollback all pending changes in [aggregate]
  /// and complete this [Transaction].
  ///
  /// If transaction is [isStarted] an
  /// [InvalidOperation] is thrown.
  ///
  Iterable<DomainEvent> rollback() {
    _assertStart();
    return _rollback(complete: true);
  }

  /// Rollback all pending changes
  /// in [aggregate].
  ///
  /// if [complete] is true, this
  /// [Transaction] will be completed.
  ///
  /// if [complete] is false, this
  /// [Transaction] will not be
  /// completed. Useful when
  ///
  Iterable<DomainEvent> _rollback({@required complete}) {
    return exists
        ? repository._rollback(
            aggregate,
            complete: complete,
          )
        : <DomainEvent>[];
  }

  bool get isCompleted => _isCompleted;
  bool _isCompleted = false;

  void _complete({
    Object error,
    StackTrace stackTrace,
    Iterable<DomainEvent> changes = const [],
  }) {
    try {
      _assertComplete();
      // Prevent infinite reentry loop
      // from calling rollback on errors
      if (exists) {
        if (error == null) {
          if (aggregate.isChanged) {
            final completed = aggregate.commit(
              changes: changes,
            );
            _assertCommitted(completed);
          }
          // This will throw ConcurrentWriteModifications
          // triggering a partial rollback to remote state
          // applied above
          _assertNoConcurrentModifications();
          _completer.complete(changes);
        } else {
          _rollback(
            complete: false,
          );
          _completer.completeError(
            error,
            stackTrace,
          );
        }
      }
    } catch (e, stackTrace) {
      _rollback(
        complete: !hasConcurrentModifications,
      );
      if (!hasConcurrentModifications) {
        _completer.completeError(e, stackTrace);
      }
    } finally {
      // Transactions can not be completed until
      // local concurrent modifications are
      // rolled back
      _isCompleted = !hasConcurrentModifications;
      if (_isCompleted) {
        repository.logger.fine(
          'Transaction on ${repository.aggregateType} $uuid is completed',
        );
      }
    }
  }

  void _assertCommitted(Iterable<DomainEvent> completed) {
    final uncommitted = _changes.where((e) => !completed.contains(e));
    if (uncommitted.isNotEmpty) {
      throw StateError(
        'Failed to commit ${uncommitted.length} events to aggregate ${aggregate.runtimeType} $uuid',
      );
    }
  }

  void _assertExists() {
    if (!exists) {
      throw AggregateNotFound('Aggregate ${typeOf<T>()} not found');
    }
  }

  void _assertStart() {
    _assertRestart();
    if (isStarted) {
      throw InvalidOperation(
        'Transaction on ${aggregate.runtimeType} $uuid is started',
      );
    }
  }

  void _assertRestart() {
    _assertTrx();
    _assertExists();
    _assertComplete();
  }

  void _assertTrx() {
    if (!repository.inTransaction(uuid)) {
      throw InvalidOperation(
        'Transaction on ${aggregate.runtimeType} $uuid is not open',
      );
    }
  }

  void _assertComplete() {
    if (_isCompleted) {
      throw InvalidOperation(
        'Transaction on ${aggregate.runtimeType} $uuid was completed',
      );
    }
  }

  void _assertNoConcurrentModifications() {
    if (hasConcurrentModifications) {
      throw ConcurrentWriteOperation(
        '${concurrent.length} concurrent modifications after '
        'transaction on ${aggregate.runtimeType} $uuid was started',
        this,
      );
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Transaction && runtimeType == other.runtimeType && uuid == other.uuid;

  @override
  int get hashCode => uuid.hashCode;

  @override
  String toString() {
    return '$runtimeType: {\n'
        '  seqnum: $seqnum,\n'
        '  changes: ${_changes.map((e) => '{${e.type}: ${e.uuid}')}},\n'
        '  aggregate: {\n'
        '    uuid: ${aggregate.uuid},\n'
        '    modifications: ${aggregate.modifications},\n'
        '    changes: ${aggregate._localEvents.map((e) => '{${e.type}: ${e.uuid}}')},\n'
        '  },\n'
        '}';
  }
}

/// [Message] type name to [DomainEvent] processor method
typedef ProcessCallback = DomainEvent Function(Message change);

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
    @required Map<Type, ProcessCallback> processors,
    this.maxPushPressure = 100,
    this.uuidFieldName = 'uuid',
    int maxBackoffTimeSeconds = 10,
  })  : _processors = Map.unmodifiable(processors.map(
          (type, process) => MapEntry('$type', process),
        )),
        maxBackoffTime = Duration(seconds: maxBackoffTimeSeconds);

  final EventStore store;
  final int maxPushPressure;
  final String uuidFieldName;

  static const timeout = Duration(seconds: 30);

  /// Internal - for local debugging
  bool debugConflicts = false;

  void _printDebug(Object message) {
    logger.info(message);
  }

  /// Get logger instance
  Logger get logger {
    _logger ??= Logger('Repository[${typeOf<T>()}:$hashCode]');
    return _logger;
  }

  Logger _logger;

  /// Get [AggregateRoot] type
  Type get aggregateType => typeOf<T>();

  /// Flag indicating that [build] succeeded
  /// and that events are not being replayed
  bool get isReady => _isReady && !isReplaying;
  bool _isReady = false;

  /// Check if events are being replayed for this repository
  bool get isReplaying => store.bus.isReplaying;

  /// Wait for repository becoming ready
  Future<bool> readyAsync() async {
    final callback = Completer<bool>();
    _awaitReady(callback);
    return callback.future;
  }

  void _awaitReady(Completer<bool> completer) async {
    if (_isReady == false || isReplaying) {
      Future.delayed(const Duration(milliseconds: 100), () => _awaitReady(completer));
    } else {
      completer.complete(true);
    }
  }

  /// Get current event number.
  /// see [EventStore.current].
  EventNumber get number => store.current();

  /// Maximum backoff duration between retries
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
  StreamSubscription _pushQueueSubscription;

  /// Used in [dispose] to close open subscriptions
  EventStoreSubscriptionController _storeSubscriptionController;

  /// Build repository from [store].
  /// Returns number of events processed.
  Future<int> build() async {
    final isRebuild = _isReady;
    if (isRebuild) {
      _isReady = false;
      await _pushQueue.dispose();
      await _pushQueueSubscription.cancel();
      await _storeSubscriptionController.cancel();
      _pushQueue = StreamRequestQueue<Iterable<DomainEvent>>();
    }

    _pushQueueSubscription = _pushQueue.onEvent().listen(_onQueueEvent);
    _pushQueue.catchError((e, stackTrace) {
      logger.network(
        'Push requests failed',
        e,
        stackTrace,
      );
      return false;
    });
    if (store.snapshots != null) {
      await store.snapshots.load();
      _suuid = store.snapshots.last?.uuid;
    }
    final count = await replay();
    _storeSubscriptionController = await subscribe();
    if (!isRebuild) {
      willStartProcessingEvents();
    }
    _isReady = true;
    return count;
  }

  void _onQueueEvent(event) {
    switch (event.runtimeType) {
      case StreamRequestAdded:
        final request = (event as StreamRequestAdded).request;
        logger.fine(
          'Push command added: ${request.tag} (${_toPressureString()})',
        );
        break;
      case StreamRequestCompleted:
        final request = (event as StreamRequestCompleted).request;
        logger.fine(
          'Push command complete: ${request.tag} (${_toPressureString()})',
        );
        break;
      case StreamQueueIdle:
        logger.fine('Push queue idle');
        break;
      case StreamRequestTimeout:
        final request = (event as StreamRequestTimeout).request;
        logger.fine(
          'Push command timeout: ${request.tag} (${_toPressureString()})',
        );
        break;
      case StreamRequestFailed:
        final request = (event as StreamRequestFailed).request;
        logger.fine(
          'Push command failed: ${request.tag} (${_toPressureString()})',
        );
        break;
    }
  }

  String _toPressureString() => 'queue pressure: ${_pushQueue.length}, command pressure: ${_commands.length}';

  /// Check if repository has a active snapshot
  bool get hasSnapshot => store.snapshots?.contains(_suuid) == true;

  /// Get current [SnapshotModel]
  SnapshotModel get snapshot => hasSnapshot ? store.snapshots[_suuid] : null;

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
  Future<EventStoreSubscriptionController> subscribe({
    Duration maxBackoffTime = const Duration(seconds: 10),
  }) =>
      store.subscribe(
        this,
        maxBackoffTime: maxBackoffTime,
      );

  /// Called after [build()] is completed.
  void willStartProcessingEvents() => {};

  /// Get domain event from given [event]
  DomainEvent toDomainEvent(SourceEvent event) {
    if (event == null) {
      return null;
    }
    final process = _processors['${event.type}'];
    if (process != null) {
      final uuid = toAggregateUuid(event);

      // Check if event is already applied
      final aggregate = _aggregates[uuid];
      final applied = aggregate.getApplied(event.uuid);

      // Only return if creation date is equal
      if (applied?.created == event.created) {
        return applied;
      }

      // Get base if exists
      final base = event.mapAt<String, dynamic>('previous') ?? aggregate?.data ?? {};

      // Prepare REQUIRED fields
      final patches = event.listAt<Map<String, dynamic>>('patches');
      assert(patches != null, 'Patches can not be null');

      // Use applied changes if exists,
      // otherwise use sourced if exists
      // otherwise apply patches to base
      final changed = applied?.changed ??
          event.mapAt<String, dynamic>('changed') ??
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
            patches: patches,
            changed: changed,
            previous: applied?.previous ?? base,
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
  void handle(Object source, DomainEvent event) async {
    if (event.local && _rules.isNotEmpty) {
      try {
        final builders = _rules[event.runtimeType];
        if (builders?.isNotEmpty == true) {
          builders.forEach((builder) async {
            final rule = builder(this);
            final events = await rule(source, event);
            logger.fine(
              'Evaluated rule $rule on event $event => $events',
            );
            events?.forEach(
              _ruleController.add,
            );
          });
        }
      } catch (e, stackTrace) {
        logger.severe(
          'Execution of rule for $event on $runtimeType failed '
          'with error: $e,\n'
          'stackTrace: ${Trace.format(stackTrace)}',
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

  final Map<String, Transaction> _transactions = {};

  /// Get a [Transaction] for
  /// given [AggregateRoot.uuid].
  ///
  /// If no [Transaction] exists,
  /// one will be created. This
  /// transaction will not end
  /// until [Transaction.push]
  /// or [Transaction.rollback] is called.
  ///
  /// If an [AggregateRoot] with
  /// given [uuid] does not [exists],
  /// it will not be created until
  /// [get] is called directly, or
  /// by execution of an [Command]
  /// of type [S] with [Action.create].
  ///
  Transaction<S, T> getTransaction(String uuid) => _transactions.putIfAbsent(
        uuid,
        () => Transaction<S, T>(uuid, this),
      );

  /// Check if modifications of [AggregateRoot]
  /// with given [uuid] is wrapped in an
  /// [Transaction]
  bool inTransaction(String uuid) => _transactions.containsKey(uuid);

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
  /// Throws an [RepositoryMaxPressureExceeded] failure if [maxPushPressure] was
  /// exceeded by this call.
  ///
  /// Throws an [StreamRequestTimeout] failure if [timeout] was
  /// exceeded by this call.
  ///
  /// Throws an [SocketException] failure if calls on [EventStore.connection] fails.
  /// This failure is not recoverable.
  ///
  /// Throws [WriteFailed] for all other failures. This failure is not recoverable.
  @override
  FutureOr<Iterable<DomainEvent>> execute(
    S command, {
    int maxAttempts = 10,
    Duration timeout = timeout,
  }) async {
    final changes = <DomainEvent>[];

    // Await transaction if exists
    // and push has started
    await _onNextCommand(
      command,
      timeout,
    );

    // Execute command on given aggregate
    final aggregate = _execute(
      command,
      changes,
    );
    if (aggregate.isChanged) {
      // If in transaction return
      // changes without pushing them
      if (_transactions.containsKey(command.uuid)) {
        return changes;
      }
      return push(
        aggregate,
        timeout: timeout,
        maxAttempts: maxAttempts,
      );
    }
    return <DomainEvent>[];
  }

  Future<String> _onNextCommand(S command, Duration timeout) async {
    final uuid = _assertExecute(
      command,
    );
    if (inTransaction(uuid)) {
      final trx = getTransaction(uuid);
      if (trx.isStarted) {
        try {
          _commands.add(command);
          await trx.onPush.timeout(timeout);
        } on TimeoutException {
          throw CommandTimeout(
            'Command ${command.runtimeType} ${command.uuid} timed out',
            command,
          );
        } finally {
          _commands.remove(command);
        }
      }
    }
    return uuid;
  }

  T _execute(S command, List<DomainEvent> changes) {
    _assertCanModify(
      command.uuid,
    );
    final aggregate = command is EntityCommand
        ? _applyEntityData(
            command,
            changes,
          )
        : _applyAggregateData(
            command,
            changes,
          );
    return aggregate;
  }

  T _applyAggregateData(S command, List<DomainEvent> changes) {
    T aggregate;
    final remaining = [];
    final list = _asAggregateData(command);
    switch (command.action) {
      case Action.create:
        aggregate = get(command.uuid, data: list.first);
        changes.addAll(aggregate.getLocalEvents());
        remaining.addAll(list.skip(1));
        break;
      case Action.update:
        aggregate = get(command.uuid);
        remaining.addAll(list);
        break;
      case Action.delete:
        aggregate = get(command.uuid);
        changes.add(aggregate.delete(
          timestamp: command.created,
        ));
        return aggregate;
    }
    for (var data in remaining) {
      changes.add(aggregate.patch(
        data,
        emits: command.emits,
        timestamp: command.created,
      ));
    }
    return aggregate;
  }

  T _applyEntityData(EntityCommand command, List<DomainEvent> changes) {
    final next = _asEntityData(command);
    final aggregate = get(command.uuid);
    if (!contains(command.uuid)) {
      changes.addAll(aggregate.getLocalEvents());
    }
    changes.add(aggregate.patch(
      Map<String, dynamic>.from(next['data']),
      index: next['index'] as int,
      emits: command.emits,
      timestamp: command.created,
      previous: Map<String, dynamic>.from(next['previous']),
    ));
    return aggregate;
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
  /// Throws an [RepositoryMaxPressureExceeded] failure if [maxPushPressure] was
  /// exceeded by this call.
  ///
  /// Throws an [StreamRequestTimeout] failure if [timeout] was
  /// exceeded by this call.
  ///
  /// Throws an [SocketException] failure if calls on [EventStore.connection] fails.
  /// This failure is not recoverable.
  ///
  /// Throws [WriteFailed] for all other failures. This failure is not recoverable.
  Future<Iterable<DomainEvent>> push(
    T aggregate, {
    int maxAttempts = 10,
    Duration timeout = timeout,
  }) {
    var result = <DomainEvent>[];
    final uuid = aggregate.uuid;
    // After this point the transaction
    // is started. A exception will be
    // thrown if a second push is attempted
    // before the transaction is completed.
    final transaction = _assertPush(
      uuid,
      maxAttempts,
    );
    if (aggregate.isChanged) {
      // Ensure transaction exists is not concurrent
      final added = _pushQueue.add(StreamRequest<Iterable<DomainEvent>>(
        key: uuid,
        fail: true,
        timeout: timeout,
        tag: transaction.tag,
        execute: () => _push(transaction),
      ));
      logger.fine(
        'Scheduled push of: ${transaction.tag} (queue pressure: $pressure)',
      );
      _assertAdd(added, uuid, transaction);
      return transaction.onPush;
    } else {
      _completeTrx(uuid);
    }
    return Future.value(
      result,
    );
  }

  /// Get number of commands waiting to [execute] and pending [push] requests
  int get pressure {
    return _commands.length + _pushQueue.length;
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
  ///
  var _pushQueue = StreamRequestQueue<Iterable<DomainEvent>>();

  /// Check if [push] or [execute] is possible
  bool get isMaximumPushPressure => maxPushPressure != null && pressure >= maxPushPressure;

  /// Get commands waiting to execute
  final _commands = <S>{};

  String _assertExecute(S command) {
    final uuid = command.uuid;
    if (isMaximumPushPressure) {
      throw RepositoryMaxPressureExceeded(
        'Execution of ${command.runtimeType} $uuid failed',
        uuid,
        this,
      );
    }
    if (uuid == null) {
      throw UUIDIsNull('Field [${command.uuidFieldName}] is null in $command');
    }
    return uuid;
  }

  Transaction _assertCanModify(String uuid, {bool open = false}) {
    var transaction;
    if (inTransaction(uuid) || open) {
      transaction = getTransaction(uuid);
      if (transaction.isStarted) {
        final idx = _pushQueue.indexOf(uuid);
        throw ConcurrentWriteOperation(
          'Push request $idx already in progress for $aggregateType $uuid',
          transaction,
        );
      }
    }
    return transaction;
  }

  Transaction _assertPush(String uuid, int maxAttempts) {
    if (isMaximumPushPressure) {
      final aggregate = _aggregates[uuid];
      final changes = (inTransaction(uuid) ? getTransaction(uuid).changes : aggregate?.getLocalEvents()?.length) ?? 0;
      throw RepositoryMaxPressureExceeded(
        'Push of $changes changes in ${aggregateType} $uuid failed',
        uuid,
        this,
      );
    }
    if (!_aggregates.containsKey(uuid)) {
      throw AggregateNotFound(
        'Aggregate $aggregateType $uuid not found',
      );
    }
    final transaction = _assertCanModify(
      uuid,
      open: true,
    );
    transaction._start(this, maxAttempts);
    return transaction;
  }

  void _assertAdd(
    bool added,
    String uuid,
    Transaction transaction,
  ) {
    if (!added) {
      throw StateError(
        'Push of ${aggregateType} $uuid already scheduled > ${transaction.tag}',
      );
    }
  }

  /// Assert that this [operation] has an [Transaction]
  T _assertTrx(Transaction transaction) {
    final aggregate = transaction.aggregate;
    if (!inTransaction(aggregate.uuid)) {
      throw StateError(
        'No transaction found for aggregate ${aggregateType} ${aggregate.uuid}',
      );
    }
    if (transaction.hasConflicts) {
      throw ConflictNotReconcilable(
        'Conflicts must be resolved for $aggregateType ${aggregate.uuid}',
        base: aggregate.base,
        mine: aggregate.mine,
        yours: aggregate.yours,
        conflicts: aggregate.conflicts,
      );
    }
    return aggregate;
  }

  Future<StreamResult<Iterable<DomainEvent>>> _push(Transaction transaction) async {
    final aggregate = _assertTrx(transaction);
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
        _printDebug('store.number.canonical: ${store.current()}');
        _printDebug('aggregate.pending.count: ${aggregate.getLocalEvents().length}');
        _printDebug('aggregate.pending.items: ${aggregate.getLocalEvents().length}');
      }

      // This will attempt to push all changes
      // in one operation, regardless of the
      // number of events that it contains.
      final changes = await store.push(
        aggregate.uuid,
        // Will throw ConcurrentWriteOperation
        // if changed after transaction was started
        transaction.changes,
        uuidFieldName: uuidFieldName,
      );

      _completeTrx(
        aggregate.uuid,
        changes: changes,
      );

      if (debugConflicts) {
        _printDebug('---DONE---');
        _printDebug('timestamp: ${DateTime.now().toIso8601String()}');
        _printDebug('repository: $this');
        _printDebug('connection: ${store.connection.host}:${store.connection.port}');
        _printDebug('store.events.count: ${store.events.values.fold(0, (count, events) => count + events.length)}');
        _printDebug('store.number.instance: ${store.current(uuid: aggregate.uuid)}');
        _printDebug('store.number.canonical: ${store.current()}');
        _printDebug('aggregate.pending.count: ${aggregate.getLocalEvents().length}');
        _printDebug('aggregate.pending.items: ${aggregate.getLocalEvents()}');
      }

      return StreamResult(
        tag: transaction.tag,
        key: transaction.uuid,
        value: changes,
      );
    } on WrongExpectedEventVersion {
      return await _reconcile(transaction);
    } catch (error, stackTrace) {
      logger.severe(
        'Failed to push ${aggregate.runtimeType}{uuid: ${aggregate.uuid}} with error: $error,\n'
        'stacktrace: ${Trace.format(stackTrace)}\n'
        'debug: ${toDebugString(aggregate?.uuid)}',
      );
      _completeTrx(
        aggregate.uuid,
        error: error,
        stackTrace: stackTrace,
      );
      return StreamResult.fail(
        error,
        stackTrace,
        tag: transaction.tag,
      );
    } finally {
      store.snapshotWhen(this);
    }
  }

  /// Attempts to reconcile conflicts between concurrent modifications
  Future<StreamResult<Iterable<DomainEvent>>> _reconcile(Transaction transaction) async {
    final aggregate = _assertTrx(transaction);
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
      _printDebug('aggregate.pending.count: ${aggregate.getLocalEvents().length}');
      _printDebug('aggregate.pending.items: ${aggregate.getLocalEvents()}');
    } // Attempt to automatic merge until maximum attempts
    try {
      final events = await ThreeWayMerge(this, maxBackoffTime).reconcile(
        transaction,
      );
      _completeTrx(
        aggregate.uuid,
        changes: events,
      );
      return StreamResult(
        value: events,
        tag: transaction.tag,
        key: transaction.uuid,
      );
    } catch (error, stackTrace) {
      logger.severe(
        'Failed to reconcile before push of ${aggregate.runtimeType}{uuid: ${aggregate.uuid}} '
        'with error: $error,\n'
        'stacktrace: ${Trace.format(stackTrace)},\n'
        'debug: ${toDebugString(aggregate?.uuid)}',
      );
      _completeTrx(
        aggregate.uuid,
        error: error,
        stackTrace: stackTrace,
      );
      return StreamResult.fail(
        error,
        stackTrace,
        tag: transaction.tag,
      );
    }
  }

  /// Rollback all changes
  Iterable<Function> rollbackAll() => _aggregates.values.where((aggregate) => aggregate.isChanged).map(
        (aggregate) => rollback,
      );

  /// Rollback all pending changes
  /// in [aggregate]. Any [Transaction]
  /// on given [aggregate] will end.
  Iterable<DomainEvent> rollback(T aggregate) {
    return _rollback(
      aggregate,
      complete: true,
    );
  }

  /// Rollback local changes. If
  Iterable<DomainEvent> _rollback(
    T aggregate, {
    @required complete,
  }) {
    final uuid = aggregate.uuid;
    final trx = _transactions[uuid];
    final exists = store.contains(uuid);
    final local = aggregate.getLocalEvents();
    final remaining = trx?.remaining ?? local;

    if (exists) {
      if (aggregate.isChanged) {
        // Replay remote events
        aggregate._replay(this);
      }
    } else {
      // Aggregate only exists
      // locally, remove it
      _aggregates.remove(uuid);
      // Reset aggregate
      aggregate._reset(this);
    }

    if (complete) {
      _completeTrx(
        uuid,
      );
    }

    return remaining;
  }

  /// Complete transaction for given [aggregate]
  Transaction _completeTrx(
    String uuid, {
    Object error,
    StackTrace stackTrace,
    Iterable<DomainEvent> changes = const [],
  }) {
    final trx = _transactions[uuid];
    try {
      trx?._complete(
        error: error,
        changes: changes,
        stackTrace: stackTrace,
      );
    } finally {
      if (trx?.isCompleted == true) {
        _transactions.remove(uuid);
      }
    }
    return trx;
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
      // Only replay if history or
      // snapshot exist for given uuid,
      // otherwise keep the event from
      // construction of this aggregate
      if (store.contains(uuid) || hasSnapshot && snapshot.contains(uuid)) {
        aggregate._replay(this);
      }
    }
    return aggregate;
  }

  /// Get all aggregate roots.
  Iterable<T> getAll({int offset = 0, int limit = 20, bool deleted = false}) =>
      _aggregates.values.where((test) => deleted || !test.isDeleted).toPage(
            offset: offset,
            limit: limit,
          );

  List<Map<String, dynamic>> _asAggregateData(S command) {
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
    return [command.data];
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
        'aggregate.pending.count: ${aggregate?.getLocalEvents()?.length},\n'
        'aggregate.pending.items: ${aggregate?.getLocalEvents()},\n'
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
      logger.info('Reset to snapshot $_suuid@${snapshot.number.value}');
    }
  }

  /// Dispose resources.
  ///
  /// Can not be called after this.
  Future<void> dispose() async {
    _aggregates.clear();
    await _pushQueue?.dispose();
    await _pushQueueSubscription?.cancel();
    await _storeSubscriptionController?.cancel();
    if (_ruleController.hasListener) {
      await _ruleController.close();
    }
    return Future.value();
  }

  @override
  String toString() {
    return '$runtimeType{'
        'hashCode: $hashCode, '
        'type: $aggregateType, '
        'number: $number, '
        'count: ${count()}, '
        'pressure: $pressure, '
        'pending.requests: ${_pushQueue.length}, '
        'pending.commands: ${_commands.length}}';
  }

  Map<String, dynamic> getMeta({
    String uuid,
    bool items = true,
    bool data = true,
  }) {
    final aggregate = _aggregates[uuid];
    return {
      'type': '$aggregateType',
      'aggregates': <String, dynamic>{
        'count': count(),
        'changed': _aggregates.values.where((aggregate) => aggregate.isChanged).length,
        'transactions': _transactions.length,
      },
      'number': number.value,
      'queue': {
        'pressure': {
          'push': _pushQueue.length,
          'command': _commands.length,
          'total': _pushQueue.length + _commands.length,
          'maximum': maxPushPressure,
          'exceeded': isMaximumPushPressure
        },
        'status': {
          'idle': _pushQueue.isIdle,
          'ready': _pushQueue.isReady,
          'disposed': _pushQueue.isDisposed,
        },
        'requests': {
          if (_pushQueue.last != null)
            'last': {
              'key': '${_pushQueue.last.key}',
              'tag': '${_pushQueue.last.tag}',
              'timestamp': '${_pushQueue.lastAt.toIso8601String()}',
            },
          if (_pushQueue.current != null)
            'current': {
              'key': '${_pushQueue.current.key}',
              'tag': '${_pushQueue.current.tag}',
              'timestamp': '${_pushQueue.currentAt.toIso8601String()}',
            },
        },
        'stats': {
          'queued': _pushQueue.length,
          'started': _pushQueue.started,
          'failures': _pushQueue.failures,
          'timeouts': _pushQueue.timeouts,
          'processed': _pushQueue.processed,
          'cancelled': _pushQueue.cancelled,
          'completed': _pushQueue.completed,
        },
      },
      if (hasSnapshot) 'snapshot': _toSnapshotMeta(items, data),
      if (aggregate != null)
        'aggregate': _toAggregateMeta(
          aggregate,
          data: data,
          items: items,
        ),
    };
  }

  Map<String, Object> _toSnapshotMeta(bool items, bool data) {
    return {
      'uuid': snapshot.uuid,
      'number': snapshot.number.value,
      'aggregates': {
        'count': snapshot.aggregates.length,
        if (items)
          'items': [
            ...snapshot.aggregates.values
                .map((a) => {
                      'uuid': a.uuid,
                      'number': a.number.value,
                      'created': <String, dynamic>{
                        'uuid': a.createdBy?.uuid,
                        'type': '${a.createdBy?.type}',
                        'timestamp': a.createdWhen.toIso8601String(),
                      },
                      'changed': <String, dynamic>{
                        'uuid': a.changedBy?.uuid,
                        'type': '${a.changedBy?.type}',
                        'timestamp': a.changedWhen.toIso8601String(),
                      },
                      if (data) 'data': a.data,
                    })
                .toList(),
          ]
      },
    };
  }

  Map<String, dynamic> _toAggregateMeta(
    AggregateRoot aggregate, {
    bool data = true,
    bool items = true,
  }) =>
      <String, dynamic>{
        'uuid': aggregate.uuid,
        'number': aggregate.number.value,
        'created': <String, dynamic>{
          'uuid': aggregate.createdBy?.uuid,
          'type': '${aggregate.createdBy?.type}',
          'timestamp': aggregate.createdWhen.toIso8601String(),
        },
        'changed': <String, dynamic>{
          'uuid': aggregate.changedBy?.uuid,
          'type': '${aggregate.changedBy?.type}',
          'timestamp': aggregate.changedWhen.toIso8601String(),
        },
        'modifications': aggregate.modifications,
        'applied': <String, dynamic>{
          'count': aggregate.applied?.length,
        },
        if (data) 'data': aggregate.data,
        'transaction': inTransaction(aggregate.uuid),
        'pending': <String, dynamic>{
          'count': aggregate.getLocalEvents()?.length,
          if (items)
            'items': [
              ...aggregate
                  .getLocalEvents()
                  .map((e) => {
                        'type': e.type,
                        'number': e.number.value,
                        'created': e.created.toIso8601String(),
                        if (data)
                          'data': {
                            'prev': e.previous,
                            'next': e.changed,
                            'patches': e.patches,
                          },
                      })
                  .toList(),
            ],
        },
      };
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
  EventNumber get number {
    if (applied.isNotEmpty) {
      return EventNumber(applied.last.number.value);
    }
    if (_snapshot == null) {
      return EventNumber.none;
    }
    return EventNumber(_snapshot.number.value);
  }

  /// Get [EventNumber] of next [DomainEvent].
  ///
  /// Since [EventNumber] is 0-based, next
  /// [EventNumber] is equal [modifications].
  ///
  EventNumber get nextNumber => EventNumber(modifications);

  /// [Message] to [DomainEvent] processors
  final Map<String, ProcessCallback> _processors;

  /// Aggregate root data without any local
  /// changes applied. This equals to [data]
  /// with all known remote events [applied].
  Map<String, dynamic> get base {
    // Get current base
    var base = Map<String, dynamic>.from(
      _base.isEmpty ? _snapshot?.data ?? {} : _base,
    );
    // Apply events added since last call that have patches
    final added = _applied.values.skip(_baseIndex).where((e) => e.patches.isNotEmpty);
    if (added.isNotEmpty) {
      base = added.fold(
        base,
        (previous, event) => JsonUtils.apply(
          previous,
          event.patches,
        ),
      );
      _setBase(base);
    }
    // This ensures that base is not
    // recalculated on each call
    _baseIndex = _applied.length;
    return Map.from(base);
  }

  int _baseIndex = 0;
  final Map<String, dynamic> _base = {};

  /// Aggregate root [data] (weak schema).
  /// This includes any changes applied locally.
  /// Last known remote state is given by [base].
  Map<String, dynamic> get data => Map.from(_data);
  final Map<String, dynamic> _data = {};

  /// Check if element with given [path] exists
  bool hasPath<T>(String path) => _data.hasPath(path);

  /// Get element at given path
  T elementAt<T>(String path) => _data.elementAt(path) as T;

  /// Get list at given path
  List<T> listAt<T>(String path, {List<T> defaultList}) => _data.listAt<T>(path) ?? defaultList;

  /// Get Map at given path
  Map<S, T> mapAt<S, T>(String path, {Map<S, T> defaultMap}) => _data.mapAt<S, T>(path) ?? defaultMap;

  /// Get number of modifications since creation
  ///
  int get modifications {
    return number.value + _localEvents.length + 1;
  }

  /// Get last event patched with [data]
  ///
  /// Is either
  /// 1. last event in local
  /// 2. last event in applied
  /// 3. [SnapshotModel.changedBy]
  /// 4. [changedBy] (new aggregate)
  ///
  DomainEvent get lastEvent => _localEvents.isNotEmpty
      ? _localEvents.last
      : (_applied.isNotEmpty ? _applied.values.last : _toDomainEvent(_snapshot?.changedBy) ?? _changedBy);

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

  /// Get local changes (mine) not committed to store
  Iterable<DomainEvent> getLocalEvents() => List.unmodifiable(_localEvents);

  /// Local changes pending commit
  final _localEvents = <DomainEvent>[];

  /// Check if uncommitted changes exists
  bool get isNew => number.isNone && _applied.isEmpty;

  /// Check if local uncommitted changes exists
  bool get isChanged => _localEvents.isNotEmpty;

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

  /// Get [mine] patches.
  List<Map<String, dynamic>> get mine {
    if (_mineIndex < _localEvents.length) {
      final mine = JsonPatch.diff(base, data);
      _setMine(mine);
      // This ensures that mine is not
      // recalculated on each call
      _mineIndex = _localEvents.length;
    }
    return List.from(_mine);
  }

  int _mineIndex = 0;
  final List<Map<String, dynamic>> _mine = [];

  /// Get [yours] patches if [hasConflicts].
  List<Map<String, dynamic>> get yours {
    if (_yourIndex < _remoteEvents.length) {
      final added = _remoteEvents.skip(_yourIndex).where((e) => e.patches.isNotEmpty);
      if (added.isNotEmpty) {
        final yours = added.fold(
          _yours.toList(),
          (previous, event) => previous..addAll(event.patches),
        );
        _setYours(yours);
      }
      // This ensures that yours is not
      // recalculated on each call
      _yourIndex = _remoteEvents.length;
    }
    return List.from(_yours);
  }

  int _yourIndex = 0;
  final List<Map<String, dynamic>> _yours = [];

  /// Check if conflicts with remote changes exists
  bool get hasConflicts => _conflicts.isNotEmpty;

  /// List of paths with conflicts that must be resolved manually
  List<String> get conflicts => List.unmodifiable(_conflicts);
  final LinkedHashSet<String> _conflicts = LinkedHashSet<String>();

  /// Remote [DomainEvent]s pending apply because of unresolvable conflicts
  final _remoteEvents = <DomainEvent>[];

  /// Get remote conflicts (yours) not applied to aggregate
  Iterable<DomainEvent> getRemoteEvents() => List.unmodifiable(_remoteEvents);

  /// Get aggregate uuid from event
  String toAggregateUuid(Event event) => event.data[uuidFieldName] as String;

  /// Load events from history.
  @protected
  AggregateRoot _replay(Repository repo) {
    final events = repo.store.get(uuid);
    _reset(repo);
    final offset = number;
    events?.where((event) => event.number > offset)?.forEach((event) => _apply(
          // Must use this method to ensure previous
          repo.toDomainEvent(event),
          isLocal: false,
        ));

    return this;
  }

  /// Catchup to head of remote event stream.
  @protected
  AggregateRoot _catchUp(Repository repo) {
    // Get events applied since last _apply or _catchup
    final added = repo.store.get(uuid).skip(_applied.length);
    final offset = number;
    // Only catchup from current event number
    added?.where((event) => event.number >= offset)?.forEach((event) => _apply(
          // Must use this method to ensure previous
          repo.toDomainEvent(event),
          isLocal: false,
        ));
    return this;
  }

  /// Reset to initial state
  void _reset(Repository repo) {
    _data.clear();
    _mine.clear();
    _yours.clear();
    _applied.clear();
    _conflicts.clear();
    _localEvents.clear();
    _remoteEvents.clear();
    _createdBy = null;
    _changedBy = null;
    _deletedBy = null;
    if (repo.hasSnapshot) {
      _snapshot = repo.snapshot.aggregates[uuid];
      if (_snapshot != null) {
        _data.addAll(snapshot.data);
        _createdBy = _toDomainEvent(snapshot.createdBy);
        _changedBy = _toDomainEvent(snapshot.changedBy);
        _deletedBy = _toDomainEvent(snapshot.deletedBy);
      }
    }
  }

  /// Convert events found in [snapshot] to [DomainEvent].
  /// Should only called from within this [AggregateRoot].
  @protected
  DomainEvent _toDomainEvent(Event event) {
    if (event != null) {
      return _process(
        event.type,
        event.data,
        event.created,
        event.number,
      );
    }
    return null;
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
  ///
  /// An aggregate that [hasConflicts]
  /// can not be modified locally before
  /// the conflict is resolved. Calling this
  /// method when the aggregate has [hasConflicts]
  /// will throw an [InvalidOperation].
  ///
  DomainEvent patch(
    Map<String, dynamic> data, {
    @required Type emits,
    int index,
    DateTime timestamp,
    Map<String, dynamic> previous,
  }) =>
      _change(
        data,
        emits,
        timestamp,
        isNew,
        index: index,
        previous: previous ?? this.data,
      );

  DomainEvent _change(
    Map<String, dynamic> next,
    Type emits,
    DateTime timestamp,
    bool isNew, {
    int index,
    Map<String, dynamic> previous,
  }) {
    // Remove all unsupported operations
    final patches = JsonUtils.diff(
      _data,
      next,
    );
    return isNew || patches.isNotEmpty
        ? _apply(
            _changed(
              emits: emits,
              index: index,
              patches: patches,
              timestamp: timestamp,
              previous: isNew ? {} : previous,
            ),
            isLocal: true,
          )
        : null;
  }

  // TODO: Add support for detecting tombstone (delete) events
  /// Delete aggregate root
  ///
  /// An aggregate that [hasConflicts]
  /// can not be modified locally before
  /// the conflict is resolved. Calling this
  /// method when the aggregate has [hasConflicts]
  /// will throw an [InvalidOperation].
  ///
  DomainEvent delete({DateTime timestamp}) => _apply(
        _deleted(timestamp ?? DateTime.now()),
        isLocal: true,
      );

  /// Apply changes and clear internal cache
  ///
  /// An aggregate that [hasConflicts]
  /// can not be modified locally before
  /// the conflict is resolved. Calling this
  /// method when the aggregate has [hasConflicts]
  /// will throw an [InvalidOperation].
  ///
  Iterable<DomainEvent> commit({Iterable<DomainEvent> changes}) {
    _assertNoConflicts();
    // Partial commit?
    if (changes?.isNotEmpty == true) {
      // Already applied?
      final duplicates = changes.where((e) => _applied.containsKey(e.uuid));
      if (duplicates.isNotEmpty) {
        throw InvalidOperation(
          'Failed to commit $changes to $runtimeType $uuid: events $duplicates already committed',
        );
      }
      // Not starting successively from head of changes?
      if (_localEvents.take(changes.length).map((e) => e.uuid) == changes.map((e) => e.uuid)) {
        throw WriteFailed(
          'Failed to commit $changes to $runtimeType $uuid: did not match head of uncommitted changes $_localEvents',
        );
      }
    }
    final committed = changes ?? _localEvents;
    _localEvents.removeWhere((e) => committed.contains(e));
    _applied.addEntries(committed.map((e) => MapEntry(e.uuid, e)));
    return committed;
  }

  /// Get aggregate updated event.
  ///
  /// Invoked from [Repository], SHOULD NOT be overridden
  @protected
  DomainEvent _changed({
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
          patches: patches,
          previous: previous,
          changed: JsonPatch.apply(_data, patches),
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

  /// Apply remote change to [data].
  ///
  /// Ff [isChanged] is false the [event]
  /// will be patched directly to [data]
  /// and added to list of [applied] events.
  ///
  /// If [isChanged] is true, a
  /// three-way-merge will be
  /// attempted. If the [event] could not
  /// be patched without an conflict, it
  /// is added to list of [_remoteEvents]
  /// instead and [data] is not changed.
  ///
  /// An aggregate that [hasConflicts]
  /// can not be modified locally before
  /// the conflict is resolved. Calling this
  /// method when the aggregate has [hasConflicts]
  /// will throw an [InvalidOperation].
  ///
  DomainEvent apply(DomainEvent event) => _apply(
        event,
        isLocal: false,
      );

  /// Resolve conflicts.
  ///
  /// If [remote] is false (default),
  /// remote changes are overwritten
  /// with local changes.
  ///
  /// If [remote] is false, local
  /// changes are overwritten with
  /// remote changes.
  ///
  Iterable<DomainEvent> resolve({bool remote = false}) {
    if (hasConflicts) {
      if (remote) {
        _setData(
          JsonPatch.apply(base, _yours),
        );
        _setModifier(
          _remoteEvents.last,
        );
        _localEvents.clear();
        _localEvents.addAll(_remoteEvents);
      }
      // Reset conflicts
      _mine.clear();
      _yours.clear();
      _conflicts.clear();
      _localEvents.clear();
      _remoteEvents.clear();
    }
    return [];
  }

  /// Apply change to [data].
  ///
  /// For internal use only.
  ///
  /// An aggregate that [hasConflicts]
  /// can not be modified locally before
  /// the conflict is resolved. Calling this
  /// method when the aggregate has [hasConflicts]
  /// will throw an [InvalidOperation].
  ///
  /// If [isLocal] is true and [hasConflicts] is false
  /// (local change only) the event is
  /// patched to [data] and added to
  /// list of [_localEvents] changes.
  ///
  /// If [isLocal] and [isChanged] is false
  /// (remote change only) the event is
  /// patched to [data] and added to
  /// list of [_applied] changes.
  ///
  /// If [isLocal] is false, and [isChanged] is true
  /// (concurrent remote and local changes),
  /// a three-way-merge will be attempted.
  ///
  /// If the [event] can be patched without any
  /// conflict it is patched to [data] and added to
  /// the list of [_applied] changes.
  ///
  /// If the [event] could not be patched without
  /// an conflict, it is added to list of [_remoteEvents]
  /// and [data] is not changed.
  ///
  @protected
  DomainEvent _apply(
    DomainEvent event, {
    @required bool isLocal,
  }) {
    _assertUuid(event);

    // Already applied?
    if (_applied.containsKey(event.uuid)) {
      _assertEqualNumber(event, _applied[event.uuid].number);
      _applied[event.uuid] = event;
      if (event == createdBy || event == changedBy) {
        _setModifier(event);
      }
      return _applied[event.uuid];
    }

    // Subscription caught up before writeEvents returned?
    final idx = _localEvents.indexOf(event);
    if (idx > -1) {
      _localEvents.replaceRange(idx, idx, [event]);
      if (event == createdBy || event == changedBy) {
        _setModifier(event);
      }
      return event;
    }

    // Apply change to data
    if (isLocal) {
      // local change only
      _assertNoConflicts();
      _patch(
        event,
        isLocal: true,
      );
    } else if (isChanged) {
      // merge concurrent remote and local changes
      _merge(event);
    } else {
      // remote change only
      _patch(
        event,
        isLocal: false,
      );
    }

    return event;
  }

  @protected
  void _patch(
    DomainEvent event, {
    @required bool isLocal,
  }) {
    // Applying events in order is REQUIRED for this to work!
    _assertStrictMonotone(event, isLocal: isLocal);

    // Set timestamps
    _setModifier(event);

    // Deletion does not update data
    if (!event.isDeleted) {
      _setData(
        _assertData(event),
      );
    }

    if (isLocal) {
      _localEvents.add(event);
    } else {
      _applied.update(
        event.uuid,
        (_) => event,
        ifAbsent: () => event,
      );
      _localEvents.forEach(
        (e) => e.number++,
      );
    }
  }

  /// Perform three-way merge
  ///
  ///  1. Get patches for base -> data (mine) and base -> remote (yours) changes
  ///  2. Check if any of mine and yours patches collide
  /// 3a. If patches collide, add event to conflicts.
  /// 3b. Else, rebase local events and reapply
  ///
  void _merge(DomainEvent event) {
    assert(!isNew, 'Only possible if same uuid is generated concurrently!');

    // 1. Get local (mine) and remote (yours) patches
    final head = event.patches;
    final yours = head.map((op) => op['path']);
    final concurrent = mine.where((op) => yours.contains(op['path']));

    // 2. Check if any of mine and yours patches collide
    final eq = const MapEquality().equals;
    final conflicts = concurrent.where(
      (op1) => head.where((op2) => op2['path'] == op1['path'] && !eq(op1, op2)).isNotEmpty,
    );

    if (hasConflicts || conflicts.isNotEmpty) {
      // 3a. Automatic merge not possible
      _conflict(
        event,
        conflicts.map((p) => p['path']),
      );
    } else {
      // 3b. Patch
      _patch(
        event,
        isLocal: false,
      );
    }
  }

  /// Handle conflict
  void _conflict(
    DomainEvent event,
    Iterable<String> conflicts,
  ) {
    _remoteEvents.add(event);
    _yours.addAll(event.patches);
    _conflicts.addAll(conflicts);
  }

  void _setBase(Map<String, dynamic> base) {
    _base.clear();
    _base.addAll(base);
  }

  void _setData(Map<String, dynamic> data) {
    _data.clear();
    _data.addAll(data);
  }

  void _setMine(Iterable<Map<String, dynamic>> mine) {
    _mine.clear();
    _mine.addAll(mine);
  }

  void _setYours(Iterable<Map<String, dynamic>> yours) {
    _yours.clear();
    _yours.addAll(yours);
  }

  void _setModifier(DomainEvent event) {
    if (_createdBy == null || _createdBy == event) {
      _createdBy = event;
      _changedBy ??= event;
      if (_changedBy == event) {
        _changedBy = event;
      }
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
        'Current aggregate has $uuid, '
        'event $event contains uuid ${toAggregateUuid(event)}',
      );
    }
  }

  void _assertNoConflicts() {
    if (hasConflicts) {
      throw ConflictNotReconcilable(
        'Aggregate $runtimeType $uuid has ${_remoteEvents.length} unresolved conflicts',
        base: base,
        mine: mine,
        yours: yours,
        conflicts: conflicts,
      );
    }
  }

  void _assertEqualNumber(DomainEvent event, EventNumber number) {
    final delta = number.value - event.number.value;
    if (delta != 0) {
      final message = 'Event number not equal to current: {\n'
          '  aggregate.uuid: $uuid\n'
          '  aggregate.type: $runtimeType\n'
          '  event.type: ${event.type}\n'
          '  event.number.expected: $number\n'
          '  event.number.actual: ${event.number.value}\n'
          '}';
      throw InvalidOperation(message);
    }
  }

  void _assertStrictMonotone(
    DomainEvent event, {
    @required bool isLocal,
  }) {
    var delta;
    if (isLocal) {
      // Local events should increase with 1
      delta = modifications - event.number.value;
    } else if (isApplied(event)) {
      // Should have same number
      delta = getApplied(event.uuid).number.value - event.number.value;
    } else {
      // Next number should only increase with
      delta = number.value + 1 - event.number.value;
    }
    if (delta != 0) {
      final message = 'Event number not strict monotone increasing: {\n'
          '  aggregate.uuid: $uuid\n'
          '  aggregate.type: $runtimeType\n'
          '  event.type: ${event.type}\n'
          '  event.applied: ${isApplied(event)}\n'
          '  event.number.expected: $nextNumber\n'
          '  event.number.actual: ${event.number.value}\n'
          '}';
      throw InvalidOperation(message);
    }
  }

  Map<String, dynamic> _assertData(DomainEvent event) {
    final data = event.changed;
    if (data == null) {
      // At this point it is assumed that
      // patches are applied to 'previous' state
      // and stored in event 'changed' state by
      // EventStore using Repository.toDomainEvent
      // or by this repository in _changed.
      throw StateError(
        "Event data 'changed' is missing: ${event.type} ${event.uuid}",
      );
    }
    return data;
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
        'number: $number, '
        'modifications: $modifications, '
        'applied: ${_applied.length},'
        'pending: ${_localEvents.length}'
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
  MergeStrategy(this.repository, this.maxBackoffTime);

  Repository repository;

  final Duration maxBackoffTime;

  Future<AggregateRoot> merge(Transaction transaction);

  Future<Iterable<DomainEvent>> reconcile(Transaction transaction) {
    return _reconcileWithRetry(transaction, 1);
  }

  Future<Iterable<DomainEvent>> _reconcileWithRetry(Transaction transaction, int attempt) async {
    // Get aggregate
    var aggregate = transaction.aggregate;

    try {
      // Wait with exponential backoff
      // until default waitFor is reached
      await onBackoff(attempt);

      // Catchup to head of event stream
      await repository.store.catchUp(
        repository,
        master: false,
      );

      // Only merge if
      if (!aggregate.isNew) {
        aggregate = await merge(transaction);
      }

      // Check if any conflicts has occurred
      aggregate._assertNoConflicts();

      // Restart transaction
      var next = transaction._restart(this);

      // IMPORTANT: Do not call Repository.push here
      // as this will add the operation to the queue
      // resulting in a live-lock situation where two
      // async operations are waiting on each other to
      // complete
      next = await repository.store.push(
        aggregate.uuid,
        next,
        uuidFieldName: aggregate.uuidFieldName,
      );

      return next;
    } on WrongExpectedEventVersion catch (e, stackTrace) {
      // Try again?
      if (attempt < transaction._maxAttempts) {
        return await _reconcileWithRetry(transaction, attempt + 1);
      }
      repository.logger.severe(
        'Aborted automatic merge after ${transaction._maxAttempts} retries on ${aggregate.runtimeType} ${aggregate.uuid} '
        'with error $e, \n'
        'stacktrace: ${Trace.format(stackTrace)},\n'
        'debug: ${repository.toDebugString(aggregate?.uuid)}',
      );
      throw EventVersionReconciliationFailed(e, attempt);
    }
  }

  Future onBackoff(int attempt) => Future.delayed(
        Duration(
          milliseconds: toNextTimeout(attempt, maxBackoffTime),
        ),
      );
}

/// Implements a three-way merge algorithm of concurrent modifications
class ThreeWayMerge extends MergeStrategy {
  ThreeWayMerge(
    Repository repository,
    Duration maxBackoffTime,
  ) : super(repository, maxBackoffTime);

  @override
  Future<AggregateRoot> merge(Transaction transaction) async {
    final aggregate = transaction.aggregate;

    // Only merge if
    if (!aggregate.isNew) {
      // Catchup to head of remote event stream
      // for given aggregate without completing
      // the transaction. Aggregate will merge
      // remote concurrent modification and
      // register any conflicts with remote
      // events that it caught up to
      aggregate._catchUp(repository);
    }

    return aggregate;
  }
}
