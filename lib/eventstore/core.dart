import 'dart:async';
import 'dart:convert';
import 'package:sarsys_app_server/eventstore/events.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart';
import 'package:meta/meta.dart';

import 'package:equatable/equatable.dart';

class EsConnection {
  EsConnection({
    this.host = 'http://127.0.0.1',
    this.port = 2113,
  });

  final String host;
  final int port;
  final Client client = Client();

  Future<WriteResult> writeEvents({
    @required String stream,
    @required List<WriteEvent> events,
    UserCredentials credentials = UserCredentials.defaultCredentials,
  }) async {
    final eventIds = <String>[];
    final response = await client.post(
      "$host:$port/streams/$stream",
      headers: {
        'Authorization': credentials.header,
        'Content-type': 'application/vnd.eventstore.events+json',
      },
      body: json.encode(
        events
            .map(
              (event) => {
                'eventId': createId(eventIds),
                'eventType': event.type,
                "data": event.data,
              },
            )
            .toList(),
      ),
    );
    return WriteResult.from(stream, eventIds, response);
  }

  String createId(List<String> eventIds) {
    eventIds.add(Uuid().v4());
    return eventIds.last;
  }

  void close() {
    client.close();
  }
}

class WriteResult {
  WriteResult({
    @required this.stream,
    @required this.statusCode,
    @required this.reasonPhrase,
    this.eventIds = const [],
    this.location,
    int number,
  }) : number = EventNumber(current: number);

  /// Event stream
  final String stream;

  /// The status code of the response.
  final int statusCode;

  /// The reason phrase associated with the status code.
  final String reasonPhrase;

  /// Ids of created events
  final List<String> eventIds;

  /// Last event number on stream
  final EventNumber number;

  /// Url to written event
  final String location;

  /// Status check
  bool get isOK => statusCode == 201;

  // ignore: prefer_constructors_over_static_methods
  static WriteResult from(String stream, List<String> eventIds, Response response) {
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

  static int _toNumber(Response response) => int.parse(response.headers['location'].split('/')?.last);

  @override
  String toString() {
    return 'WriteResult{stream: $stream, statusCode: $statusCode, '
        'reasonPhrase: $reasonPhrase, number: $number, location: $location}';
  }
}

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

class EventNumber extends Equatable {
  const EventNumber({this.current, this.direction = Direction.forward});

  final int current;
  final Direction direction;

  @override
  List<Object> get props => [current, direction];

  @override
  String toString() {
    return 'EventNumber{current: $current, direction: $direction}';
  }
}

enum Direction { forward, backward }

/// When you write to a stream you often want to use Expected Version to allow for
/// optimistic concurrency with a stream. You commonly use this for a domain object projection.
class ExpectedVersion {
  const ExpectedVersion(this.number);

  /// Stream should exist but be empty when writing.
  static const int empty = 0;

  /// Stream should not exist when writing.
  static const int none = -1;

  /// Write should not conflict with anything and should always succeed.
  /// This disables the optimistic concurrency check.
  static const int any = -2;

  /// Stream should exist, but does not expect the stream to be at a specific event version number.
  static const int exists = -4;

  /// The event version number that you expect the stream to currently be at.
  final int number;
}
