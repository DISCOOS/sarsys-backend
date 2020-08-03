import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:http/http.dart';
import 'package:meta/meta.dart';
import 'package:logging/logging.dart';
import 'package:collection/collection.dart';

import 'bus.dart';
import 'core.dart';
import 'error.dart';
import 'extension.dart';
import 'domain.dart';
import 'models/AtomFeed.dart';
import 'models/AtomItem.dart';
import 'results.dart';

const Duration defaultWaitFor = Duration(milliseconds: 1500);
const Duration defaultPullEvery = Duration(milliseconds: 100);

/// Storage class managing events locally in memory received from event store server
@sealed
class EventStore {
  /// [EventStore] constructor
  ///
  /// Parameter [bus] is required. [EventStore] uses it
  /// to publish events after a successful [push] of events
  /// to the appropriate canonical stream.
  ///
  /// Parameter [aggregate] is required. It defines the
  /// aggregate name segment in the [canonicalStream] to source
  /// events from.
  ///
  /// Parameter [prefix] is optional. If given,
  /// it is concatenated with [aggregate] using
  /// `EventStore.toCanonical([prefix, stream])` which
  /// returns a canonical stream name of colon-delimited
  /// stream segments.
  ///
  /// Parameter [useInstanceStreams] controls how this
  /// repository is writing events for each [AggregateRoot]
  /// instance.
  ///
  /// If true, events for each [AggregateRoot] is
  /// written to a separate aggregate instance stream. Each
  /// instance streams are identified by concatenating
  /// [prefix], [aggregate] and [AggregateRoot.uuid] using
  /// `EventStore.toCanonical([prefix, aggregate, uuid])`.
  ///
  /// This is the default behavior since it will minimize
  /// write contention an hence reduce the number of
  /// [WrongExpectedEventVersion] thrown by method [push].
  ///
  /// [EventStore] uses the system projection
  /// [$by_category](https://eventstore.org/docs/projections/system-projections/index.html?tabs=tabid-5#by-category)
  /// to project all stream instances of [AggregateRoot]s
  /// into one single category stream. This reduces the number
  /// of connections required to subscribe to events making
  /// the overall network load as low as possible. System
  /// projections must be enabled for this to work.
  ///
  /// If false, all events are sourced from the same
  /// [canonicalStream]. This is typically appropriate for
  /// aggregates with a low write-rate or where write
  /// contention is not an issue. In most cases however, it
  /// is probably not a good idea to source all events from
  /// the same stream.
  ///
  EventStore({
    @required this.bus,
    @required this.aggregate,
    @required this.connection,
    this.prefix,
    this.useInstanceStreams = true,
  }) : logger = Logger('EventStore[${toCanonical([prefix, aggregate])}]') {
    _current[canonicalStream] = EventNumber.none;
  }

  /// Get canonical stream name
  static String toCanonical(List<String> segments) => segments
      .where(
        (test) => test?.trim()?.isNotEmpty == true,
      )
      .join(':');

