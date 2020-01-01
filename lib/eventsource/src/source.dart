import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:http/http.dart';
import 'package:meta/meta.dart';
import 'package:logging/logging.dart';

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
  /// Parameter [stream] is required. It defines which
  /// [AggregateRoot] stream to source events from.
  ///
  /// Parameter [prefix] is optional. If given,
  /// it is concatenated with [stream] using
  /// `EventStore.toCanonical([prefix, stream])` which
  /// returns a canonical stream name of colon-delimited
  /// stream segments.
  ///
  /// Parameter [useAggregateStreams] controls how this
  /// repository is writing events for each [AggregateRoot]
  /// instance.
  ///
  /// If true, events for each [AggregateRoot] is
  /// written to a separate aggregate instance stream. Each
  /// instance streams are identified by concatenating
  /// [prefix], [stream] and [AggregateRoot.uuid] using
  /// `EventStore.toCanonical([prefix, stream, uuid])`.
  ///
  /// This is the default behavior since it will minimize
  /// write contention an hence reduce the number of
  /// [WrongExpectedEventVersion] thrown by method [push].
  ///
  /// [EventStore] uses the system projection
  /// [$stream_by_category](https://eventstore.org/docs/projections/system-projections/index.html?tabs=tabid-5#stream-by-category)
  /// to project all stream instances of a [canonicalStream]
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
    @required this.stream,
    @required this.connection,
    this.prefix,
    this.useAggregateStreams = true,
  }) : logger = Logger("EventStore[${toCanonical([prefix, stream])}]");

  /// Get canonical stream name
  static String toCanonical(List<String> segments) => segments
      .where(
        (test) => test?.trim()?.isNotEmpty == true,
      )
      .join(':');

  String get canonicalStream => toCanonical([prefix, stream]);

  /// Stream prefix
  final String prefix;

  /// Stream name
  final String stream;

  /// If true, eventstore will write events for each
  /// [AggregateRoot] instance to a separate stream
  final bool useAggregateStreams;

  /// [MessageBus] instance
  final MessageBus bus;

  /// [Logger] instance
  final Logger logger;

  /// [EventStoreConnection] instance
  final EventStoreConnection connection;

  /// [Map] of events for each aggregate root sourced from stream
  final _store = <String, List<Event>>{};

  /// [Map] of events from aggregate roots pending push to stream
  //final _pending = <String, List<Event>>{};

  /// Current event number in store
  EventNumber get current => _current;
  EventNumber _current = EventNumber.none;

  /// Check if store is empty
  bool get isEmpty => _store.isEmpty;

  /// Check if store is not empty
  bool get isNotEmpty => _store.isNotEmpty;

  /// Replay events from stream to given repository
  ///
  /// Throws an [InvalidOperation] if [Repository.store] is not this [EventStore]
  Future<int> replay(Repository repository) async {
    // Sanity checks
    _assertState();
    _assertRepository(repository);

    try {
      bus.replayStarted();

      // Fetch all events
      return _catchUp(
        repository,
        EventNumber.first,
      );
    } finally {
      bus.replayEnded();
    }
  }

  /// Catch up with stream
  Future<int> catchUp(Repository repository) async => _catchUp(repository, _current + 1);

  /// Catch up with stream from given number
  Future<int> _catchUp(Repository repository, EventNumber number) async {
    // TODO: Read events as string - implement readEventsAsStream
    final result = await connection.readAllEvents(
      stream: canonicalStream,
      number: number,
    );

    if (result.isOK) {
      _store.clear();

      // Catch-up with last event number in stream
      _current = result.events.fold(
        EventNumber.none,
        _assertMonotone,
      );

      // Hydrate event store with events
      result.events
          .where(
            (event) => repository.toAggregateUuid(event) is String,
          )
          .forEach(
            (event) => _store.update(
              repository.toAggregateUuid(event),
              (events) => events..add(event),
              ifAbsent: () => [event],
            ),
          );

      // This will recreate aggregates and republish events
      _store.keys
        ..forEach(
          (uuid) => repository.get(uuid),
        )
        ..forEach(
          (uuid) => _publish(_store[uuid]),
        );

      // Flush events accumulated during replay
      repository.commitAll();

      logger.info("Replayed ${result.events.length} events from stream '${canonicalStream}'");
    }
    return result.events.length;
  }

  /// Get events for given [AggregateRoot.uuid]
  Iterable<Event> get(String uuid) => _store[uuid] ?? [];

  /// Commit events to local storage.
  Iterable<DomainEvent> commit(AggregateRoot aggregate) {
    _assertState();
    final events = aggregate.commit();

    // Do not save during replay
    if (bus.replaying == false && events.isNotEmpty) {
      _store.update(
        aggregate.uuid,
        (stored) => stored..addAll(events),
        ifAbsent: events.toList,
      );
      _current += events.length;
      _publish(events);
    }
    return events;
  }

  /// Publish events to [bus]
  void _publish(Iterable<Event> events) => events.forEach(bus.publish);

  /// Push changes in [aggregates] to [canonicalStream]
  ///
  /// Throws an [WrongExpectedEventVersion] if [current] event number is not
  /// equal to the last event number in  [canonicalStream]. This failure is
  /// recoverable when the store has caught up with [canonicalStream].
  ///
  /// Throws an [WriteFailed] for all other failures. This failure is not
  /// recoverable.
  Future<Iterable<Event>> push(Iterable<AggregateRoot> aggregates) async {
    _assertState();
    // Collect events pending commit for given aggregates
    final events = aggregates.fold(
      <Event>[],
      (events, aggregate) => <DomainEvent>[...events, ...aggregate.getUncommittedChanges() ?? []],
    );
    if (events.isEmpty) {
      return events;
    }
    final result = await connection.writeEvents(
      stream: canonicalStream,
      events: events,
      version: _current == EventNumber.none ? ExpectedVersion.any : ExpectedVersion.from(_current),
    );
    if (result.isCreated) {
      // Commit all changes after successful write
      aggregates.forEach(commit);
      // Check if commits caught up with last known event in stream
      _assertCurrentVersion(result.version);
      return events;
    } else if (result.isWrongESNumber) {
      throw WrongExpectedEventVersion(result.reasonPhrase, result.version);
    }
    throw WriteFailed("Failed to push changes: ${result.statusCode} ${result.reasonPhrase}");
  }

  /// Subscription controller for each repository
  /// subscribing to events from [canonicalStream]
  final _subscriptions = <Type, _SubscriptionController>{};

  /// Subscribe given [repository] to receive changes from [canonicalStream]
  ///
  /// Throws an [InvalidOperation] if [Repository.store] is not this [EventStore]
  /// Throws an [InvalidOperation] if [Repository] is already subscribing to events
  void subscribe(
    Repository repository, {
    Duration maxBackoffTime = const Duration(seconds: 10),
  }) async {
    // Sanity checks
    _assertState();
    _assertRepository(repository);

    _subscriptions.update(
      repository.runtimeType,
      (controller) => controller.subscribe(
        repository,
        current,
        connection,
        canonicalStream,
      ),
      ifAbsent: () => _SubscriptionController(
        logger: logger,
        onDone: _onSubscriptionDone,
        onEvent: _onSubscriptionEvent,
        onError: _onSubscriptionError,
        maxBackoffTime: maxBackoffTime,
      )..subscribe(
          repository,
          current,
          connection,
          canonicalStream,
        ),
    );
  }

  /// Handle event from subscriptions
  void _onSubscriptionEvent(Repository repository, SourceEvent event) {
    try {
      _subscriptions[repository.runtimeType]?.connected(
        repository,
        connection,
      );
      if (isEmpty || event.number > _current) {
        // Get and commit changes
        final aggregate = repository.get(
          repository.toAggregateUuid(event),
          data: event.data,
        );
        if (aggregate.isChanged == false) {
          if (aggregate.isApplied(event) == false) {
            aggregate.patch(event.data);
          }
        }
        if (aggregate.isChanged) {
          // This will catch up with stream
          final events = commit(aggregate);
          if (events.length > 1) {
            throw InvalidOperation("One source event produced ${events.length} domain events");
          }
        } else {
          // Catch up with stream
          _current = event.number;
        }
      }
    } catch (e) {
      logger.severe("Failed to process ${event.type}{uuid: ${event.uuid}}, got $e");
    }
  }

  /// Handle subscription completed
  void _onSubscriptionDone(Repository repository) {
    logger.fine("${repository.runtimeType} subscription closed");
    if (!_disposed) {
      _subscriptions[repository.runtimeType].reconnect(
        repository,
        this,
      );
    }
  }

  /// Handle subscription errors
  void _onSubscriptionError(Repository repository, error) {
    logger.severe("${repository.runtimeType} subscription failed with: $error");

    if (!(error is SocketException)) {
      print(error);
    }

    if (!_disposed) {
      _subscriptions[repository.runtimeType].reconnect(
        repository,
        this,
      );
    }
  }

  /// When true, this store should not be used any more
  bool get disposed => _disposed;
  bool _disposed = false;

  /// Assert that this [EventStore] is not [disposed]
  void _assertState() {
    if (_disposed) {
      throw InvalidOperation("$this is disposed");
    }
  }

  /// Assert that this this [EventStore] is managed by [repository]
  void _assertRepository(Repository<Command, AggregateRoot> repository) {
    if (repository.store != this) {
      throw InvalidOperation("This $this is not managed by ${repository}");
    }
  }

  /// Assert that [current] event number is caught up with last known event in stream
  void _assertCurrentVersion(ExpectedVersion version) {
    if (_current != EventNumber.from(version)) {
      throw WriteFailed("Catch up failed, current ${_current.value} not equal to version ${version.value}");
    }
  }

  /// Clear events in store and close connection
  void dispose() {
    _store.clear();
    _subscriptions.values.forEach((state) => state.dispose());
    _subscriptions.clear();
    _disposed = true;
  }

  EventNumber _assertMonotone(EventNumber previous, SourceEvent next) {
    if (previous.value >= next.number.value) {
      throw InvalidOperation("EventNumber not monotone increasing, current: $previous, "
          "next: ${next.number} in event ${next.type} with uuid: ${next.uuid}");
    }
    return next.number;
  }
}

