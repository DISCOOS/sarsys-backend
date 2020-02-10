import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:event_source/event_source.dart';
import 'package:json_patch/json_patch.dart';
import 'package:uuid/uuid.dart';

typedef Replicate = void Function(
  int port,
  String stream,
  String path,
  List<Map<String, dynamic>> events,
);

class EventStoreMockServer {
  EventStoreMockServer(
    this.tenant,
    this.prefix,
    this.port, {
    this.replicate,
  });

  /// Port to listen on.
  final int port;

  /// Eventstore stream tenant
  final String tenant;

  /// Eventstore stream prefix
  final String prefix;

  /// EventStore test routes
  final Map<String, TestRoute> _router = <String, TestRoute>{};

  /// EventStore test streams
  final Map<String, TestStream> _streams = <String, TestStream>{};

  final Replicate replicate;

  /// The underlying [HttpServer] listening for requests.
  HttpServer _server;

  /// Check if paused (not responding)
  bool isStreamPartitioned(String name) => _streams[name].partitioned;

  /// Begins listening for HTTP requests on [port].
  Future open() async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
    _server.listen((request) async {
      final route = _router.values.firstWhere(
        (route) => route.isMatch(request),
        orElse: () => null,
      );
      if (route == null) {
        request.response.statusCode = HttpStatus.notFound;
      } else {
        final response = route.handle(request);
        if (response is Future) {
          await response;
        }
      }
      await request.response.close();
    });
  }

  void clear() {
    _router.clear();
    _streams
      ..forEach((_, stream) => stream.dispose())
      ..clear();
  }

  EventStoreMockServer withProjection(String name) {
    _router.putIfAbsent(
      name,
      () => TestRoute(
        '/projection/\$$name',
        (request) => request.response
          ..statusCode = HttpStatus.ok
          ..write(
            json.encode(const {
              'status': 'running',
            }),
          ),
      ),
    );
    return this;
  }

  EventStoreMockServer withStream(String name, {bool useInstanceStreams = true}) {
    final stream = _addStream(name, useInstanceStreams);
    _router.putIfAbsent(
      stream.instanceStream,
      () => TestRoute(
        '/streams/${stream.instanceStream}',
        stream,
      ),
    );
    if (useInstanceStreams) {
      _router.putIfAbsent(
        stream.canonicalStream,
        () => TestRoute(
          '/streams/${stream.canonicalStream}',
          stream,
        ),
      );
    }
    return this;
  }

  TestStream _addStream(String name, bool useInstanceStreams) => _streams.putIfAbsent(
        name,
        () => TestStream(
          port,
          tenant,
          prefix,
          name,
          replicate,
          useInstanceStreams: useInstanceStreams,
        ),
      );

  TestStream getStream(String name) => _streams[name];

  /// Shuts down the server listening for HTTP requests.
  Future close() {
    clear();
    try {
      // Allow open requests to finish before closing
      return Future.delayed(
        const Duration(milliseconds: 1),
        _server?.close,
      );
    } finally {
      _server = null;
    }
  }

  bool get isOpen => _server != null;
}

class TestRoute {
  TestRoute(this.path, this.handle);
  final String path;
  final FutureOr Function(HttpRequest request) handle;

  bool isMatch(HttpRequest request) => request.uri.path.startsWith(path);
}

class TestStream {
  TestStream(
    this.port,
    this.tenant,
    this.prefix,
    this.aggregate,
    this.replicate, {
    this.useInstanceStreams = true,
  });

  final int port;
  final String tenant;
  final String prefix;
  final String aggregate;
  final Replicate replicate;
  final bool useInstanceStreams;
  final Map<String, Map<String, dynamic>> _canonical = {};
  final Map<String, List<Map<String, dynamic>>> _cached = {};
  final List<Map<String, Map<String, dynamic>>> _instances = [];

  /// Get [SourceEvent] as JSON compatible object with aggregate [uuid], type [T], [oldData], [newData] and legal [operations]
  static Map<String, dynamic> asSourceEvent<T>(
    String uuid,
    Map<String, dynamic> oldData,
    Map<String, dynamic> newData, {
    DateTime updated,
    bool deleted = false,
    List<String> operations = AggregateRoot.ops,
  }) =>
      {
        'eventId': Uuid().v4(),
        'eventType': '${typeOf<T>()}',
        'updated': (updated ?? DateTime.now()).toIso8601String(),
        'data': {
          'uuid': uuid,
          'patches': JsonPatch.diff(
            oldData,
            newData,
          )..removeWhere(
              (diff) => !operations.contains(diff['op']),
            ),
          'deleted': deleted,
        },
      };

  String get canonicalStream => useInstanceStreams ? '\$ce-$instanceStream' : instanceStream;
  String get instanceStream => EventStore.toCanonical([
        tenant,
        prefix,
        aggregate,
      ]);