  /// The name of canonical stream to source events from.
  ///
  /// If [useInstanceStreams] is true, events from all instance
  /// streams are projected by the system projection
  /// [$by_category](https://eventstore.org/docs/projections/system-projections/index.html?tabs=tabid-5#by-category)
  /// to a category stream with name equal to the concatenation
  /// of '$ce-', [prefix] and [aggregate] with colon ':' as
  /// delimiter. All events are read from the category
  /// stream, including any subscriptions.
  ///
  /// Events for each [AggregateRoot] is written to separate
  /// aggregate instance streams. The name of each instance
  /// stream is a concatenation of [prefix], [aggregate] and
  /// [AggregateRoot.uuid]. Method [toInstanceStream] will return
  /// the name of the stream which the events are written to.
  ///
  /// If [useInstanceStreams] is false, all events are
  /// read and written to [canonicalStream], equal to the
  /// concatenation [prefix] and [aggregate] with colon ':'
  /// as delimiter.
  ///
  String get canonicalStream => useInstanceStreams
      ? '\$ce-${toCanonical([
          prefix,
          aggregate,
        ])}'
      : toCanonical([
          prefix,
          aggregate,
        ]);

  /// Stream prefix
  final String prefix;

  /// Stream name
  final String aggregate;

  /// If true, eventstore will write events for each
  /// [AggregateRoot] instance to a separate stream
  final bool useInstanceStreams;

  /// [MessageBus] instance
  final MessageBus bus;

  /// [Logger] instance
  final Logger logger;

  /// [EventStoreConnection] instance
  final EventStoreConnection connection;

  /// [Map] of events for each aggregate root sourced from stream.
  ///
  /// [LinkedHashMap] remembers the insertion order of keys, and
  /// keys are iterated in the order they were inserted into the map.
  /// This is important for stream id inference from key order.
  final LinkedHashMap<String, List<Event>> _store = LinkedHashMap<String, List<Event>>();

  /// Current event numbers mapped to associated stream
  final Map<String, EventNumber> _current = {};

  /// Check if store is empty
  bool get isEmpty => _store.isEmpty;

  /// Check if store is not empty
  bool get isNotEmpty => _store.isNotEmpty;

  /// Get all events
  Map<String, List<Event>> get events => Map.from(_store);

  /// Current event number for [canonicalStream]
  ///
  /// If [AggregateRoot.uuid] is given, the aggregate
  /// instance stream number is returned. This numbers
  /// is the same as for the [canonicalStream] if
  /// [useInstanceStreams] is false.
  ///
  /// If [stream] is given, this takes precedence and
  /// returns the event number for this stream.
  ///
  /// If stream does not exist, [EventNumber.none] is returned.
  ///
  EventNumber current({String stream, String uuid}) =>
      (useInstanceStreams && (stream != null || uuid != null)
          ? _current[stream ?? toInstanceStream(uuid)]
          : _current[canonicalStream]) ??
      EventNumber.none;

  /// Replay events from stream to given repository
  ///
  /// Throws an [InvalidOperation] if [Repository.store] is not this [EventStore]
  Future<int> replay<T extends AggregateRoot>(Repository<Command, T> repository) async {
    // Sanity checks
    _assertState();
    _assertRepository(repository);

    try {
      bus.replayStarted<T>();

      _reset();

      // Fetch all events
      final count = await _catchUp(
        repository,
        EventNumber.first,
      );
      logger.info("Replayed $count events from stream '${canonicalStream}'");
      return count;
    } finally {
      bus.replayEnded<T>();
    }
  }

  void _reset() {
    _store.clear();
    _current.clear();
    _current[canonicalStream] = EventNumber.none;
  }

  /// Catch up with stream
  Future<int> catchUp(Repository repository) async {
    final previous = current();
    final next = current() + 1;
    final count = await _catchUp(repository, next);
    final actual = current();
    if (count > 0) {
      logger.info(
        'Caught up from event $previous to $actual with $count events from remote stream $canonicalStream',
      );
    } else {
      logger.info(
        'Local stream $canonicalStream is at same event number as remote stream ($previous)',
      );
//      logger.info('---STACKTRACE---');
//      logger.info(StackTrace.current);
    }
    return count;
  }

  /// Catch up with stream from given number
  Future<int> _catchUp(Repository repository, EventNumber number) async {
    var count = 0;
    // Lower bound is last known event number in stream
    final head = EventNumber(max(current().value, number.value));
    if (head > number) {
      logger.fine(
        "_catchUp: 'number': $number < current number for $canonicalStream: ${current()}: 'number' changed to $head",
      );
    }

    final stream = await connection.readEventsAsStream(
      stream: canonicalStream,
      number: head,
    );

    // Process results as they arrive
    stream.listen((result) {
      if (result.isOK) {
        // Group events by aggregate uuid
        final eventsPerAggregate = groupBy<SourceEvent, String>(
          result.events,
          (event) => repository.toAggregateUuid(event),
        );

        // Hydrate store with events
        eventsPerAggregate.forEach(
          (uuid, events) {
            _updateAll(uuid, events);
            final domainEvents = _applyAll(
              repository,
              uuid,
              events,
            );
            // Publish remotely created events.
            // Handlers can determine events with
            // local origin using the local field
            // in each Event
            _publishAll(domainEvents);
          },
        );

        count += result.events.length;
      }
    });

    await stream.length;

    return count;
  }

  List<Event> _updateAll(String uuid, Iterable<Event> events) => _store.update(
        uuid,
        (current) => List.from(current)..addAll(events),
        ifAbsent: () => events.toList(),
      );

  EventNumber _getCanonicalNumber(Iterable<SourceEvent> events) {
    return current() +
        (useInstanceStreams
            // NOTE: event numbers in a projected stream is not
            // monotone, but event order is stable so just do
            // a 0-based increment. Since EventNumber.none.value
            // equals -1, this will account for the first event
            // when adding event.length to it.
            ? events.length
            // Event numbers in instance streams SHOULD ALWAYS
            // be sorted in an ordered monotone incrementing
            // manner. This check ensures that if and only if
            // the assumption is violated, an InvalidOperation
            // exception is thrown. This ensures that previous
            // next states can be calculated safely without any
            // risk of applying patches out-of-order, removing the
            // need to store these states in each event.
            : events
                .fold(
                  EventNumber.none,
                  _assertMonotone,
                )
                .value);
  }

  Iterable<DomainEvent> _applyAll(Repository repository, String uuid, List<SourceEvent> events) {
    final exists = repository.contains(uuid);
    final aggregate = repository.get(uuid);
    final domainEvents = events.map(repository.toDomainEvent);
    if (exists) {
      domainEvents.forEach(aggregate.apply);
    }
    // Commit remote changes
    aggregate.commit();
    // Catch up with last event in stream
    _setEventNumber(aggregate);
    return domainEvents;
  }

  /// Get events for given [AggregateRoot.uuid]
  Iterable<Event> get(String uuid) => List.from(_store[uuid] ?? []);

  /// Commit events to local storage.
  Iterable<DomainEvent> _commit(AggregateRoot aggregate, Iterable<DomainEvent> changes) {
    _assertState();
    final events = aggregate.commit(changes: changes);

    // Do not save during replay
    if (bus.replaying == false && events.isNotEmpty) {
      _updateAll(
        aggregate.uuid,
        events,
      );
      _setEventNumber(aggregate);
      // Publish locally created events.
      // Handlers can determine events with
      // local origin using the local field
      // in each Event
      _publishAll(events);
    }
    return events;
  }

  void _setEventNumber(AggregateRoot aggregate) {
    var append = 0;
    final applied = _store[aggregate.uuid];
    final stream = toInstanceStream(aggregate.uuid);
    final previous = _current[stream]?.value ?? 0;
    if (_current.containsKey(stream)) {
      append = EventNumber.none.value + applied.length - previous;
    } else {
      append = applied.length;
    }
    _current[stream] = EventNumber.none + applied.length;
    if (useInstanceStreams) {
      _current[canonicalStream] += append;
    }
  }

  /// Publish events to [bus] and [asStream]
  void _publishAll(Iterable<DomainEvent> events) {
    // Notify later but before next Future
    scheduleMicrotask(() => events.forEach(bus.publish));
    _streamController ??= StreamController.broadcast();
    events.forEach(_streamController.add);
  }

  /// Get name of aggregate instance stream for [AggregateRoot.uuid].
  String toInstanceStream(String uuid) {
    if (useInstanceStreams) {
      final index = _store.keys.toList().indexOf(uuid);
      return '${toCanonical([prefix, aggregate])}-${index < 0 ? _store.length : index}';
    }
    return canonicalStream;
  }

  /// Push given [changes] in [aggregate] to appropriate instance stream.
  ///
  /// If [snapshot] is given, this state is pushed and result
  /// applied to [aggregate] if push succeeded.
  ///
  /// Throws an [WrongExpectedEventVersion] if current event number
  /// aggregate instance stream for [aggregate] stored locally is not
  /// equal to the last event number in aggregate instance stream.
  /// This failure is recoverable when the store has caught up with
  /// all events in [canonicalStream].
  ///
  /// Throws an [WriteFailed] for all other failures. This failure
  /// is not recoverable.
  Future<Iterable<DomainEvent>> push(AggregateRoot aggregate) async {
    _assertState();
    if (aggregate.isChanged == false) {
      return [];
    }
    final stream = toInstanceStream(aggregate.uuid);
    final changes = aggregate.getUncommittedChanges();
    final number = toExpectedVersion(stream);
    final result = await connection.writeEvents(
      stream: stream,
      version: number,
      events: changes.map((e) => e.toEvent(aggregate.uuidFieldName)),
    );
    if (result.isCreated) {
      // Commit all changes after successful write
      _commit(aggregate, changes);
      // Check if commits caught up with last known event in aggregate instance stream
      _assertCurrentVersion(stream, result.actual);
      return changes;
    } else if (result.isWrongESNumber) {
      throw WrongExpectedEventVersion(
        result.reasonPhrase,
        stream: stream,
        actual: result.actual,
        expected: result.expected,
      );
    }
    throw WriteFailed(
      'Failed to push changes to $stream: '
      '${changes.map((event) => event.runtimeType)}: '
      '${result.statusCode} ${result.reasonPhrase}',
    );
  }

  /// Get expected version number for given stream.
  ///
  /// IMPORTANT: If no event number exists for given
  /// [stream], [ExpectedVersion.none] MUST BE used
  /// to ensure that only the first concurrent writer
  /// will succeed to create same instance stream.
  /// This will result in a '400 Wrong expected
  /// EventNumber' response forcing a catchup to
  /// occur before a retry is attempted with
  /// an new expected stream id created by
  /// [toInstanceStream], which is based on current
  /// aggregate count (safe since all consumers
  /// are guaranteed to receive events in same
  /// order).
  ///
  ExpectedVersion toExpectedVersion(String stream) => (_current[stream] ?? EventNumber.none).isNone
      ? ExpectedVersion.none
      : ExpectedVersion.from(
          _current[stream],
        );

  /// Subscription controller for each repository
  /// subscribing to events from [canonicalStream]
  final _subscriptions = <Type, SubscriptionController>{};

  /// Subscribe given [repository] to compete for changes from [canonicalStream]
  ///
  /// This will create a
  /// [persistent subscription group](https://eventstore.com/docs/http-api/competing-consumers/index.html)
  /// of repositories with same [Repository.aggregateType], where the
  /// name of the group is [Repository.aggregateType].
  ///
  ///
  /// Throws an [InvalidOperation] if [Repository.store] is not this [EventStore]
  /// Throws an [InvalidOperation] if [Repository] is already subscribing to events
  Future compete(
    Repository repository, {
    int consume = 20,
    ConsumerStrategy strategy = ConsumerStrategy.RoundRobin,
    Duration maxBackoffTime = const Duration(seconds: 10),
  }) async {
    // Sanity checks
    _assertState();
    _assertRepository(repository);

    // Dispose current subscription if exists
    await _subscriptions[repository.runtimeType]?.cancel();

    // Get existing or create new
    final controller = await _subscribe(
      _subscriptions[repository.runtimeType] ??
          SubscriptionController(
            logger: logger,
            onDone: _onSubscriptionDone,
            onEvent: _onSubscriptionEvent,
            onError: _onSubscriptionError,
            maxBackoffTime: maxBackoffTime,
          ),
      repository,
      competing: true,
      consume: consume,
      strategy: strategy,
    );
    _subscriptions[repository.runtimeType] = controller;
  }

  /// Subscribe given [repository] to receive changes from [canonicalStream]
  ///
  /// Throws an [InvalidOperation] if [Repository.store] is not this [EventStore]
  /// Throws an [InvalidOperation] if [Repository] is already subscribing to events
  Future subscribe(
    Repository repository, {
    Duration maxBackoffTime = const Duration(seconds: 10),
  }) async {
    // Sanity checks
    _assertState();
    _assertRepository(repository);

    // Dispose current subscription if exists
    await _subscriptions[repository.runtimeType]?.cancel();

    // Get existing or create new
    final controller = await _subscribe(
      _subscriptions[repository.runtimeType] ??
          SubscriptionController(
            logger: logger,
            onDone: _onSubscriptionDone,
            onEvent: _onSubscriptionEvent,
            onError: _onSubscriptionError,
            maxBackoffTime: maxBackoffTime,
          ),
      repository,
      competing: false,
    );
    _subscriptions[repository.runtimeType] = controller;
  }

  Future<SubscriptionController> _subscribe(
    SubscriptionController controller,
    Repository<Command, AggregateRoot> repository, {
    int consume = 20,
    bool competing = false,
    ConsumerStrategy strategy = ConsumerStrategy.RoundRobin,
  }) async =>
      competing
          ? controller.compete(
              repository,
              stream: canonicalStream,
              group: '${repository.aggregateType}',
              number: current() + 1,
              consume: consume,
              strategy: strategy,
            )
          : controller.subscribe(
              repository,
              number: current() + 1,
              stream: canonicalStream,
            );

  /// Handle event from subscriptions
  void _onSubscriptionEvent(Repository repository, SourceEvent event) {
    // Only catchup if repository have no
    // pending changes. If updated before
    // write-op is completed, a concurrent
    // write will happened and information
    // will be lost.
    if (!(repository.isProcessing || repository.isChanged)) {
      final uuid = repository.toAggregateUuid(event);

      try {
        logger.fine(
          '${repository.runtimeType}: _onSubscriptionEvent: ${event.runtimeType}'
          '{type: ${event.type}, uuid: ${event.uuid}}',
        );
        _subscriptions[repository.runtimeType]?.connected(
          repository,
          connection,
        );

        // Prepare event sourcing
        final stream = toInstanceStream(uuid);
        final actual = current(uuid: uuid);

        // Do not process own events twice unless it is one that was created by me!
        final unseen = (isEmpty || event.number > actual) && _store[uuid]?.contains(event) != true;

        logger.finer(
          '${repository.runtimeType}: _onSubscriptionEvent: '
          'process: $unseen, isEmpty: $isEmpty, '
          'current: $actual, received: ${event.number}, '
          'stream: $stream, isInstanceStream: $useInstanceStreams, numbers: $_current',
        );

        if (unseen) {
          _onUnseen(uuid, stream, event, repository);
        } else {
          _onSeen(uuid, stream, event, repository);
        }
        logger.fine(
          '${repository.runtimeType}: _onSubscriptionEvent: Processed $event',
        );
      } catch (e, stacktrace) {
        logger.network(
          'Failed to process $event for $aggregate, got error $e with stacktrace: $stacktrace',
          e,
          stacktrace,
        );
      }
    }
  }

  void _onSeen(
    String uuid,
    String stream,
    SourceEvent event,
    Repository repository,
  ) {
    // Catch up with stream
    final aggregate = repository.get(uuid);

    // Sanity check
    if (aggregate.isChanged) {
      throw InvalidOperation('Remote event $event modified $aggregate');
    }

    // Apply event with stable created date?
    final applied = aggregate.getApplied(event.uuid);
    if (applied == null) {
      throw InvalidOperation('Remote event $event not seen by $aggregate');
    }
    final domainEvent = repository.toDomainEvent(event);
    aggregate.apply(domainEvent);
  }

  void _onUnseen(
    String uuid,
    String stream,
    SourceEvent event,
    Repository repository,
  ) {
    // IMPORTANT: append to store before applying to repository
    // This ensures that the event added to an aggregate during
    // construction is overwritten with the remote actual
    // received here.
    _updateAll(uuid, [event]);

    // Catch up with stream
    final aggregate = repository.get(uuid);
    final domainEvent = repository.toDomainEvent(event);
    if (!aggregate.isApplied(event)) {
      aggregate.apply(domainEvent);
    }
    // Sanity check
    if (aggregate.isChanged) {
      throw InvalidOperation('Remote event $event modified $aggregate');
    }
    // Get last number in canonical stream
    _current[canonicalStream] = _getCanonicalNumber([event]);
    // Update last number in canonical stream
    _current[stream] = event.number;
    // Publish remotely created events.
    // Handlers can determine events with
    // local origin using the local field
    // in each Event
    _publishAll([domainEvent]);
  }

  /// Handle subscription completed
  void _onSubscriptionDone(Repository repository) {
    logger.fine('${repository.runtimeType}: subscription closed');
    if (!_disposed) {
      _subscriptions[repository.runtimeType].reconnect(
        repository,
      );
    }
  }

  /// Handle subscription errors
  void _onSubscriptionError(Repository repository, Object error, StackTrace stackTrace) {
    logger.network(
      '${repository.runtimeType}: subscription failed with: $error. stacktrace: $stackTrace',
      error,
      stackTrace,
    );
    if (!_disposed) {
      _subscriptions[repository.runtimeType].reconnect(
        repository,
      );
    }
  }

  /// When true, this store should not be used any more
  bool get disposed => _disposed;
  bool _disposed = false;

  /// Assert that this [EventStore] is not [disposed]
  void _assertState() {
    if (_disposed) {
      throw InvalidOperation('$this is disposed');
    }
  }

  /// Assert that this this [EventStore] is managed by [repository]
  void _assertRepository(Repository<Command, AggregateRoot> repository) {
    if (repository.store != this) {
      throw InvalidOperation('This $this is not managed by ${repository}');
    }
  }

  /// Assert that current event number for [stream] is caught up with last known event
  void _assertCurrentVersion(String stream, EventNumber actual) {
    if (_current[stream] < actual) {
      logger.severe(toDebugString());
      throw EventNumberMismatch(
        stream,
        _current[stream],
        actual,
        'Catch up failed',
      );
    }
  }

  EventNumber _assertMonotone(EventNumber previous, SourceEvent next) {
    if (previous.value != next.number.value - 1) {
      logger.severe(toDebugString());
      throw InvalidOperation('EventNumber not monotone increasing, current: $previous, '
          'next: ${next.number} in event ${next.type} with uuid: ${next.uuid}');
    }
    return next.number;
  }

  /// This stream will only contain [DomainEvent] pushed to remote stream
  StreamController<Event> _streamController;

  /// Get remote [Event] stream.
  Stream<Event> asStream() {
    _streamController ??= StreamController.broadcast();
    return _streamController.stream;
  }

  bool _isPaused = false;
  bool get isPaused => _isPaused;

  /// Pause all subscriptions
  void pause() async {
    _assertState();
    if (!_isPaused) {
      _isPaused = true;
      _subscriptions.values.forEach(
        (controller) => controller.pause(),
      );
    }
  }

  /// Resume all subscriptions
  void resume() async {
    _assertState();
    if (_isPaused) {
      _isPaused = false;
      _subscriptions.values.forEach(
        (controller) => controller.resume(),
      );
    }
  }

  /// Clear events in store and close connection
  Future dispose() async {
    _store.clear();

    try {
      await Future.forEach<SubscriptionController>(
        _subscriptions.values,
        (controller) => controller.cancel(),
      );
    } on ClientException catch (e, stackTrace) {
      logger.network('Failed to dispose one or more subscriptions: error: $e, stacktrace: $stackTrace', e, stackTrace);
    }

    _subscriptions.clear();
    if (_streamController?.hasListener == true && _streamController?.isClosed == false) {
      // See https://github.com/dart-lang/sdk/issues/19095#issuecomment-108436560
      // ignore: unawaited_futures
      _streamController.close();
    }
    _disposed = true;
  }

  String toDebugString() => '$runtimeType: {'
      'count: ${_store.length}, '
      'canonicalStream: $canonicalStream}, '
      'aggregates: {${_store.keys.map((uuid) => '{'
          'aggregate: $uuid, '
          'events: {count: ${_store[uuid]?.length ?? 0}, '
          'sourced: ${_store[uuid]?.map((e) => e.type)}}, '
          'instanceStream: ${toInstanceStream(uuid)}, '
          'currentEventNumber: ${current(uuid: uuid)}, '
          '}').join(', ')}}';
}