class _SubscriptionController {
  _SubscriptionController({
    this.logger,
    this.onEvent,
    this.onDone,
    this.onError,
    this.maxBackoffTime,
  });

  /// [Logger] instance
  final Logger logger;

  final void Function(Repository repository) onDone;
  final void Function(Repository repository, SourceEvent event) onEvent;
  final void Function(Repository repository, dynamic error) onError;

  /// Maximum backoff duration between reconnect attempts
  final Duration maxBackoffTime;

  /// Cancelled when store is disposed
  StreamSubscription<SourceEvent> _subscription;

  /// Reconnect count. Uses in exponential backoff calculation
  int reconnects = 0;

  /// Reference for cancelling in [dispose]
  Timer _timer;

  /// Subscribe to events from given stream.
  ///
  /// Cancels previous subscriptions if exists
  _SubscriptionController subscribe(
    Repository repository,
    EventNumber current,
    EventStoreConnection connection,
    String stream,
  ) {
    _subscription?.cancel();
    _subscription = connection
        .subscribe(
          stream: stream,
          number: current,
        )
        .listen(
          (event) => onEvent(repository, event),
          onDone: () => onDone(repository),
          onError: (error) => onError(repository, error),
        );
    return this;
  }

  int toNextReconnectMillis() => min(
        pow(2, reconnects++).toInt() + Random().nextInt(1000),
        maxBackoffTime.inMilliseconds,
      );

