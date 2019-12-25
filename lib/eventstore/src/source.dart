import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart';
import 'package:meta/meta.dart';
import 'package:logging/logging.dart';
import 'package:sarsys_app_server/eventstore/eventstore.dart';

import 'core.dart';

/// [EventStore] manager class. Use this to manage sourcing of multiple event streams
@sealed
class EventStoreManager {
  EventStoreManager(
    this.bus,
    this.connection,
  );

  final MessageBus bus;
  final EventStoreConnection connection;

  final Map<Repository, EventStore> _stores = {};

  /// Register [Repository] with given [AggregateRoot].
  void register<T extends AggregateRoot>(Repository create(EventStore store)) {
    final repository = create(EventStore(
      bus: bus,
      connection: connection,
      stream: typeOf<T>().toKebabCase(),
    ));
    _stores.putIfAbsent(
      repository,
      () => EventStore(
        bus: bus,
        connection: connection,
        stream: T.toKebabCase(),
      ),
    );
  }

  /// Build all repositories from event stores
  Future build() async {
    await Future.wait(_stores.keys.map(
      (repository) => repository.build(),
    ));
  }

  /// Dispose all repositories and stores
  void dispose() {
    _stores.forEach((repository, store) {
      store.dispose();
      repository.dispose();
    });
    _stores.clear();
  }

  /// Get repository from [Type]
  Repository<T> get<T extends AggregateRoot>() => _stores.keys.whereType<Repository<T>>()?.first;
}

/// Base class for source events
class SourceEvent extends Event {
  const SourceEvent({
    @required String uuid,
    @required String type,
    @required this.number,
    @required Map<String, dynamic> data,
  }) : super(
          uuid: uuid,
          type: type,
          data: data,
        );
  final EventNumber number;
}

/// Storage class managing events locally in memory received from event store server
@sealed
class EventStore {
  EventStore({
    @required this.stream,
    @required this.bus,
    @required this.connection,
  }) : logger = Logger("EventStore:$stream");

  final String stream;
  final Logger logger;
  final MessageBus bus;
  final EventStoreConnection connection;
  final _store = <String, List<Event>>{};
  final _pending = <String, List<Event>>{};

  EventNumber current = EventNumber.first;
  StreamSubscription<Event> _subscription;

  /// Replay events from stream to given repository
  Future<Iterable<Event>> replay(Repository repository) async {
    try {
      Iterable<Event> events = [];

      bus.replayStarted();

      // Fetch all events
      final result = await connection.readAllEvents(
        stream: stream,
      );

      if (result.isOK) {
        _store.clear();

        // Get current event number, TODO: move to unit test?
        current = result.events.fold(EventNumber.none, _assertMonotone);

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
        events = repository.commitAll();

        logger.info("Replayed ${result.events.length} events from stream '${result.stream}'");
      }
      return events;
    } finally {
      bus.replayEnded();
    }
  }

  /// Get events for given [AggregateRoot.uuid]
  Iterable<Event> get(String uuid) => _store[uuid] ?? [];

  /// Get all uuids
  Iterable<String> uuids() => _store.keys.toList();

  /// Commit events to local storage.
  ///
  /// Returns true if changes was saved, false otherwise
  Iterable<DomainEvent> commit(AggregateRoot aggregate) {
    final events = aggregate.commit();
    // Do not save during replay
    if (bus.replaying == false && events.isNotEmpty) {
      // Update local event store
      _update(aggregate, events, _store);
      // Append to events pending push to remote event store
      _update(aggregate, events, _pending);
      // Notify event handlers
      _publish(events);
    }
    return events;
  }

  /// Push changes to remote event store for given aggregate
  Future<Iterable<Event>> push(Iterable<AggregateRoot> aggregates) async {
    // Collect pending events for given aggregates
    final events = aggregates.fold(
      <Event>[],
      (events, aggregate) => <Event>[...events, ..._pending[aggregate.uuid] ?? []],
    );
    final result = await connection.writeEvents(
      stream: stream,
      events: events,
    );
    if (result.isCreated) {
      // Remove changes
      aggregates.forEach((aggregate) => _pending.remove(aggregate.uuid));
      return events;
    }
    throw PushFailed("Failed to push changes: ${result.statusCode} ${result.reasonPhrase}");
  }

  void _publish(Iterable<Event> events) => events.forEach(bus.publish);

  void _update(
    AggregateRoot aggregate,
    Iterable<Event> events,
    Map<String, List<Event>> store,
  ) =>
      store.update(
        aggregate.uuid,
        (stored) => stored..addAll(events),
        ifAbsent: events.toList,
      );