/// Class for handling a subscription with automatic reconnection on failures
class SubscriptionController<T extends Repository> {
  SubscriptionController({
    @required this.onEvent,
    @required this.onDone,
    @required this.onError,
    @required this.logger,
    this.maxBackoffTime = const Duration(seconds: 10),
  });

  /// [Logger] instance
  final Logger logger;

  final void Function(T repository) onDone;
  final void Function(T repository, SourceEvent event) onEvent;
  final void Function(T repository, Object error, StackTrace stackTrace) onError;

  /// Maximum backoff duration between reconnect attempts
  final Duration maxBackoffTime;

  /// Cancelled when store is disposed
  StreamSubscription<SourceEvent> _subscription;

  /// Reconnect count. Uses in exponential backoff calculation
  int reconnects = 0;

  /// Reference for cancelling in [cancel]
  Timer _timer;

  /// Flag indication if subscription is competing for events with other consumers
  bool get isCompeting => _competing;
  bool _competing = false;

  /// Get subscription group if competing for events
  String get group => _group;
  String _group;

  /// Event consumer strategy if subscription is competing for events with other consumers
  ConsumerStrategy get strategy => _strategy;
  ConsumerStrategy _strategy;

  /// Number of events to consume if subscription is competing for events with other consumers
  int get consume => _consume;
  int _consume;