  void call(HttpRequest request) async {
    switch (request.method) {
      case 'GET':
        handleGet(request);
        break;
      case 'POST':
        final path = request.uri.path;
        final content = await utf8.decoder.bind(request).join();
        final data = json.decode(content);
        final list = _toEventsWithUpdatedField(data);
        if (_checkEventNumber(request, path)) {
          final events = append(path, list);
          request.response
            ..headers.add('location', '$path/${events.length - 1}')
            ..statusCode = HttpStatus.created;
          _notify(path, list);
        }
        break;
      default:
        request.response.statusCode = HttpStatus.forbidden;
        break;
    }
  }

  bool _checkEventNumber(HttpRequest request, String path) {
    final expectedNumber = int.tryParse(request.headers.value('ES-ExpectedVersion'));
    if (expectedNumber != null && expectedNumber >= 0) {
      final number = _toEventsFromPath(path).length - 1;
      if (number != expectedNumber) {
        request.response
          ..statusCode = HttpStatus.badRequest
          ..headers.add('ES-CurrentVersion', number)
          ..reasonPhrase = 'Wrong expected eventnumber';
        return false;
      }
    }
    return true;
  }

  List<Map<String, dynamic>> _toEventsWithUpdatedField(data) =>
      (data is List ? List<Map<String, dynamic>>.from(data) : [data as Map<String, dynamic>])
          .map(_ensureUpdated)
          .toList();

  /// If true, POSTS are cached locally until [join] is invoked
  bool get partitioned => _partitioned;
  bool _partitioned = false;

  /// Cache POSTS locally until [join] is invoked
  void partition() => _partitioned = true;

  /// Replicate any POSTS cached locally to all streams
  void join() {
    if (replicate != null) {
      _cached.forEach((path, events) => replicate(port, aggregate, path, events));
    }
    _cached.clear();
    _partitioned = false;
  }

  bool _disposed = false;
  void dispose() {
    _disposed = true;
    _cached.clear();
    _canonical.clear();
    _instances.clear();
  }

  void _notify(String path, List<Map<String, dynamic>> events) {
    if (_partitioned == false) {
      Future.delayed(
        const Duration(milliseconds: 1),
        () {
          if (!(_disposed || replicate == null)) {
            replicate(port, aggregate, path, events);
          }
        },
      );
    }
  }

  /// Append [list] of data objects to [path]
  Map<String, Map<String, dynamic>> append(String path, List<Map<String, dynamic>> list) {
    final events = _toEventsFromPath(path);
    events.addEntries(list.map((event) => MapEntry(
          event['eventId'] as String,
          event,
        )));
    if (_partitioned) {
      _cached.update(path, (events) => events..addAll(list), ifAbsent: () => list);
    }
    _canonical.addAll(events);
    return events;
  }

  Map<String, dynamic> _ensureUpdated(Map<String, dynamic> event) {
    if (event.containsKey('updated')) {
      return event;
    }
    return Map.from(event)..addAll({'updated': DateTime.now().toIso8601String()});
  }

  Map<String, Map<String, dynamic>> _toEventsFromPath(String path) {
    if (_instances.isEmpty) {
      _instances.add(LinkedHashMap.from({}));
    }
    if (useInstanceStreams) {
      final id = int.tryParse(path.split('-').last);
      if (id >= _instances.length) {
        _instances.insert(id, LinkedHashMap.from({}));
      }
      return _instances.elementAt(id);
    }
    return _instances.first;
  }

  Map<String, Map<String, dynamic>> toEvents({int id}) =>
      _instances.isEmpty ? {} : (useInstanceStreams ? _instances.elementAt(id ?? 0) : _instances.first);

  void handleGet(HttpRequest request) {
    final path = request.uri.path;
    final stream = RegExp.escape(canonicalStream);
    if (RegExp(asHead(stream)).hasMatch(path)) {
      // Fetch events from head and backwards
      _toAtomFeedResponse(request, asHead(stream), path);
    } else if (RegExp(asBackward(stream)).hasMatch(path)) {
      // Fetch events from given number and backwards
      _toAtomFeedResponse(request, asBackward(stream), path);
    } else if (RegExp(asForward(stream)).hasMatch(path)) {
      // Fetch events from given number and forwards
      _toAtomFeedResponse(request, asForward(stream), path);
    } else if (RegExp(asUuid(stream)).hasMatch(path)) {
      // Fetch events with given uuid
      // final data = _canonical[toUuid(stream, path)];
    } else if (RegExp(asNumber(stream)).hasMatch(path)) {
      // Fetch events with given canonical event number
      final number = toNumber(stream, path);
      final data = _canonical[_canonical.keys.elementAt(number)];
      _toAtomItemContentResponse(request, number, data);
    } else {
      request.response.statusCode = HttpStatus.notFound;
    }
  }

  String _toSelfUrl(String stream) {
    return 'http://localhost:$port/streams/$stream';
  }

  String asHead(String stream) => '/streams/$stream/head/backward/(\\d+)';
  String asForward(String stream) => '/streams/$stream/(\\d+)/forward/(\\d+)';
  String asBackward(String stream) => '/streams/$stream/(\\d+)/backward/(\\d+)';

