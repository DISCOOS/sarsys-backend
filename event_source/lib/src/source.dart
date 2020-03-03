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
import 'domain.dart';
import 'models/AtomFeed.dart';
import 'models/AtomItem.dart';
import 'results.dart';

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

  /// Current event number for [canonicalStream]
  ///
  /// If [AggregateRoot.uuid] is given, the aggregate
  /// instance stream number is returned. This numbers
  /// is the same as for the [canonicalStream] if
  /// [useInstanceStreams] is false.
  ///
  /// If [stream] is given, this takes precedence and returns event number this stream.
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
    final next = current() + 1;
    final count = await _catchUp(repository, next);
    logger.info("Catched up on $count events from stream '${canonicalStream}' starting from number $next");
    return count;
  }

  /// Catch up with stream from given number
  Future<int> _catchUp(Repository repository, EventNumber number) async {
    // Lower bound is last known event number in stream
    final head = EventNumber(max(current().value, number.value));
    if (head > number) {
      logger.fine(
        "_catchUp: 'number': $number < current number for $canonicalStream: ${current()}: 'number' changed to $head",
      );
    }

    // TODO: Read events as stream - implement readEventsAsStream
    final result = await connection.readAllEvents(
      stream: canonicalStream,
      number: head,
    );

    if (result.isOK) {
      // Catch-up with last event number in canonical stream
      _current[canonicalStream] = _getCanonicalNumber(result.events);

      // Group events by aggregate uuid
      final eventsPerAggregate = groupBy<SourceEvent, String>(
        result.events,
        (event) => repository.toAggregateUuid(event),
      );

      // Hydrate store with events
      eventsPerAggregate.forEach(
        (uuid, events) {
          _update(uuid, events);
          _apply(repository, uuid, events);
          _publish(events.map(repository.toDomainEvent));
        },
      );

      logger.fine(
        '_catchUp: Current event number for $canonicalStream: ${current()}',
      );
    }
    return result.events.length;
  }

  List<Event> _update(String uuid, Iterable<Event> events) => _store.update(
        uuid,
        (events) => List.from(events)..addAll(events),
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
            // manner
            : events
                .fold(
                  EventNumber.none,
                  _assertMonotone,
                )
                .value);
  }

  void _apply(Repository repository, String uuid, List<SourceEvent> events) {
    final exists = repository.contains(uuid);
    final aggregate = repository.get(uuid);
    final domainEvents = events.map(repository.toDomainEvent);
    if (exists) {
      domainEvents.forEach(aggregate.apply);
    }
    // Commit remote changes
    aggregate.commit();
    // Catch up with last event in stream
    _setEventNumber(aggregate, domainEvents);
  }

  /// Get events for given [AggregateRoot.uuid]
  Iterable<Event> get(String uuid) => _store[uuid] ?? [];

  /// Commit events to local storage.
  Iterable<DomainEvent> commit(AggregateRoot aggregate) {
    _assertState();
    final events = aggregate.commit();

    // Do not save during replay
    if (bus.replaying == false && events.isNotEmpty) {
      _update(
        aggregate.uuid,
        events,
      );
      _setEventNumber(aggregate, events);
      _publish(events);
    }
    return events;
  }

  void _setEventNumber(AggregateRoot aggregate, Iterable<Event> events) {
    final stream = toInstanceStream(aggregate.uuid);
    if (_current.containsKey(stream)) {
      final applied = _store[aggregate.uuid];
      final unique = events.toList()..removeWhere(applied.contains);
      _current[stream] += unique.length;
    } else {
      _current[stream] = EventNumber.none + events.length;
    }
  }

  /// Publish events to [bus] and [asStream]
  void _publish(Iterable<DomainEvent> events) {
    events.forEach(bus.publish);
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

  /// Push changes in [aggregate] to to appropriate instance stream.
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
    final events = aggregate.getUncommittedChanges();
    final result = await connection.writeEvents(
      stream: stream,
      events: events,
      version: _toExpectedVersion(stream),
    );
    if (result.isCreated) {
      // Commit all changes after successful write
      commit(aggregate);
      // Check if commits caught up with last known event in aggregate instance stream
      _assertCurrentVersion(stream, result.version);
      return events;
    } else if (result.isWrongESNumber) {
      throw WrongExpectedEventVersion(
        result.reasonPhrase,
        expected: result.version,
        actual: result.number,
      );
    }
    throw WriteFailed('Failed to push changes to $stream: ${result.statusCode} ${result.reasonPhrase}');
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
  ExpectedVersion _toExpectedVersion(String stream) => (_current[stream] ?? EventNumber.none).isNone
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
  void compete(
    Repository repository, {
    int consume = 20,
    ConsumerStrategy strategy = ConsumerStrategy.RoundRobin,
    Duration maxBackoffTime = const Duration(seconds: 10),
  }) {
    // Sanity checks
    _assertState();
    _assertRepository(repository);

    // Dispose current subscription if exists
    _subscriptions[repository.runtimeType]?.dispose();

    _subscriptions.update(
      repository.runtimeType,
      (controller) => _subscribe(
        controller,
        repository,
        competing: true,
        consume: consume,
        strategy: strategy,
      ),
      ifAbsent: () => _subscribe(
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
      ),
    );
  }

  /// Subscribe given [repository] to receive changes from [canonicalStream]
  ///
  /// Throws an [InvalidOperation] if [Repository.store] is not this [EventStore]
  /// Throws an [InvalidOperation] if [Repository] is already subscribing to events
  void subscribe(
    Repository repository, {
    Duration maxBackoffTime = const Duration(seconds: 10),
  }) {
    // Sanity checks
    _assertState();
    _assertRepository(repository);

    // Dispose current subscription if exists
    _subscriptions[repository.runtimeType]?.dispose();

    _subscriptions.update(
      repository.runtimeType,
      (controller) => _subscribe(
        controller,
        repository,
        competing: false,
      ),
      ifAbsent: () => _subscribe(
        SubscriptionController(
          logger: logger,
          onDone: _onSubscriptionDone,
          onEvent: _onSubscriptionEvent,
          onError: _onSubscriptionError,
          maxBackoffTime: maxBackoffTime,
        ),
        repository,
        competing: false,
      ),
    );
  }

  SubscriptionController _subscribe(
    SubscriptionController controller,
    Repository<Command, AggregateRoot> repository, {
    int consume = 20,
    bool competing = false,
    ConsumerStrategy strategy = ConsumerStrategy.RoundRobin,
  }) =>
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
      final uuid = repository.toAggregateUuid(event);
      final stream = toInstanceStream(uuid);
      final actual = current(uuid: uuid);
      final process = isEmpty || event.number > actual;
      logger.finer(
        '${repository.runtimeType}: _onSubscriptionEvent: '
        'process: $process, isEmpty: $isEmpty, '
        'current: $actual, received: ${event.number}, '
        'stream: $stream, isInstanceStream: $useInstanceStreams, numbers: $_current',
      );

      if (process) {
        final uuid = repository.toAggregateUuid(event);

        // IMPORTANT: append to store before applying to repository
        // This ensures that the event added to an aggregate during
        // construction is overwritten with the remote actual
        // received here.
        _update(uuid, [event]);

        // Catch up with stream
        final aggregate = repository.get(uuid);
        if (aggregate.isApplied(event) == false) {
          aggregate.apply(
            repository.toDomainEvent(event),
          );
        }
        if (aggregate.isChanged) {
          final events = commit(aggregate);
          if (events.length > 1) {
            throw InvalidOperation('One source event produced ${events.length} domain events');
          }
        } else {
          // Get last number in canonical stream
          _current[canonicalStream] = _getCanonicalNumber([event]);
          // Update last number in canonical stream
          _current[stream] = event.number;
          // Notify listeners
          _publish([repository.toDomainEvent(event)]);
        }
        logger.fine(
          '${repository.runtimeType}: _onSubscriptionEvent: Processed $event',
        );
      }
    } catch (e, stacktrace) {
      logger.severe('Failed to process $event, got error $e with stacktrace: $stacktrace');
    }
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
  void _onSubscriptionError(Repository repository, dynamic error, StackTrace stackTrace) {
    logger.severe(
      '${repository.runtimeType}: subscription failed with: $error. stactrace: $stackTrace',
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
  void _assertCurrentVersion(String stream, ExpectedVersion version) {
    if (_current[stream] != EventNumber.from(version)) {
      throw WriteFailed('Catch up failed, current ${_current[stream]?.value} not equal to version ${version?.value}');
    }
  }

  /// This stream will only contain [DomainEvent] pushed to remote stream
  StreamController<Event> _streamController;

  /// Get remote [Event] stream.
  Stream<Event> asStream() {
    _streamController ??= StreamController.broadcast();
    return _streamController.stream;
  }

  /// Clear events in store and close connection
  void dispose() {
    _store.clear();
    _subscriptions.values.forEach((state) => state.dispose());
    _subscriptions.clear();
    _streamController?.close();
    _disposed = true;
  }

  EventNumber _assertMonotone(EventNumber previous, SourceEvent next) {
    if (previous.value != next.number.value - 1) {
      throw InvalidOperation('EventNumber not monotone increasing, current: $previous, '
          'next: ${next.number} in event ${next.type} with uuid: ${next.uuid}');
    }
    return next.number;
  }
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
  final void Function(T repository, dynamic error, StackTrace stackTrace) onError;

  /// Maximum backoff duration between reconnect attempts
  final Duration maxBackoffTime;

  /// Cancelled when store is disposed
  StreamSubscription<SourceEvent> _subscription;

  /// Reconnect count. Uses in exponential backoff calculation
  int reconnects = 0;

  /// Reference for cancelling in [dispose]
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
  SubscriptionController<T> subscribe(
    T repository, {
    @required String stream,
    EventNumber number = EventNumber.first,
  }) {
    _subscription?.cancel();
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
          onError: (error, trace) => onError(repository, error, trace),
        );
    logger.fine('${repository.runtimeType}: Subscribed to stream $stream from event number $number');
    return this;
  }

  /// Compete for events from given stream.
  ///
  /// Cancels previous subscriptions if exists
  SubscriptionController<T> compete(
    T repository, {
    @required String stream,
    @required String group,
    int consume = 20,
    EventNumber number = EventNumber.first,
    ConsumerStrategy strategy = ConsumerStrategy.RoundRobin,
  }) {
    _subscription?.cancel();
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
          onError: (error, trace) => onError(repository, error, trace),
        );
    logger.fine('${repository.runtimeType}: Subscribed to stream $stream from event number $number');
    return this;
  }

  int toNextReconnectMillis() => min(
        pow(2, reconnects++).toInt() + Random().nextInt(1000),
        maxBackoffTime.inMilliseconds,
      );

  void reconnect(T repository) {
    _subscription.cancel();
    if (!repository.store.connection.closed) {
      _timer ??= Timer(
        Duration(milliseconds: toNextReconnectMillis()),
        () {
          _timer.cancel();
          _timer = null;
          logger.info(
            '${repository.runtimeType}: $runtimeType is reconnecting to stream ${repository.store.canonicalStream}',
          );
          if (_competing) {
            repository.store.compete(
              repository,
              consume: _consume,
              strategy: _strategy,
              maxBackoffTime: maxBackoffTime,
            );
          } else {
            repository.store.subscribe(
              repository,
              maxBackoffTime: maxBackoffTime,
            );
          }
        },
      );
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

  void dispose() {
    _timer?.cancel();
    _subscription?.cancel();
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
    this.credentials = UserCredentials.defaultCredentials,
  });

  final String host;
  final int port;
  final int pageSize;
  final Client client = Client();
  final UserCredentials credentials;

  final Logger _logger = Logger('EventStoreConnection');

  /// Get atom feed from stream
  Future<FeedResult> getFeed({
    @required String stream,
    EventNumber number = EventNumber.first,
    Direction direction = Direction.forward,
    Duration waitFor = const Duration(milliseconds: 0),
  }) async {
    _assertState();
    final response = await client.get(
      '$host:$port/streams/$stream${_toFeedUri(number, direction)}',
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

    ReadResult next,
        result = ReadResult(
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
        url,
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
    final body = json.encode(data.toList());
    final response = await client.post(
      _toStreamUri(stream),
      headers: {
        'Authorization': credentials.header,
        'Content-type': 'application/vnd.eventstore.events+json',
        'ES-ExpectedVersion': '${version.value}'
      },
      body: body,
    );
    return WriteResult.from(stream, version, eventIds, response);
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
    Duration waitFor = const Duration(milliseconds: 1500),
    Duration pullEvery = const Duration(milliseconds: 500),
  }) async* {
    _assertState();
    var current = number;

    // Catch-up subscription?
    if (false == current.isLast) {
      _logger.fine('Stream $stream catch up from event number $current');
      FeedResult feed;
      do {
        feed = await getFeed(
          stream: stream,
          number: current,
          direction: Direction.forward,
        );
        if (feed.isOK) {
          final result = await readEventsInFeed(feed);
          if (result.isOK) {
            for (var e in result.events) {
              yield e;
            }
            current = result.number + 1;
          }
        }
      } while (feed.isOK && !feed.atomFeed.headOfStream);

      if (number < current) {
        _logger.fine('Stream $stream caught up from $number to $current');
      }
    }

    _logger.fine('Listen for events in $stream starting from number $current');

    // Continues until StreamSubscription.cancel() is invoked
    await for (var request in Stream.periodic(
      pullEvery,
      (_) => getFeed(
        stream: stream,
        number: current,
        direction: Direction.forward,
        waitFor: waitFor,
      ),
    )) {
      final feed = await request;
      if (feed.isOK) {
        final result = await readEventsInFeed(feed);
        if (result.isOK) {
          for (var e in result.events) {
            yield e;
          }
          final next = result.number + 1;
          _logger.fine('Stream $stream caught up to event $current, listening for $next');
          current = next;
        } else if (!result.isNotFound) {
          throw SubscriptionFailed(
            'Failed to read head of stream $stream: ${result.statusCode} ${result.reasonPhrase}',
          );
        }
      }
    }
  }

  /// Compete for [SourceEvent]s from given [stream]
  Stream<SourceEvent> compete({
    @required String stream,
    @required String group,
    int consume = 20,
    bool accept = true,
    EventNumber number = EventNumber.last,
    ConsumerStrategy strategy = ConsumerStrategy.RoundRobin,
    Duration pullEvery = const Duration(milliseconds: 500),
  }) async* {
    _assertState();
    var current = number;

    // Catch-up subscription?
    if (false == current.isLast) {
      _logger.fine('Stream $stream catch up from event number $current');
      FeedResult feed;
      do {
        feed = await getSubscriptionFeed(
          stream: stream,
          group: group,
          number: current,
          consume: consume,
        );
        if (feed.isOK) {
          final result = await readEventsInFeed(feed);
          if (result.isOK) {
            if (accept) {
              await _acceptEvents(
                stream,
                group,
                result,
              );
            }
            for (var e in result.events) {
              yield e;
            }
            current = result.number + 1;
          }
        }
      } while (feed.isOK && !feed.atomFeed.headOfStream);

      if (number < current) {
        _logger.fine('Subscription $stream/$group caught up from $number to $current');
      }
    }

    _logger.fine('Listen for events in subscription $stream/$group starting from number $current');

    // Continues until StreamSubscription.cancel() is invoked
    await for (var request in Stream.periodic(
      pullEvery,
      (_) => getSubscriptionFeed(
        stream: stream,
        group: group,
        number: current,
        consume: consume,
      ),
    )) {
      final feed = await request;
      if (feed.isOK) {
        final result = await readEventsInFeed(feed);
        if (result.isOK) {
          if (accept) {
            await _acceptEvents(
              stream,
              group,
              result,
            );
          }
          for (var e in result.events) {
            yield e;
          }
          final next = result.number + 1;
          _logger.fine('Subscription $stream/$group caught up to event $current, listening for $next');
          current = next;
        } else if (!result.isNotFound) {
          throw SubscriptionFailed(
            'Failed to read head of subscription $stream/$group: ${result.statusCode} ${result.reasonPhrase}',
          );
        }
      }
    }
  }

  Future _acceptEvents(String stream, String group, ReadResult result) async {
    final answer = await writeSubscriptionAck(
      stream: stream,
      group: group,
      events: result.events,
    );
    if (answer.isAccepted == false) {
      throw SubscriptionFailed(
        'Failed to accept ${result.events.length} events in $stream/$group: '
        '${answer.statusCode} ${answer.reasonPhrase}',
      );
    }
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
    Duration timeout = const Duration(microseconds: 10000),
    ConsumerStrategy strategy = ConsumerStrategy.RoundRobin,
  }) async {
    final result = await client.put('$host:$port/subscriptions/$stream/$group',
        headers: {
          'Authorization': credentials.header,
          'Accept': ' application/vnd.eventstore.competingatom+json',
        },
        body: json.encode({
          'startFrom': number.value,
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

  Future<Response> _getSubscriptionGroup(String stream, String group, int count) => client.get(
        '$host:$port/subscriptions/$stream/$group/$count',
        headers: {
          'Authorization': credentials.header,
          'Accept': ' application/vnd.eventstore.competingatom+json',
        },
      );

  /// Acknowledge multiple messages
  ///
  /// Clients must acknowledge (or not acknowledge) messages in the competing consumer model.
  /// If the client fails to respond in the given timeout period, the message will be retried.
  Future<SubscriptionResult> writeSubscriptionAck({
    @required String stream,
    @required String group,
    @required List<SourceEvent> events,
  }) async =>
      await _writeSubscriptionAnswer(stream, group, events, nack: false);

  /// Negative acknowledge multiple messages
  ///
  /// Clients must acknowledge (or not acknowledge) messages in the competing consumer model.
  /// If the client fails to respond in the given timeout period, the message will be retried.
  Future<SubscriptionResult> writeSubscriptionNack({
    @required String stream,
    @required String group,
    @required List<SourceEvent> events,
    SubscriptionAction action = SubscriptionAction.Retry,
  }) async =>
      await _writeSubscriptionAnswer(stream, group, events, nack: true);

  /// Negative acknowledge multiple messages
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