  /// Subscribe to events from given stream.
  ///
  /// Cancels previous subscriptions if exists
  Future<SubscriptionController<T>> subscribe(
    T repository, {
    @required String stream,
    EventNumber number = EventNumber.first,
  }) async {
    await _subscription?.cancel();
    _competing = false;
    _group = null;
    _consume = null;
    _strategy = null;
    _subscription = repository.store.connection
        .subscribe(
          stream: stream,
          number: number,
        )
        .listen(
          (event) => onEvent(repository, event),
          onDone: () => onDone(repository),
          onError: (error, StackTrace stackTrace) => onError(
            repository,
            error,
            stackTrace,
          ),
        );
    logger.fine(
      '${repository.runtimeType}: Subscribed to stream $stream from event number $number',
    );
    return this;
  }

  /// Compete for events from given stream.
  ///
  /// Cancels previous subscriptions if exists
  Future<SubscriptionController<T>> compete(
    T repository, {
    @required String stream,
    @required String group,
    int consume = 20,
    EventNumber number = EventNumber.first,
    ConsumerStrategy strategy = ConsumerStrategy.RoundRobin,
  }) async {
    await _subscription?.cancel();
    _competing = true;
    _group = group;
    _consume = consume;
    _strategy = strategy;
    _subscription = repository.store.connection
        .compete(
          stream: stream,
          group: group,
          number: number,
          consume: consume,
          strategy: strategy,
        )
        .listen(
          (event) => onEvent(repository, event),
          onDone: () => onDone(repository),
          onError: (error, StackTrace stackTrace) => onError(
            repository,
            error,
            stackTrace,
          ),
        );
    logger.fine(
      '${repository.runtimeType}: Subscribed to stream $stream from event number $number',
    );
    return this;
  }

  int toNextReconnectMillis() {
    final wait = toNextTimeout(reconnects++, maxBackoffTime);
    logger.info('Wait ${wait}ms before reconnecting (attempt: $reconnects)');
    return wait;
  }

  void reconnect(T repository) async {
    if (!repository.store.connection.closed) {
      // Wait for current timer to complete
      _timer ??= Timer(
        Duration(milliseconds: toNextReconnectMillis()),
        () => _retry(repository),
      );
    }
  }

  Future _retry(T repository) async {
    try {
      _timer.cancel();
      _timer = null;
      logger.info(
        '${repository.runtimeType}: SubscriptionController is '
        'reconnecting to stream ${repository.store.canonicalStream}, attempt: $reconnects',
      );
      await _subscription?.cancel();
      if (_competing) {
        _subscription = await repository.store.compete(
          repository,
          consume: _consume,
          strategy: _strategy,
          maxBackoffTime: maxBackoffTime,
        );
      } else {
        _subscription = await repository.store.subscribe(
          repository,
          maxBackoffTime: maxBackoffTime,
        );
      }
    } catch (e, stackTrace) {
      logger.network('Failed to reconnect: $e: $stackTrace', e, stackTrace);
    }
  }

  void connected(T repository, EventStoreConnection connection) {
    if (reconnects > 0) {
      logger.info(
        '${repository.runtimeType} reconnected to '
        "'${connection.host}:${connection.port}' after ${reconnects} attempts",
      );
      reconnects = 0;
    }
  }

  bool _isPaused = false;
  bool get isPaused => _isPaused;

  void pause() {
    if (!_isPaused) {
      _isPaused = true;
      _subscription?.pause();
    }
  }

  void resume() {
    if (_isPaused) {
      _isPaused = false;
      _subscription?.resume();
    }
  }

  Future cancel() {
    _timer?.cancel();
    return _subscription?.cancel();
  }
}

// TODO: Add delete operation to EventStoreConnection

/// EventStore HTTP connection class
@sealed
class EventStoreConnection {
  EventStoreConnection({
    this.host = 'http://127.0.0.1',
    this.port = 2113,
    this.pageSize = 20,
    this.requireMaster = true,
    this.enforceAddress = true,
    this.credentials = UserCredentials.defaultCredentials,
  });

