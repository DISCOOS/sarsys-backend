import 'dart:convert';
import 'dart:io';

import 'package:event_source/event_source.dart';
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
    this.subscription,
    this.atomFeed,
  }) : super(
          stream: stream,
          statusCode: statusCode,
          reasonPhrase: reasonPhrase,
          eTag: eTag,
        );

  factory FeedResult.from({
    @required String stream,
    @required EventNumber number,
    @required Response response,
    String subscription,
    Direction direction = Direction.forward,
  }) {
    switch (response.statusCode) {
      case HttpStatus.ok:
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

  /// Persistent subscription group
  final String subscription;

  /// Atom feed data
  final AtomFeed atomFeed;

  /// Check if empty stream
  bool get isEmpty => atomFeed?.entries?.isEmpty == true;

  /// Check if not empty stream
  bool get isNotEmpty => atomFeed?.entries?.isNotEmpty == true;

  /// Check if head of stream
  bool get headOfStream => atomFeed?.headOfStream == true;

  /// Check if 200 OK
  bool get isOK => statusCode == HttpStatus.ok;

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
      throw FeedFailed('Failed to get atom feed for $stream because: $statusCode $reasonPhrase');
    }
    return this;
  }

  @override
  String toString() {
    return '$runtimeType{statusCode: $statusCode, reasonPhrase: $reasonPhrase, eTag: $eTag, '
        'number: $number, subscription: $subscription, atomFeed: ${atomFeed.toJson()}}';
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
      case HttpStatus.ok:
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
                      uuid: event['eventId'] as String,
                      type: event['eventType'] as String,
                      streamId: event['eventStreamId'] as String,
                      data: event['data'] as Map<String, dynamic>,
                      number: EventNumber(event['eventNumber'] as int),
                      created: DateTime.tryParse(event['updated'] as String),
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

  /// Check if empty stream
  @override
  bool get isEmpty => events?.isEmpty == true;

  /// Check if not empty stream
  @override
  bool get isNotEmpty => events?.isNotEmpty == true;

  @override
  String toString() {
    return '$runtimeType{statusCode: $statusCode, reasonPhrase: $reasonPhrase, eTag: $eTag, '
        'number: $number, subscription: $subscription, atomFeed: ${atomFeed.toJson()}, events: $events}';
  }
}

/// Command result class
class WriteResult extends StreamResult {
  WriteResult({
    @required String stream,
    @required int statusCode,
    @required String reasonPhrase,
    this.eventIds = const [],
    this.location,
    this.expected,
    this.actual,
  }) : super(
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
      case HttpStatus.created:
        return WriteResult(
          stream: stream,
          statusCode: response.statusCode,
          reasonPhrase: response.reasonPhrase,
          eventIds: eventIds,
          expected: version,
          actual: EventNumber(_toNumber(response)),
          location: response.headers['location'],
        );
      case HttpStatus.badRequest:
        return WriteResult(
          stream: stream,
          statusCode: response.statusCode,
          reasonPhrase: response.reasonPhrase,
          expected: version,
          actual: EventNumber(int.tryParse(response.headers['es-currentversion'] ?? '${EventNumber.none.value}')),
        );
      default:
        return WriteResult(
          stream: stream,
          statusCode: response.statusCode,
          reasonPhrase: response.reasonPhrase,
          expected: version,
        );
    }
  }

  /// Ids of created events
  final List<String> eventIds;

  /// Last event number in local [stream]
  final ExpectedVersion expected;

  /// Last event number in remote [stream]
  final EventNumber actual;

  /// Url to written event
  final String location;

  /// Check if 201 Created
  bool get isCreated => statusCode == HttpStatus.created;

  /// Check if 400 Bad request
  bool get isBadRequest => statusCode == HttpStatus.badRequest;

  /// Check if 400 Wrong expected EventNumber
  bool get isWrongESNumber =>
      statusCode == HttpStatus.badRequest && 'wrong expected eventnumber' == reasonPhrase.toLowerCase();

  static int _toNumber(Response response) => int.parse(response.headers['location'].split('/')?.last);

  @override
  String toString() {
    return '$runtimeType{stream: $stream, statusCode: $statusCode, '
        'reasonPhrase: $reasonPhrase, number: $actual, location: $location}';
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
      case HttpStatus.ok:
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
  bool get isOK => statusCode == HttpStatus.ok;

  /// Check if projection is running
  bool get isRunning => (data['status'] as String)?.toLowerCase() == 'running';

  @override
  String toString() {
    return '$runtimeType{stream: $name, statusCode: $statusCode, reasonPhrase: $reasonPhrase, eTag: $eTag}';
  }
}

/// Subscription result class
class SubscriptionResult extends Result {
  SubscriptionResult({
    @required this.stream,
    @required this.group,
    @required int statusCode,
    @required String reasonPhrase,
    this.number,
    this.strategy,
  }) : super(
          statusCode: statusCode,
          reasonPhrase: reasonPhrase,
        );

  factory SubscriptionResult.from({
    String stream,
    String group,
    EventNumber number,
    ConsumerStrategy strategy,
    Response response,
  }) =>
      SubscriptionResult(
        stream: stream,
        group: group,
        statusCode: response.statusCode,
        reasonPhrase: response.reasonPhrase,
      );

  /// Stream name
  final String stream;

  /// Subscription group name
  final String group;

  /// Current event number
  final EventNumber number;

  /// Consumer strategy applied to subscription
  final ConsumerStrategy strategy;

  /// Check if [statusCode] is 200
  bool get isOK => statusCode == HttpStatus.ok;

  /// Check if 201 Created
  bool get isCreated => statusCode == HttpStatus.created;

  /// Check if 202 Accepted
  bool get isAccepted => statusCode == HttpStatus.accepted;

  /// Check if 400 Bad request
  bool get isBadRequest => statusCode == HttpStatus.badRequest;

  /// Check if 409 Conflict
  bool get isConflict => statusCode == HttpStatus.conflict;

  @override
  String toString() {
    return '$runtimeType{stream: $stream, group: $group, statusCode: '
        '$statusCode, reasonPhrase: $reasonPhrase, strategy: ${enumName(strategy)}}';
  }
}
