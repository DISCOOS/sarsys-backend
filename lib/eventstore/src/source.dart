import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart';
import 'package:meta/meta.dart';
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

  /// Dispose all event stores
  void dispose() {
    _stores.values.forEach(
      (store) => store.dispose(),
    );
    _stores.clear();
  }

  /// Get repository from [Type]
  Repository<T> get<T extends AggregateRoot>() => _stores.keys.whereType<Repository<T>>()?.first;
}

/// Storage class managing events locally in memory received from event store server
@sealed
class EventStore {
  EventStore({
    @required this.stream,
    @required this.bus,
    @required this.connection,
  });
  final String stream;
  final MessageBus bus;
  final EventStoreConnection connection;
  final _store = <String, List<Event>>{};
  final _pending = <String, List<Event>>{};

  /// Replay events from events for given repository
  Future replay(Repository repository) async {
    try {
      bus.replayStarted();
      // Fetch atom feed for stream and fetch all events in it
      final feed = await connection.getFeed(
        stream: stream,
        direction: Direction.backward,
      );
      if (feed.isOK) {
        final result = await connection.readAllEvents(
          stream: stream,
          atomFeed: feed.atomFeed,
        );
        // Rebuild local event store
        _store.clear();
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
        // This will recreate aggregates stored in repository and republish events
        _store.keys
          ..forEach(
            (uuid) => repository.get(uuid),
          )
          ..forEach(
            (uuid) => _publish(_store[uuid]),
          );
        // Flush changes accumulated during replay
        repository.commitAll();
      }
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
  Iterable<Event> commit(AggregateRoot aggregate) {
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
  }
}

/// EventStore HTTP connection class
class EventStoreConnection {
  EventStoreConnection({
    this.host = 'http://127.0.0.1',
    this.port = 2113,
  });

  final String host;
  final int port;
  final Client client = Client();

  Future<FeedResult> getFeed({
    @required String stream,
    EventNumber number = EventNumber.first,
    Direction direction = Direction.backward,
    UserCredentials credentials = UserCredentials.defaultCredentials,
  }) async =>
      FeedResult.from(
        stream: stream,
        number: number,
        direction: direction,
        response: await client.get(
          "$host:$port/streams/$stream${_toPageUri(number, direction)}",
          headers: {
            'Authorization': credentials.header,
            'Accept': 'application/vnd.eventstore.atom+json',
          },
        ),
      );

  String _toPageUri(
    EventNumber number,
    Direction direction,
  ) {
    String uri;
    if (number.isFirst)
      uri = '';
    else if (number.isLast)
      uri = '/head/backward/20';
    else
      uri = '/${number.value}/${direction == Direction.forward ? 'forward' : 'backward'}/20';
    return uri;
  }

  Future<ReadResult> readAllEvents({
    @required String stream,
    @required AtomFeed atomFeed,
    UserCredentials credentials = UserCredentials.defaultCredentials,
  }) async {
    final requests = _toRequests(atomFeed, Direction.forward, credentials);
    final responses = await Future.wait(requests);
    final events = responses
        .where((test) => 200 == test.statusCode)
        .map((test) => json.decode(test.body))
        .map((data) => Event(
              uuid: data['content']['eventId'] as String,
              type: data['content']['eventType'] as String,
              data: data['content']['data'] as Map<String, dynamic>,
            ))
        .toList();

    return ReadResult(
      stream: stream,
      statusCode: 200,
      reasonPhrase: 'OK',
      events: events,
    );
  }

  String _toUri(Direction direction, AtomFeed atomFeed) {
    return direction == Direction.backward
        ? atomFeed.getUri(AtomFeed.last) ?? atomFeed.getUri(AtomFeed.next)
        : atomFeed.getUri(AtomFeed.first) ?? atomFeed.getUri(AtomFeed.previous);
  }

  Iterable<Future<Response>> _toRequests(
    AtomFeed atomFeed,
    Direction direction,
    UserCredentials credentials,
  ) {
    return (direction == Direction.forward ? atomFeed.entries.reversed : atomFeed.entries).map(
      (item) async => client.get(
        item.getUri(AtomItem.alternate),
        headers: {
          'Authorization': credentials.header,
          'Accept': 'application/vnd.eventstore.atom+json',
        },
      ),
    );
  }

  Future<WriteResult> writeEvents({
    @required String stream,
    @required Iterable<Event> events,
    UserCredentials credentials = UserCredentials.defaultCredentials,
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
      "$host:$port/streams/$stream",
      headers: {
        'Authorization': credentials.header,
        'Content-type': 'application/vnd.eventstore.events+json',
      },
      body: json.encode(body.toList()),
    );
    return WriteResult.from(stream, eventIds, response);
  }

  String _uuid(List<String> eventIds, Event event) {
    eventIds.add(event.uuid);
    return event.uuid;
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
    this.events = const <Event>[],
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
                .map((event) => Event(
                      uuid: event['eventid'] as String,
                      type: event['eventtype'] as String,
                      data: event['data'] as Map<String, dynamic>,
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

  /// Events read from stream
  final List<Event> events;
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
  })  : number = EventNumber(value: number),
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