  final String host;
  final int port;
  final int pageSize;
  final bool requireMaster;
  final bool enforceAddress;
  final Client client = Client();
  final UserCredentials credentials;

  final Logger _logger = Logger('EventStoreConnection');

  /// Get atom feed from stream
  Future<FeedResult> getFeed({
    @required String stream,
    int pageSize,
    EventNumber number = EventNumber.first,
    Direction direction = Direction.forward,
    Duration waitFor = const Duration(milliseconds: 0),
  }) async {
    _assertState();
    final response = await client.get(
      '$host:$port/streams/$stream${_toFeedUri(number, direction, pageSize ?? this.pageSize)}',
      headers: {
        'Authorization': credentials.header,
        'Accept': 'application/vnd.eventstore.atom+json',
        if (waitFor.inSeconds > 0) 'ES-LongPoll': '${waitFor.inSeconds}'
      },
    );
    return FeedResult.from(
      stream: stream,
      number: number,
      direction: direction,
      response: response,
    );
  }

  String _toFeedUri(
    EventNumber number,
    Direction direction,
    int pageSize,
  ) {
    String uri;
    if (number.isFirst) {
      uri = '/0/${direction == Direction.forward ? 'forward' : 'backward'}/$pageSize';
    } else if (number.isLast) {
      uri = '/head/backward/$pageSize';
    } else {
      uri = '/${number.value}/${direction == Direction.forward ? 'forward' : 'backward'}/$pageSize';
    }
    _logger.finest(uri);
    return uri;
  }

  /// Read events in [AtomFeed.entries] and return all in one result
  Future<ReadResult> readEvents({
    @required String stream,
    EventNumber number = EventNumber.first,
    Direction direction = Direction.forward,
  }) async {
    final result = await getFeed(
      stream: stream,
      number: number,
      direction: direction,
    );
    if (result.isOK == false) {
      return ReadResult(
        stream: stream,
        atomFeed: result.atomFeed,
        statusCode: result.statusCode,
        reasonPhrase: result.reasonPhrase,
        direction: direction,
        number: number,
        events: [],
      );
    }
    return readEventsInFeed(result);
  }

  /// Read events in [AtomFeed.entries] in given [FeedResult.direction] and return all in one result
  Future<ReadResult> readEventsInFeed(FeedResult result) async {
    _assertState();

    // Fail immediately using eagerError: true
    final responses = await Future.wait(
      _getEvents(
        result.atomFeed,
        result.direction,
        result.number,
      ),
      eagerError: true,
    );
    final events = responses
        .where(
          (test) => 200 == test.statusCode,
        )
        .map((test) => json.decode(test.body))
        .map(_toEvent)
        .toList();

    return ReadResult(
      stream: result.stream,
      statusCode: events.isEmpty ? 404 : 200,
      reasonPhrase: events.isEmpty ? 'Not found' : 'OK',
      events: events,
      atomFeed: result.atomFeed,
      number: events.isEmpty ? result.number : result.number + (events.length - 1),
      direction: result.direction,
    );
  }

  SourceEvent _toEvent(data) => SourceEvent(
        uuid: data['content']['eventId'] as String,
        type: data['content']['eventType'] as String,
        streamId: data['content']['eventStreamId'] as String,
        data: data['content']['data'] as Map<String, dynamic>,
        created: DateTime.tryParse(data['updated'] as String),
        number: EventNumber(data['content']['eventNumber'] as int),
      );

  /// Read events as paged results and return results as stream
  Stream<ReadResult> readEventsAsStream({
    @required String stream,
    int pageSize = 20,
    EventNumber number = EventNumber.first,
    Direction direction = Direction.forward,
    Duration waitFor = defaultWaitFor,
  }) {
    _assertState();

    var controller = _EventStreamController(
      this,
    );

    return controller.read(
      stream: stream,
      number: number,
      waitFor: waitFor,
      pageSize: pageSize,
      direction: direction,
    );
  }

  /// Read events in [AtomFeed.entries] and return all in one result
  Future<ReadResult> readAllEvents({
    @required String stream,
    EventNumber number = EventNumber.first,
    Direction direction = Direction.forward,
  }) async {
    // Get Initial atom feed
    var feed = await getFeed(
      stream: stream,
      number: number,
      direction: direction,
    );

    if (feed.isOK == false) {
      return ReadResult(
        stream: stream,
        atomFeed: feed.atomFeed,
        statusCode: feed.statusCode,
        reasonPhrase: feed.reasonPhrase,
        direction: direction,
        number: number,
        events: [],
      );
    }

    var next;
    var result = ReadResult(
      stream: stream,
      number: number,
      direction: direction,
      statusCode: 404,
      reasonPhrase: 'Not found',
      events: [],
    );

    // Loop until all events are fetched from stream
    do {
      next = await readEventsInFeed(feed);
      if (next.isOK) {
        result = result == null ? next : result + next;
        if (hasNextFeed(result)) {
          feed = await getNextFeed(feed)
            ..assertResult();
        }
      }
    } while (next?.isOK == true && hasNextFeed(result));

    return result;
  }

  /// Check if pagination is reached its end
  bool hasNextFeed(FeedResult result) => !(result.direction == Direction.forward ? result.isHead : result.isTail);

  /// Get next [AtomFeed] from previous [FeedResult.atomFeed] in given [FeedResult.direction].
  Future<FeedResult> getNextFeed(FeedResult result) async {
    _assertState();

    return FeedResult.from(
      stream: result.stream,
      number: result.number,
      direction: result.direction,
      response: await client.get(
        _toUri(
          result.direction,
          result.atomFeed,
        ),
        headers: {
          'Authorization': credentials.header,
          'Accept': 'application/vnd.eventstore.atom+json',
        },
      ),
    );
  }

  String _toUri(Direction direction, AtomFeed atomFeed) {
    final uri = direction == Direction.forward
        ? atomFeed.getUri(AtomFeed.previous) ?? atomFeed.getUri(AtomFeed.first)
        : atomFeed.getUri(AtomFeed.next) ?? atomFeed.getUri(AtomFeed.last);
    _logger.finest(uri);
    return uri;
  }

  Iterable<Future<Response>> _getEvents(
    AtomFeed atomFeed,
    Direction direction,
    EventNumber number,
  ) {
    var entries = direction == Direction.forward ? atomFeed.entries.reversed : atomFeed.entries;
    // We do not know the EventNumber of the last event in each stream other than '/streams/{name}/head'.
    // When paginating forwards and requested number is [EventNumber.last] we will get last page of events,
    // and not only the last event which is requested. We can work around this by only returning
    // the last entry in [AtomFeed.entries] and current page is [AtomFeed.headOfStream]. This will only
    // fetch the last event from remote log.
    if (atomFeed.headOfStream && number.isLast && direction == Direction.forward) {
      entries = [entries.last];
    }
    return entries.map(
      (item) async => _getEvent(_getUri(item)),
    );
  }

  /// Get event from stream
  Future<Response> _getEvent(String url) => client.get(
        _mapUrlTo(url),
        headers: {
          'Authorization': credentials.header,
          'Accept': 'application/vnd.eventstore.atom+json',
        },
      );