  void reconnect(Repository repository, EventStore store) {
    _subscription.cancel();
    if (!store.connection.closed) {
      _timer ??= Timer(
        Duration(milliseconds: toNextReconnectMillis()),
        () {
          _timer.cancel();
          _timer = null;
          store.subscribe(
            repository,
            maxBackoffTime: maxBackoffTime,
          );
        },
      );
    }
  }

  void connected(Repository repository, EventStoreConnection connection) {
    if (reconnects > 0) {
      logger.info(
        "${repository.runtimeType} reconnected at "
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

  final Logger _logger = Logger("EventStoreConnection");

  /// Get atom feed from stream
  Future<FeedResult> getFeed({
    @required String stream,
    EventNumber number = EventNumber.first,
    Direction direction = Direction.forward,
    Duration waitFor = const Duration(milliseconds: 0),
  }) async {
    _assertState();
    final response = await client.get(
      "$host:$port/streams/$stream${_toFeedUri(number, direction)}",
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
    if (number.isFirst)
      uri = '/0/${direction == Direction.forward ? 'forward' : 'backward'}/$pageSize';
    else if (number.isLast)
      uri = '/head/backward/$pageSize';
    else
      uri = '/${number.value}/${direction == Direction.forward ? 'forward' : 'backward'}/$pageSize';
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
      number: events.isEmpty ? result.number : events.last.number,
      direction: result.direction,
    );
  }

  SourceEvent _toEvent(data) => SourceEvent(
        uuid: data['content']['eventId'] as String,
        type: data['content']['eventType'] as String,
        data: data['content']['data'] as Map<String, dynamic>,
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
      reasonPhrase: "Not found",
      events: [],
    );

    // Loop until all events are fetched from stream
    do {
      next = await readEventsInFeed(feed);
      if (next.isOK) {
        result = result == null ? next : result + next;
        if (hasNextFeed(result))
          feed = await getNextFeed(feed)
            ..assertResult();
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
    final body = events.map(
      (event) => {
        'eventId': _uuid(eventIds, event),
        'eventType': event.type,
        "data": event.data,
      },
    );
    final response = await client.post(
      _toStreamUri(stream),
      headers: {
        'Authorization': credentials.header,
        'Content-type': 'application/vnd.eventstore.events+json',
        'ES-ExpectedVersion': '${version.value}'
      },
      body: json.encode(body.toList()),
    );
    return WriteResult.from(stream, version, eventIds, response);
  }

  String _toStreamUri(String stream) => "$host:$port/streams/$stream";

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
    if (!current.isLast) {
      FeedResult feed;
      do {
        feed = await getFeed(
          stream: stream,
          number: current,
          direction: Direction.forward,
        );
        if (feed.isOK) {
          final result = await readEventsInFeed(feed);
          if (!result.isOK) {
            throw SubscriptionFailed(
              "Failed to read events: ${result.statusCode} ${result.reasonPhrase}",
            );
          }
          for (var e in result.events) {
            yield e;
          }
          current = result.number;
        }
      } while (feed.isOK && !feed.atomFeed.headOfStream);

      // Move one more event forward?
      if (current.value > 0) {
        current = current + 1;
      }
    }

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
      if (feed.statusCode == 200) {
        final result = await readEventsInFeed(feed);
        if (result.isOK) {
          for (var e in result.events) {
            yield e;
          }
          current = result.number + 1;
        } else if (!result.isNotFound) {
          throw SubscriptionFailed(
            "Failed to read head of stream $stream: ${result.statusCode} ${result.reasonPhrase}",
          );
        }
      }
    }
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

  /// When true, this store should not be used any more
  bool get closed => _closed;
  bool _closed = false;
  void _assertState() {
    if (_closed) {
      throw InvalidOperation("$this is closed");
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
    login: "admin",
    password: "changeit",
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