  /// Clear events in store and close connection
  void dispose() {
    _store.clear();
    _subscription?.cancel();
  }

  EventNumber _assertMonotone(EventNumber previous, SourceEvent next) {
    if (previous.value >= next.number.value) {
      throw InvalidOperation("EventNumber not monotone increasing, current: $previous, "
          "next: ${next.number} in event ${next.type} with uuid: ${next.uuid}");
    }
    return next.number;
  }
}

/// EventStore HTTP connection class
class EventStoreConnection {
  EventStoreConnection({
    this.host = 'http://127.0.0.1',
    this.port = 2113,
    this.pageSize = 20,
    this.credentials = UserCredentials.defaultCredentials,
    String logger = 'eventstore',
  }) : _logger = Logger(logger);

  final String host;
  final int port;
  final int pageSize;
  final Client client = Client();
  final UserCredentials credentials;

  final Logger _logger;

  /// Get atom feed from stream
  Future<FeedResult> getFeed({
    @required String stream,
    EventNumber number = EventNumber.first,
    Direction direction = Direction.forward,
    Duration waitFor = const Duration(milliseconds: 0),
  }) async =>
      FeedResult.from(
        stream: stream,
        number: number,
        direction: direction,
        response: await client.get(
          "$host:$port/streams/$stream${_toFeedUri(number, direction)}",
          headers: {
            'Authorization': credentials.header,
            'Accept': 'application/vnd.eventstore.atom+json',
            if (waitFor.inSeconds > 0) 'ES-LongPoll': '${waitFor.inSeconds}'
          },
        ),
      );

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
    _logger.fine(uri);
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
      );
    }
    return readEventsInFeed(result);
  }

  /// Read events in [AtomFeed.entries] in given [FeedResult.direction] and return all in one result
  Future<ReadResult> readEventsInFeed(FeedResult result) async {
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
    )
      ..assertResult();

    // Loop until all events are fetched from stream
    ReadResult result, next;
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
  Future<FeedResult> getNextFeed(FeedResult result) async => FeedResult.from(
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

  String _toUri(Direction direction, AtomFeed atomFeed) {
    final uri = direction == Direction.forward
        ? atomFeed.getUri(AtomFeed.previous) ?? atomFeed.getUri(AtomFeed.first)
        : atomFeed.getUri(AtomFeed.next) ?? atomFeed.getUri(AtomFeed.last);
    _logger.fine(uri);
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
    _logger.fine(item.getUri(AtomItem.alternate));
    return item.getUri(AtomItem.alternate);
  }

  Future<WriteResult> writeEvents({
    @required String stream,
    @required Iterable<Event> events,
  }) async {
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
      },
      body: json.encode(body.toList()),
    );
    return WriteResult.from(stream, eventIds, response);
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
              "Failed to read events: ${result.statusCode} ${result.assertResult()}",
            );
          }
          for (var e in result.events) {
            yield e;
          }
          current = result.number;
        }
      } while (feed.isOK && !feed.atomFeed.headOfStream);

      // Move one more event forward
      current = current + 1;
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
            "Failed to read head of stream $stream: ${result.statusCode} ${result.assertResult()}",
          );
        }
      }
    }
  }

  void close() {
    client.close();
  }
}

/// Stream result class
abstract class Result {
  Result({
    @required this.stream,
    @required this.statusCode,
    @required this.reasonPhrase,
    this.eTag,
  });

  /// Event stream
  final String stream;

  /// The status code of the response.
  final int statusCode;

  /// The reason phrase associated with the status code.
  final String reasonPhrase;

  /// ETAG in header - pass to server with If-None-Match which returns 304 not modified it stream is unchanged
  final String eTag;

  @override
  String toString() {
    return '{stream: $stream, statusCode: $statusCode, reasonPhrase: $reasonPhrase, eTag: $eTag}';
  }
}

/// Class with AtomFeed result for given stream
class FeedResult extends Result {
  FeedResult({
    @required String stream,
    @required int statusCode,
    @required String reasonPhrase,
    String eTag,
    this.number,
    this.direction,
    this.atomFeed,
  }) : super(
          stream: stream,
          statusCode: statusCode,
          reasonPhrase: reasonPhrase,
          eTag: eTag,
        );