  String _getUri(AtomItem item) {
    _logger.finest(item.getUri(AtomItem.alternate));
    return item.getUri(AtomItem.alternate);
  }

  Future<WriteResult> writeEvents({
    @required String stream,
    @required Iterable<Event> events,
    ExpectedVersion version = ExpectedVersion.any,
  }) async {
    _assertState();
    final eventIds = <String>[];
    final data = events.map(
      (event) => {
        'eventId': _uuid(eventIds, event),
        'eventType': event.type,
        'data': event.data,
      },
    );
    final url = _toStreamUri(stream);
    final body = json.encode(data.toList());
    final headers = {
      'Authorization': credentials.header,
      'ES-RequireMaster': '$requireMaster',
      'ES-ExpectedVersion': '${version.value}',
      'Content-type': 'application/vnd.eventstore.events+json',
    };
    final response = await client.post(
      url,
      headers: headers,
      body: body,
    );
    if (response.statusCode != HttpStatus.temporaryRedirect) {
      return WriteResult.from(
        stream,
        version,
        eventIds,
        response,
      );
    }
    final redirected = await client.post(
      response.headers['location'],
      headers: headers,
      body: body,
    );
    return WriteResult.from(
      stream,
      version,
      eventIds,
      redirected,
    );
  }

  String _toStreamUri(String stream) => '$host:$port/streams/$stream';

  String _uuid(List<String> eventIds, Event event) {
    eventIds.add(event.uuid);
    return event.uuid;
  }

  /// Subscribe to [SourceEvent]s from given [stream]
  Stream<SourceEvent> subscribe({
    @required String stream,
    EventNumber number = EventNumber.last,
    Duration waitFor = defaultWaitFor,
    Duration pullEvery = defaultPullEvery,
  }) {
    _assertState();

    var controller = _SubscriptionController(
      this,
    );

    return controller.pull(
      stream: stream,
      number: number,
      waitFor: waitFor,
      pullEvery: pullEvery,
    );
  }

  /// Compete for [SourceEvent]s from given [stream]
  Stream<SourceEvent> compete({
    @required String stream,
    @required String group,
    int consume = 20,
    bool accept = true,
    EventNumber number = EventNumber.last,
    ConsumerStrategy strategy = ConsumerStrategy.RoundRobin,
    Duration pullEvery = defaultPullEvery,
  }) {
    _assertState();

    var controller = _SubscriptionController(
      this,
    );

    return controller.consume(
      stream: stream,
      group: group,
      accept: accept,
      number: number,
      pageSize: consume,
      strategy: strategy,
      pullEvery: pullEvery,
    );
  }

  /// Get feed for persistent subscription group.
  ///
  /// Will attempt to create subscription group if not found.
  Future<FeedResult> getSubscriptionFeed({
    @required String stream,
    @required String group,
    @required EventNumber number,
    int consume = 20,
    ConsumerStrategy strategy = ConsumerStrategy.RoundRobin,
  }) async {
    final response = await _getSubscriptionGroup(stream, group, consume);
    switch (response.statusCode) {
      case HttpStatus.ok:
        return FeedResult.from(
          stream: stream,
          number: number,
          subscription: group,
          response: response,
        );
        break;
      case HttpStatus.notFound:
        final result = await createSubscription(
          stream,
          group,
          number: number,
          strategy: strategy,
        );
        if (result.isCreated || result.isConflict) {
          return FeedResult.from(
              stream: stream,
              number: number,
              subscription: group,
              response: await _getSubscriptionGroup(stream, group, consume));
        }
        break;
    }
    return FeedResult.from(
      stream: stream,
      number: number,
      subscription: group,
      response: response,
    );
  }

  /// Create a persistent subscription.
  ///
  /// Before interacting with a subscription group, you need to create one.
  /// You will receive an error if you attempt to create a subscription group more than once.
  Future<SubscriptionResult> createSubscription(
    String stream,
    String group, {
    EventNumber number = EventNumber.first,
    Duration timeout = const Duration(seconds: 1),
    ConsumerStrategy strategy = ConsumerStrategy.RoundRobin,
  }) async {
    final url = _mapUrlTo('$host:$port/subscriptions/$stream/$group');
    final result = await client.put(url,
        headers: {
          'Authorization': credentials.header,
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'startFrom': number.value,
          // IMPORTANT: This will resolve to events instead of atom items in subscription stream
          'resolveLinktos': true,
          'namedConsumerStrategy': enumName(strategy),
          'messageTimeoutMilliseconds': timeout.inMilliseconds,
        }));
    return SubscriptionResult.from(
      stream: stream,
      group: group,
      number: number,
      strategy: strategy,
      response: result,
    );
  }

  Future<Response> _getSubscriptionGroup(String stream, String group, int count) {
    final url = _mapUrlTo('$host:$port/subscriptions/$stream/$group/$count');
    return client.get(
      url,
      headers: {
        'Authorization': credentials.header,
        'Accept': 'application/vnd.eventstore.competingatom+json',
      },
    );
  }

  /// Acknowledge multiple messages
  ///
  /// Clients must acknowledge (or not acknowledge) messages in the competing consumer model.
  /// If the client fails to respond in the given timeout period, the message will be retried.
  Future<SubscriptionResult> writeSubscriptionAck({
    @required String stream,
    @required String group,
    @required List<SourceEvent> events,
  }) =>
      _writeSubscriptionAnswer(stream, group, events, nack: false);

  /// Acknowledge all messages in [SubscriptionFeed]
  ///
  /// Clients must acknowledge (or not acknowledge) messages in the competing consumer model.
  /// If the client fails to respond in the given timeout period, the message will be retried.
  Future<SubscriptionResult> writeSubscriptionAckAll(FeedResult feed) async {
    final url = feed.atomFeed.getUri('ackAll');
    final response = await client.post(
      url,
      headers: {
        'Authorization': credentials.header,
      },
    );
    return SubscriptionResult.from(
      stream: feed.stream,
      group: feed.subscription,
      response: response,
    );
  }

  /// Negative acknowledge multiple messages
  ///
  /// Clients must acknowledge (or not acknowledge) messages in the competing consumer model.
  /// If the client fails to respond in the given timeout period, the message will be retried.
  Future<SubscriptionResult> writeSubscriptionNack({
    @required String stream,
    @required String group,
    @required List<SourceEvent> events,
    SubscriptionAction action = SubscriptionAction.Retry,
  }) =>
      _writeSubscriptionAnswer(stream, group, events, nack: true);

  /// Acknowledge multiple messages
  ///
  /// Clients must acknowledge (or not acknowledge) messages in the competing consumer model.
  /// If the client fails to respond in the given timeout period, the message will be retried.
  Future<SubscriptionResult> _writeSubscriptionAnswer(
    String stream,
    String group,
    List<SourceEvent> events, {
    bool nack = false,
    SubscriptionAction action = SubscriptionAction.Retry,
  }) async {
    final answer = nack ? 'nack' : 'ack';
    final ids = events.map((event) => event.uuid).join(',');
    final nackAction = nack ? '?action=${enumName(action)}' : '';
    final url = '$host:$port/subscriptions/$stream/$group/$answer?ids=$ids$nackAction';
    final result = await client.post(
      url,
      headers: {
        'Authorization': credentials.header,
//        'Content-Type': 'application/json',
      },
    );
    return SubscriptionResult.from(
      stream: stream,
      group: group,
      response: result,
    );
  }

  /// Read state of projection [name]
  Future<ProjectionResult> projectionCommand({
    @required String name,
    @required ProjectionCommand command,
  }) async {
    final url = '$host:$port/projection/$name/command/${enumName(command)}';
    final result = await client.post(
      url,
      headers: {
        'Authorization': credentials.header,
        'Accept': 'application/json',
      },
    );
    return ProjectionResult.from(
      name: name,
      response: result,
    );
  }

  /// Read state of projection [name]
  Future<ProjectionResult> readProjection({
    @required String name,
  }) async {
    final result = await client.get(
      '$host:$port/projection/$name',
      headers: {
        'Authorization': credentials.header,
        'Accept': 'application/json',
      },
    );
    return ProjectionResult.from(
      name: name,
      response: result,
    );
  }

  /// When true, this store should not be used any more
  bool get closed => _closed;
  bool _closed = false;
  void _assertState() {
    if (_closed) {
      throw InvalidOperation('$this is closed');
    }
  }

  /// Close connection.
  ///
  /// This [EventStoreConnection] instance should be disposed afterwards.
  void close() {
    _closed = true;
    client.close();
  }

  @override
  String toString() {
    return 'EventStoreConnection{host: $host, port: $port, pageSize: $pageSize}';
  }

  String _mapUrlTo(String url) {
    if (enforceAddress) {
      var uri = Uri.parse(url);
      final host = uri.host;
      if (uri.hasPort) {
        final next = url.replaceFirst('${uri.scheme}://$host:${uri.port}', '${this.host}:$port');
        return next;
      }
      return url.replaceFirst('$host', '${this.host}:$port');
    }
    return url;
  }
}

