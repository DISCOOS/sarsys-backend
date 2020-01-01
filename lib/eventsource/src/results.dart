import 'dart:convert';

import 'package:http/http.dart';
import 'package:meta/meta.dart';

import 'core.dart';
import 'models/AtomFeed.dart';

/// Result class
abstract class Result {
  Result({
    @required this.statusCode,
    @required this.reasonPhrase,
    this.eTag,
  });

  /// The status code of the response.
  final int statusCode;

  /// The reason phrase associated with the status code.
  final String reasonPhrase;

  /// ETAG in header - pass to server with If-None-Match which returns 304 not modified if resource is unchanged
  final String eTag;

  @override
  String toString() {
    return '$runtimeType{statusCode: $statusCode, reasonPhrase: $reasonPhrase, eTag: $eTag}';
  }
}

/// Stream result class
abstract class StreamResult extends Result {
  StreamResult({
    @required this.stream,
    @required int statusCode,
    @required String reasonPhrase,
    String eTag,
  }) : super(
          statusCode: statusCode,
          reasonPhrase: reasonPhrase,
          eTag: eTag,
        );

  /// Event stream
  final String stream;

  @override
  String toString() {
    return '$runtimeType{stream: $stream, statusCode: $statusCode, reasonPhrase: $reasonPhrase, eTag: $eTag}';
  }
}

/// Class with AtomFeed result for given stream
class FeedResult extends StreamResult {
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
      throw FeedFailed("Failed to get atom feed for $stream because: $statusCode $reasonPhrase");
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
class WriteResult extends StreamResult {
  WriteResult({
    @required String stream,
    @required int statusCode,
    @required String reasonPhrase,
    this.eventIds = const [],
    this.location,
    this.version,
    int number,
  })  : number = EventNumber(number),
        super(
          stream: stream,
          statusCode: statusCode,
          reasonPhrase: reasonPhrase,
        );

  factory WriteResult.from(
    String stream,
    ExpectedVersion version,
    List<String> eventIds,
    Response response,
  ) {
    switch (response.statusCode) {
      case 201:
        return WriteResult(
          stream: stream,
          statusCode: response.statusCode,
          reasonPhrase: response.reasonPhrase,
          eventIds: eventIds,
          number: _toNumber(response),
          location: response.headers['location'],
          version: ExpectedVersion(_toNumber(response)),
        );
      case 400:
        return WriteResult(
          stream: stream,
          statusCode: response.statusCode,
          reasonPhrase: response.reasonPhrase,
          version: ExpectedVersion(int.parse(response.headers['es-currentversion'])),
        );
      default:
        return WriteResult(
          stream: stream,
          statusCode: response.statusCode,
          reasonPhrase: response.reasonPhrase,
          version: version,
        );
    }
  }

  /// Ids of created events
  final List<String> eventIds;

  /// Last event number on stream
  final EventNumber number;

  /// Version of last event written to [stream]
  final ExpectedVersion version;

  /// Url to written event
  final String location;

  /// Check if 201 Created
  bool get isCreated => statusCode == 201;

  /// Check if 400 Wrong expected EventNumber
  bool get isWrongESNumber => statusCode == 400;

  static int _toNumber(Response response) => int.parse(response.headers['location'].split('/')?.last);

  @override
  String toString() {
    return '$runtimeType{stream: $stream, statusCode: $statusCode, '
        'reasonPhrase: $reasonPhrase, number: $number, location: $location}';
  }
}

/// Stream result class
class ProjectionResult extends Result {
  ProjectionResult({
    @required this.name,
    @required int statusCode,
    @required String reasonPhrase,
    this.data = const {},
  }) : super(
          statusCode: statusCode,
          reasonPhrase: reasonPhrase,
        );

  factory ProjectionResult.from({
    String name,
    Response response,
  }) {
    switch (response.statusCode) {
      case 200:
        return ProjectionResult(
          name: name,
          statusCode: response.statusCode,
          reasonPhrase: response.reasonPhrase,
          data: response.body?.isEmpty == true
              ? const <String, dynamic>{}
              : json.decode(response.body) as Map<String, dynamic>,
        );
      default:
        return ProjectionResult(
          name: name,
          statusCode: response.statusCode,
          reasonPhrase: response.reasonPhrase,
        );
    }
  }

  /// Projection name
  final String name;

  /// Projection data
  final Map<String, dynamic> data;

  /// Check if [statusCode] is 200
  bool get isOK => statusCode == 200;

  /// Check if projection is running
  bool get isRunning => (data['status'] as String)?.toLowerCase() == 'running';

  @override
  String toString() {
    return '$runtimeType{stream: $name, statusCode: $statusCode, reasonPhrase: $reasonPhrase, eTag: $eTag}';
  }
}