  String asUuid(String stream) => '/streams/$stream/(\\s+)';
  String toUuid(String stream, String path) => RegExp('/streams/$stream/(\\s+)').firstMatch(path)?.group(1);

  String asNumber(String stream) => '/streams/$stream/(\\d+)';
  int toNumber(String stream, String path) => int.parse(RegExp('/streams/$stream/(\\d+)').firstMatch(path)?.group(1));

  Map<String, String> _toAtomAuthor() => {
        'name': '${typeOf<EventStoreMockServer>()}',
      };

  void _toAtomItemContentResponse(HttpRequest request, int number, Map<String, dynamic> data) {
    if (request.headers.value('accept')?.contains('application/vnd.eventstore.atom+json') != true) {
      request.response
        ..statusCode = HttpStatus.badRequest
        ..write(
          'TestStream only supports Accept:application/vnd.eventstore.atom+json',
        );
    } else {
      final selfUrl = _toSelfUrl(canonicalStream);
      request.response
        ..statusCode = HttpStatus.ok
        ..write(json.encode(_toAtomItem(
          number,
          selfUrl,
          data,
          withContent: true,
        )));
    }
  }

  void _toAtomFeedResponse(HttpRequest request, String pattern, String path) {
    final match = RegExp(pattern).firstMatch(path);
    final offset = int.parse(match.group(1));
    final count = int.parse(match.group(2));
    if (request.headers.value('accept')?.contains('application/vnd.eventstore.atom+json') != true) {
      request.response
        ..statusCode = HttpStatus.badRequest
        ..write(
          'TestStream only supports Accept:application/vnd.eventstore.atom+json',
        );
    } else if (offset < 0 || count < 0 || offset > _canonical.length) {
      request.response.statusCode = HttpStatus.notFound;
    } else if (offset == 0 && count == 0) {
      request.response.statusCode = HttpStatus.ok;
    } else {
      final selfUrl = _toSelfUrl(canonicalStream);
      final events = _canonical.values.skip(offset).take(count).toList();
      request.response
        ..statusCode = HttpStatus.ok
        ..write(json.encode(_toAtomFeed(selfUrl, offset, events)));
    }
  }

  AtomFeed _toAtomFeed(String selfUrl, int offset, List<Map<String, dynamic>> events) => AtomFeed(
        id: selfUrl, // Dummy
        title: 'Event stream $canonicalStream',
        author: AtomAuthor(name: '${typeOf<EventStoreMockServer>()}'),
        updated: _lastUpdated(events),
        eTag: '26;-2060438500', // Dummy
        // streamId: canonicalStream,
        headOfStream: true,
        selfUrl: selfUrl,
        links: [
          AtomLink(uri: selfUrl, relation: 'self'),
          AtomLink(uri: '$selfUrl/head/backward/20', relation: 'first'),
          AtomLink(uri: '$selfUrl/1/forward/20', relation: 'previous'),
          AtomLink(uri: '$selfUrl/metadata', relation: 'meta'),
        ],
        entries: _toAtomItems(events, offset, selfUrl),
      );

  String _lastUpdated(List<Map<String, dynamic>> events) {
    return events.isEmpty
        ? null
        : events.fold<DateTime>(DateTime.parse(events.first['updated'] as String), (updated, event) {
            var next = DateTime.parse(event['updated'] as String);
            if (next.difference(updated).inMilliseconds > 0) {
              next = updated;
            }
            return next;
          })?.toIso8601String();
  }

  List<AtomItem> _toAtomItems(
    List<Map<String, dynamic>> events,
    int offset,
    String selfUrl, {
    bool withContent = false,
  }) {
    final entries = <AtomItem>[];
    var i = 0;
    events.forEach((event) {
      final number = offset + (i++);
      entries.add(
        AtomItem.fromJson(Map.from(event)
          ..addAll(_toAtomItem(
            number,
            selfUrl,
            event,
            withContent: withContent,
          ))),
      );
    });
    return entries;
  }

  Map<String, dynamic> _toAtomItem(
    int number,
    String selfUrl,
    Map<String, dynamic> data, {
    bool withContent = false,
  }) =>
      {
        'id': '$selfUrl/$number',
        'title': '$number@$canonicalStream',
        'author': _toAtomAuthor(),
        'updated': data['updated'],
        'summary': data['eventType'],
        if (!withContent) 'eventNumber': number,
        if (!withContent) 'streamId': canonicalStream,
        if (!withContent) 'isJSON': true,
        if (!withContent) 'isMetaData': false,
        if (!withContent) 'isLinkMetaData': false,
        if (withContent)
          'content': {
            'eventStreamId': canonicalStream,
            'eventNumber': number,
            'eventId': data['eventId'],
            'eventType': data['eventType'],
            'data': data['data'],
            'metadata': '',
          },
        'links': [
          {
            'uri': '$selfUrl/$number',
            'relation': 'edit',
          },
          {
            'uri': '$selfUrl/$number',
            'relation': 'alternate',
          }
        ]
      };
}