class _EventStreamController {
  _EventStreamController(this.connection) : logger = connection._logger;

  final Logger logger;
  final EventStoreConnection connection;

  int _pageSize;
  int get pageSize => _pageSize;

  String _stream;
  String get stream => _stream;

  Duration _waitFor;
  Duration get waitFor => _waitFor;

  EventNumber _number;
  EventNumber get number => _number;

  Direction _direction;
  Direction get direction => _direction;

  EventNumber _current;
  EventNumber get current => _current;

  bool _pause = true;

  StreamController<ReadResult> _controller;
  StreamController<ReadResult> get controller => _controller;

  Stream<ReadResult> read({
    @required String stream,
    int pageSize = 20,
    bool broadcast = true,
    EventNumber number = EventNumber.first,
    Direction direction = Direction.forward,
    Duration waitFor = defaultWaitFor,
  }) {
    // Setup
    _stream = stream;
    _number = number;
    _current = number;
    _waitFor = waitFor;
    _pageSize = pageSize;
    _direction = direction;

    _controller?.close();
    _controller = broadcast
        ? StreamController<ReadResult>.broadcast(
            onListen: _startRead,
            onCancel: _stopRead,
          )
        : StreamController<ReadResult>(
            onPause: _pauseRead,
            onCancel: _stopRead,
            onListen: _startRead,
            onResume: _startRead,
          );
    return controller.stream;
  }

  void _startRead() async {
    try {
      logger.fine(
        _pause
            ? 'Started reading events from $stream@$_number in direction $_direction'
            : 'Resumed reading events from $stream@$_current in direction $_direction',
      );
      _pause = false;

      FeedResult feed;
      do {
        if (!_pause) {
          feed = await _readNext();
        }
      } while (feed != null && feed.isOK && !(feed.headOfStream || feed.isEmpty));

      _stopRead();
    } catch (e, stackTrace) {
      _fatal(
        'Failed to read stream $_stream@$_number in direction $_direction',
        e,
        stackTrace,
      );
    }
  }

  Future<FeedResult> _readNext() async {
    final feed = await _nextFeed();
    if (feed.isNotEmpty) {
      await _readEventsInFeed(feed);
    }
    return feed;
  }

  void _pauseRead() {
    _pause = true;
    logger.fine('Paused reading events from stream $_stream');
  }

  void _stopRead() {
    if (_controller != null) {
      logger.fine('Stopped reading events from stream $_stream@$_current');
      _controller.close();
      _controller = null;
    }
  }

  Future _readEventsInFeed(FeedResult feed) async {
    if (feed.isOK) {
      final result = await connection.readEventsInFeed(feed);
      if (result.isOK) {
        if (result.isNotEmpty) {
          final next = result.number + 1;
          _current = next;
          // Notify when all actions are done
          controller.add(result);

          logger.fine(
            'Read up to $_stream@${next.value - 1}, listening for $next',
          );
        }
      } else {
        _fatal(
          'Failed to read events from $_stream@$_current: ${result.statusCode} ${result.reasonPhrase}',
          '${result.statusCode} ${result.reasonPhrase}',
          StackTrace.current,
        );
      }
      return result;
    }
    _fatal(
      'Failed to read feed from $_stream@$_current: ${feed.statusCode} ${feed.reasonPhrase}',
      '${feed.statusCode} ${feed.reasonPhrase}',
      StackTrace.current,
    );
    return feed;
  }

  Future<FeedResult> _nextFeed() => connection.getFeed(
        stream: stream,
        number: current,
        direction: Direction.forward,
        waitFor: waitFor,
        pageSize: _pageSize,
      );

  void _fatal(String message, Object error, StackTrace stackTrace) {
    _controller.addError(error, stackTrace);
    logger.severe(
      '$message: $error: $stackTrace',
    );
    _stopRead();
  }
}

/// User credentials required by event store endpoint
class UserCredentials {
  const UserCredentials({
    this.login,
    this.password,
  });

  static const defaultCredentials = UserCredentials(
    login: 'admin',
    password: 'changeit',
  );

  final String login;
  final String password;

  String get header => "Basic ${base64.encode(utf8.encode("$login:$password"))}";
}

/// Projection command enum
enum ProjectionCommand {
  /// Enable the specified projection.
  ///
  /// When enabling is complete status will be 'Running'
  enable,

  /// Disable the specified projection
  ///
  /// When disabling is complete status will be 'Stopped'
  disable,

  /// Reset the specified projection
  ///
  /// This is an unsafe operation. Any previously emitted
  /// events will be emitted again to the same streams and
  /// handled by their subscribers
  reset,

  /// Abort the specified projection.
  abort,
}

/// EventStore supported consumer strategies for use with persistent subscriptions.
enum ConsumerStrategy {
  /// Distribute events to each client in a
  /// round robin fashion.
  RoundRobin,

//  /// Distributes events to a single client until is
//  /// is full. Then round robin to the next client.
//  DispatchToSingle,
//
//  /// Distribute events of the same streamId to the
//  /// same client until it disconnects on a best efforts
//  /// basis. Designed to be used with indexes such as the
//  /// category projection.
//  Pinned,
}

/// Subscription actions when not accepting consumed events from a subscription
enum SubscriptionAction {
  /// Retry the message on next incoming consumption
  Retry,

//  /// Don't retry the message, park it until a request is sent to reply the parked messages
//  Park,
//
//  /// Discard the message for all consumers
//  Skip,
//
//  /// Stop the subscription for all consumers
//  Stop
}

class _SubscriptionController {
  _SubscriptionController(this.connection) : logger = connection._logger;

  final Logger logger;
  final EventStoreConnection connection;

  int _pageSize;
  int get pageSize => _pageSize;