  factory FeedResult.from({
    String stream,
    EventNumber number,
    Direction direction,
    Response response,
  }) {
    switch (response.statusCode) {
      case 200:
        return FeedResult(
          stream: stream,
          statusCode: response.statusCode,
          reasonPhrase: response.reasonPhrase,
          eTag: response.headers['etag'],
          number: number,
          direction: direction,
          atomFeed: AtomFeed.fromJson(json.decode(response.body) as Map<String, dynamic>),
        );
      default:
        return FeedResult(
          stream: stream,
          statusCode: response.statusCode,
          reasonPhrase: response.reasonPhrase,
          eTag: response.headers['etag'],
        );
    }
  }

  /// Current event number
  final EventNumber number;

  /// Event traversal direction
  final Direction direction;

  /// Atom feed data
  final AtomFeed atomFeed;

  /// Check if 200 OK
  bool get isOK => statusCode == 200;

  /// Check if 304 Not modified
  bool get isNotModified => statusCode == 304;

  /// Check if 404 Not found
  bool get isNotFound => statusCode == 404;

  /// Check if head (last page) of stream is reached
  bool get isHead => atomFeed.headOfStream;

  /// Check if tail (first page) of stream is reached
  bool get isTail => !atomFeed.has(AtomFeed.next);

  FeedResult assertResult() {
    if (isOK == false) {
      throw FeedFailed("Failed to get atom feed because: ${statusCode} ${reasonPhrase}");
    }
    return this;
  }
}

/// Query result class
class ReadResult extends FeedResult {
  ReadResult({
    @required String stream,
    @required int statusCode,
    @required String reasonPhrase,
    String eTag,
    AtomFeed atomFeed,
    EventNumber number,
    Direction direction = Direction.backward,
    this.events = const <SourceEvent>[],
  }) : super(
          stream: stream,
          statusCode: statusCode,
          reasonPhrase: reasonPhrase,
          atomFeed: atomFeed,
          eTag: eTag,
          number: number,
          direction: direction,
        );

  factory ReadResult.from({
    String stream,
    AtomFeed atomFeed,
    EventNumber number,
    Direction direction,
    Response response,
  }) {
    switch (response.statusCode) {
      case 200:
        final events = json.decode(response.body) as Map<String, dynamic>;
        return ReadResult(
            stream: stream,
            statusCode: response.statusCode,
            reasonPhrase: response.reasonPhrase,
            eTag: response.headers['etag'],
            atomFeed: atomFeed,
            number: number,
            direction: direction,
            events: (events['entries'] as List)
                .map((event) => SourceEvent(
                      uuid: event['eventid'] as String,
                      type: event['eventtype'] as String,
                      data: event['data'] as Map<String, dynamic>,
                      number: EventNumber(event['eventNumber'] as int),
                    ))
                .toList());
      default:
        return ReadResult(
          stream: stream,
          statusCode: response.statusCode,
          reasonPhrase: response.reasonPhrase,
          eTag: response.headers['etag'],
        );
    }
  }

  /// Append results together
  ReadResult operator +(ReadResult result) => ReadResult(
        stream: result.stream,
        atomFeed: result.atomFeed,
        direction: result.direction,
        statusCode: result.statusCode,
        reasonPhrase: result.reasonPhrase,
        events: events..addAll(result.events),
      );

  /// Events read from stream
  final List<SourceEvent> events;
}

/// Command result class
class WriteResult extends Result {
  WriteResult({
    @required String stream,
    @required int statusCode,
    @required String reasonPhrase,
    this.eventIds = const [],
    this.location,
    int number,
  })  : number = EventNumber(number),
        super(
          stream: stream,
          statusCode: statusCode,
          reasonPhrase: reasonPhrase,
        );

  factory WriteResult.from(String stream, List<String> eventIds, Response response) {
    switch (response.statusCode) {
      case 201:
        return WriteResult(
          stream: stream,
          statusCode: response.statusCode,
          reasonPhrase: response.reasonPhrase,
          location: response.headers['location'],
          eventIds: eventIds,
          number: _toNumber(response),
        );
      default:
        return WriteResult(
          stream: stream,
          statusCode: response.statusCode,
          reasonPhrase: response.reasonPhrase,
        );
    }
  }

  /// Ids of created events
  final List<String> eventIds;

  /// Last event number on stream
  final EventNumber number;

  /// Url to written event
  final String location;

  /// Check if 201 Created
  bool get isCreated => statusCode == 201;

  static int _toNumber(Response response) => int.parse(response.headers['location'].split('/')?.last);

  @override
  String toString() {
    return 'WriteResult{stream: $stream, statusCode: $statusCode, '
        'reasonPhrase: $reasonPhrase, number: $number, location: $location}';
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