  String _stream;
  String get stream => _stream;

  String _group;
  String get group => _group;

  Duration _waitFor;
  Duration get waitFor => _waitFor;

  Duration _pullEvery;
  Duration get pullEvery => _pullEvery;

  EventNumber _number;
  EventNumber get number => _number;

  bool _accept;
  bool get accept => _accept;

  EventNumber _current;
  EventNumber get current => _current;

  ConsumerStrategy _strategy;
  ConsumerStrategy get strategy => _strategy;

  StreamController<SourceEvent> _controller;
  StreamController<SourceEvent> get controller => _controller;

  Timer _timer;

  bool _isCatchup;

  /// Queue of [_SubscriptionRequest]s executed in FIFO manner.
  ///
  /// This queue ensures that each command is processed in order
  /// waiting for the previous request has completed. This
  /// is need because the [Timer] class will not block on
  /// await in it't callback method.
  final _requestQueue = ListQueue<_SubscriptionRequest>();

  Stream<SourceEvent> pull({
    @required String stream,
    EventNumber number = EventNumber.last,
    Duration waitFor = defaultWaitFor,
    Duration pullEvery = defaultPullEvery,
  }) {
    // Setup
    _accept = false;
    _stream = stream;
    _number = number;
    _current = number;
    _waitFor = waitFor;
    _pullEvery = pullEvery;

    // catchup before consuming from head of stream?
    _isCatchup = false == number.isLast;

    _controller?.close();
    _controller = StreamController<SourceEvent>(
      onListen: _startTimer,
      onPause: _stopTimer,
      onResume: _startTimer,
      onCancel: _stopTimer,
    );

    return controller.stream;
  }

  Stream<SourceEvent> consume({
    @required String stream,
    @required String group,
    int pageSize = 20,
    bool accept = true,
    EventNumber number = EventNumber.last,
    ConsumerStrategy strategy = ConsumerStrategy.RoundRobin,
    Duration pullEvery = defaultPullEvery,
  }) {
    // Setup
    _group = group;
    _stream = stream;
    _accept = accept;
    _number = number;
    _current = number;
    _strategy = strategy;
    _pageSize = pageSize;
    _pullEvery = pullEvery;

    // catchup before consuming from head of stream?
    _isCatchup = false == number.isLast;

    _controller?.close();
    _controller = StreamController<SourceEvent>(
      onListen: _startTimer,
      onResume: _startTimer,
      onPause: _stopTimer,
      onCancel: _stopTimer,
    );

    return controller.stream;
  }

  void _startTimer() async {
    try {
      logger.fine(
        'Started ${_strategy == null ? 'pull' : enumName(_strategy)} subscription on stream: $stream',
      );
      if (_isCatchup) {
        await _catchup(controller);
        _isCatchup = false;
      }
      _timer = Timer.periodic(
        pullEvery,
        (_) {
          // Timer could will fire before previous read has completed
          if (_requestQueue.isEmpty) {
            _schedule<FeedResult>(_readNext);
            scheduleMicrotask(_process);
          }
        },
      );
      logger.fine(
        'Listen for events in subscription $name starting from number $_current',
      );
    } catch (e, stackTrace) {
      // Only throw if running
      if (_timer != null && _timer.isActive) {
        _fatal('Failed to catchup to head of stream $name', e, stackTrace);
      }
    }
  }

  void _schedule<T>(Future<T> Function() execute) {
    _requestQueue.add(
      _SubscriptionRequest<T>(execute),
    );
  }

  /// Execute [_SubscriptionRequest] in FIFO-manner until empty
  void _process() async {
    while (_requestQueue.isNotEmpty) {
      final request = _requestQueue.first;
      try {
        await request();
      } catch (e, stackTrace) {
        _fatal('Failed to execute $request', e, stackTrace);
      }
      // Only remove after execution is completed
      _requestQueue.remove(request);
    }
  }

  void _fatal(String message, Exception e, StackTrace stackTrace) {
    _stopTimer();
    controller.addError(e, stackTrace);
    logger.severe(
      '$message: $e: $stackTrace',
    );
  }

  void _stopTimer() {
    logger.fine('Stop timer for $name');
    _timer?.cancel();
    _timer = null;
  }

  Future _catchup(StreamController<SourceEvent> controller) async {
    logger.fine(
      'Stream $stream catch up from event number $_current',
    );

    FeedResult feed;
    do {
      feed = await _readNext();
    } while (feed != null && feed.isOK && !(feed.headOfStream || feed.isEmpty));

    if (number < _current) {
      logger.fine(
        'Subscription $name caught up from $number to $_current',
      );
    }
    return _current;
  }

  String get name => [stream, if (group != null) group].join('/');

  Future<FeedResult> _readNext() async {
    FeedResult feed;
    try {
      feed = await _nextFeed();
      if (feed.isNotEmpty) {
        await _readEventsInFeed(feed);
      }
    } catch (e, stackTrace) {
      // Only throw if running
      if (_timer != null && _timer.isActive) {
        _stopTimer();
        controller.addError(e, stackTrace);
        logger.network(
          'Failed to read next events for $name: $e: $stackTrace',
          e,
          stackTrace,
        );
      }
    }
    return feed;
  }

  Future<ReadResult> _readEventsInFeed(FeedResult feed) async {
    if (feed.isOK) {
      final result = await connection.readEventsInFeed(feed);
      if (result.isOK && result.isNotEmpty) {
        final next = result.number + 1;
        logger.fine(
          'Subscription $name caught up to event $_current, listening for $next',
        );
        _current = next;

        if (accept) {
          await _acceptEvents(feed);
        }

        // Notify when all actions are done
        result.events.forEach(
          controller.add,
        );
      } else {
        logger.fine(
          'Failed to read events in $name from $_current: ${result.statusCode} ${result.reasonPhrase}',
        );
      }
      return result;
    }
    return null;
  }

  Future<FeedResult> _nextFeed() => strategy == ConsumerStrategy.RoundRobin
      ? connection.getSubscriptionFeed(
          stream: stream,
          group: group,
          number: current,
          consume: pageSize,
          strategy: strategy,
        )
      : connection.getFeed(
          stream: stream,
          number: current,
          direction: Direction.forward,
          waitFor: waitFor,
        );

  Future<SubscriptionResult> _acceptEvents(FeedResult feed) async {
    final answer = await connection.writeSubscriptionAckAll(feed);
    if (answer.isAccepted == false) {
      throw SubscriptionFailed(
        'Failed to accept events in for $name: '
        '${answer.statusCode} ${answer.reasonPhrase}',
      );
    }
    return answer;
  }
}

class _SubscriptionRequest<T> {
  _SubscriptionRequest(this.execute);
  final Completer completer = Completer();
  final Future<T> Function() execute;

  Future<T> call() async {
    var response;
    try {
      response = await execute();
      completer.complete(response);
    } catch (e, stackTrace) {
      completer.completeError(e, stackTrace);
    }
    return response;
  }

  @override
  String toString() {
    return '_SubscriptionRequest{execute: $execute}';
  }
}

int toNextTimeout(int reconnects, Duration maxBackoffTime, {int exponent = 2}) {
  final wait = min(
    pow(exponent, reconnects++).toInt() + Random().nextInt(1000),
    maxBackoffTime.inMilliseconds,
  );
  return wait;
}
