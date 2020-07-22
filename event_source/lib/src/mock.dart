import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:event_source/event_source.dart';
import 'package:json_patch/json_patch.dart';
import 'package:logging/logging.dart';
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
    this.logger,
    this.replicate,
    this.verbose = true,
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

  /// Verbose logging flag
  final bool verbose;

  /// Logger instance
  final Logger logger;

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
//        if (request.method == 'POST') {
//          print(request.uri.path);
//        }
        _notFound(request);
      } else {
//        if (request.method == 'POST') {
//          print(request.uri.path);
//        }
        await route.handle(request);
      }
      _log(
        'Ports ${request.connectionInfo.remotePort} > ${request.connectionInfo.localPort}: '
        '${request.method} ${request.uri.path}'
        '${request.uri.queryParameters.isNotEmpty ? '?${request.uri.query}' : ''} '
        '> ${request.response.statusCode} ${request.response.reasonPhrase}',
      );
      await request.response.close();
    });
    _log(
      '$runtimeType[$port]: Listening for requests',
    );
  }

  HttpResponse _notFound(HttpRequest request) {
    return request.response
      ..statusCode = HttpStatus.notFound
      ..reasonPhrase = 'Not found';
  }

  void _log(String message) {
    if (verbose && logger != null) {
      logger.info(
        message,
      );
    }
  }

  EventStoreMockServer withProjection(String name) {
    _router.putIfAbsent(
      name,
      () => TestRoute(
        '/projection/$name',
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

  EventStoreMockServer withStream(
    String name, {
    bool useInstanceStreams = true,
    bool useCanonicalName = true,
  }) {
    final stream = _addStream(
      name,
      useInstanceStreams,
      useCanonicalName ? tenant : null,
      useCanonicalName ? prefix : null,
    );
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

  TestStream getStream(String name) => _streams[name];

  TestStream _addStream(String name, bool useInstanceStreams, String tenant, String prefix) => _streams.putIfAbsent(
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

  EventStoreMockServer withSubscription(String stream, {String group}) {
    final _stream = _streams[stream];
    if (_stream == null) {
      throw ArgumentError('Stream $stream not found');
    }
    if (group != null) {
      _stream._createGroup(group);
    }
    final path = '/subscriptions/${_stream.canonicalStream}';
    _router.putIfAbsent(
      path,
      () => TestRoute(
        path,
        _stream,
      ),
    );
    return this;
  }

  void clear() {
    _clear();
    _log(
      '$runtimeType[$port]: Cleared router and streams',
    );
  }

  void _clear() {
    _router.clear();
    _streams
      ..forEach((_, stream) => stream.dispose())
      ..clear();
  }

  /// Shuts down the server listening for HTTP requests.
  Future close() async {
    _clear();
    try {
      // Allow open requests to finish before closing
      return Future.delayed(
        const Duration(milliseconds: 1),
        await _server?.close,
      );
    } finally {
      _server = null;
      _log(
        '$runtimeType[$port]: Closed server',
      );
    }
  }

  bool get isOpen => _server != null;
}

class TestRoute {
  TestRoute(this.path, this.handle);
  final String path;
  final FutureOr Function(HttpRequest request) handle;

  bool isMatch(HttpRequest request) {
    final test = request.uri.path;
    final matches = test.startsWith(path);
    // Hack - workaround for unable
    // to make regexp work directly
    if (matches && _isPathPrefix(test)) {
//      print('HttpRequest.path=$test');
//      print('TestRoute.path=$path');
      return true;
    }
    return false;
  }

  bool _isPathPrefix(String test) => (test.length == path.length ||
      test.length > path.length &&
          (test.substring(path.length, path.length + 1).startsWith('\/') ||
              test.substring(path.length).startsWith(RegExp(r'-\d*$'))));
}

class TestStream {
  TestStream(
    this.port,
    this.tenant,
    this.prefix,
    this.aggregate,
    this.replicate, {
    this.useInstanceStreams = true,
    this.strategy = ConsumerStrategy.RoundRobin,
  });

  final int port;
  final String tenant;
  final String prefix;
  final String aggregate;
  final Replicate replicate;
  final bool useInstanceStreams;
  final ConsumerStrategy strategy;
  final Map<String, TestSubscription> _groups = {};
  final Map<String, Map<String, dynamic>> _canonical = {};
  final Map<String, List<Map<String, dynamic>>> _cached = {};
  final List<Map<String, Map<String, dynamic>>> _instances = [];

  List<Map<String, Map<String, dynamic>>> get instances => List.unmodifiable(_instances);

  /// Get [SourceEvent] from [DomainEvent]
  static Map<String, dynamic> fromDomainEvent(
    DomainEvent event, {
    DateTime updated,
  }) =>
      {
        'eventId': event.uuid,
        'eventType': event.type,
        'updated': event.created.toIso8601String(),
        'data': event.data,
      };

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

  String get canonicalStream => useInstanceStreams ? categoryStream : instanceStream;
  String get categoryStream => '\$ce-$instanceStream';
  String get instanceStream => EventStore.toCanonical([
        tenant,
        prefix,
        aggregate,
      ]);

  void call(HttpRequest request) async {
    switch (request.method) {
      case 'GET':
        handleGET(request);
        break;
      case 'PUT':
        await handlePUT(request);
        break;
      case 'POST':
        await handlePOST(request);
        break;
      default:
        _unsupported(request);
        break;
    }
  }

  Future handlePUT(HttpRequest request) async {
    RegExp pattern;
    final path = request.uri.path;
    if ((pattern = RegExp(TestSubscription.asSubscription(RegExp.escape(canonicalStream)))).hasMatch(path)) {
      await _createSubscription(request, pattern, path);
    } else {
      _unsupported(request);
    }
  }

  Future _createSubscription(HttpRequest request, RegExp pattern, String path) async {
    final content = await utf8.decoder.bind(request).join();
    final data = json.decode(content);
    final offset = data['startFrom'] ?? 0;
    final strategy = data['namedConsumerStrategy'] as String ?? enumName(ConsumerStrategy.RoundRobin);
    final type = ConsumerStrategy.values.firstWhere(
      (value) => enumName(value).toLowerCase() == strategy.toLowerCase(),
      orElse: () => null,
    );
    if (type == null) {
      _unsupported(
        request,
        message: 'Consumer strategy $strategy not suppored',
      );
    } else {
      final group = pattern.firstMatch(path).group(1);
      if (_groups.containsKey(group)) {
        request.response
          ..statusCode = HttpStatus.conflict
          ..reasonPhrase = 'Already exists';
      } else {
        _createGroup(
          group,
          type: type,
          offset: offset,
          data: data,
        );
        request.response..statusCode = HttpStatus.created;
      }
    }
  }

  TestSubscription _createGroup(
    String group, {
    ConsumerStrategy type = ConsumerStrategy.RoundRobin,
    offset = 0,
    Map data,
  }) =>
      _groups[group] = TestSubscription(
        canonicalStream,
        group,
        type,
        offset,
        timeout: (data ?? {})['messageTimeoutMilliseconds'] as int,
      );

  Future _ackEvents(HttpRequest request, RegExp pattern, String path) async {
    final group = pattern.firstMatch(path).group(1);
    if (_groups.containsKey(group)) {
      final ids = request.uri.queryParameters['ids']?.split(',') ?? [];
      _groups[group].ack(this, request, ids);
    } else {
      _notFound(request);
    }
  }

  Future _nackEvents(HttpRequest request, RegExp pattern, String path) async {
    final group = pattern.firstMatch(path).group(1);
    if (_groups.containsKey(group)) {
      final ids = request.uri.queryParameters['ids']?.split(',') ?? [];
      _groups[group].nack(this, request, ids);
    } else {
      _notFound(request);
    }
  }

  String asStream(String stream) => '/streams/$stream';

  Future handlePOST(HttpRequest request) async {
    RegExp pattern;
    final path = request.uri.path;
    if (RegExp(asStream(RegExp.escape(instanceStream))).hasMatch(path)) {
      await _createStream(request, path);
    } else if ((pattern = RegExp(TestSubscription.asAck(RegExp.escape(canonicalStream)))).hasMatch(path)) {
      await _ackEvents(request, pattern, path);
    } else if ((pattern = RegExp(TestSubscription.asNack(RegExp.escape(canonicalStream)))).hasMatch(path)) {
      await _nackEvents(request, pattern, path);
    } else {
      _unsupported(request);
    }
  }

  Future _createStream(HttpRequest request, String path) async {
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
  }

  bool _checkEventNumber(HttpRequest request, String path) {
    final expectedNumber = int.tryParse(request.headers.value('ES-ExpectedVersion'));
    if (expectedNumber != null) {
      final exists = _streamExists(path);
      final number = _toEventsFromPath(path).length - 1;
      final isAny = ExpectedVersion.any.value == expectedNumber;
      final isNone = ExpectedVersion.none.value == expectedNumber;
      final isEmpty = ExpectedVersion.empty.value == expectedNumber;
      final isNotEmpty = expectedNumber > 0;

      if (!isAny && /* If ExpectedVersion.any is given, write should never conflict and should always succeed */
          (isNotEmpty && number != expectedNumber || /* Should match exact event number given */
              isNone && exists && number >= 0 || /* Should not exist at the time of the writing */
              isEmpty && (!exists || number > 0)) /* Should exist and be empty */) {
        request.response
          ..statusCode = HttpStatus.badRequest
          ..headers.add('ES-CurrentVersion', number)
          ..reasonPhrase = 'Wrong expected EventNumber';
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

  HttpResponse _unsupported(HttpRequest request, {String message}) => request.response
    ..statusCode = HttpStatus.badRequest
    ..reasonPhrase = message ?? 'Request ${request.method} ${request.uri.path} not supported';

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

  bool _streamExists(String path) {
    if (useInstanceStreams) {
      final id = int.tryParse(path.split('-').last);
      return id < _instances.length;
    }
    return _instances.isNotEmpty;
  }

  Map<String, Map<String, dynamic>> _toEventsFromPath(String path) {
    if (_instances.isEmpty) {
      _instances.add(LinkedHashMap.from({}));
    }
    if (useInstanceStreams) {
      final id = int.tryParse(path.split('-').last);
      if (id >= _instances.length) {
        for (var i = _instances.length; i <= id; i++) {
          _instances.add(LinkedHashMap.from({}));
        }
      }
      return _instances.elementAt(id);
    }
    return _instances.first;
  }

  Map<String, Map<String, dynamic>> toEvents({int id}) =>
      _instances.isEmpty ? {} : (useInstanceStreams ? _instances.elementAt(id ?? 0) : _instances.first);

  void handleGET(HttpRequest request) {
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
    } else if (RegExp(asNumber(stream)).hasMatch(path)) {
      // Fetch events with given canonical event number
      final number = toNumber(stream, path);
      if (number >= 0 && number < _canonical.keys.length) {
        final data = _canonical[_canonical.keys.elementAt(number)];
        _toAtomItemContentResponse(request, number, data);
      } else {
        _notFound(request);
      }
    } else if (RegExp(TestSubscription.asSubscription(stream)).hasMatch(path)) {
      // Fetch next events from subscription group for given consumer
      _toCompetingAtomFeedResponse(request, TestSubscription.asSubscription(stream), path);
//    } else if (RegExp(asUuid(stream)).hasMatch(path)) {
//      // Fetch events with given uuid
//      final data = _canonical[toUuid(stream, path)];
    } else {
      _unsupported(request);
    }
  }

  String toHost() => 'http://localhost:$port';
  String toSelfURL(String stream) => '${toHost()}/streams/$stream';

  String asHead(String stream) => '/streams/$stream/head/backward/(\\d+)';
  String asForward(String stream) => '/streams/$stream/(\\d+)/forward/(\\d+)';
  String asBackward(String stream) => '/streams/$stream/(\\d+)/backward/(\\d+)';

  String asUuid(String stream) => '/streams/$stream/([\\w:-]+)';
  String toUuid(String stream, String path) => RegExp('/streams/$stream/([\\w:-]+)').firstMatch(path)?.group(1);

  String asNumber(String stream) => '/streams/$stream/(\\d+)';
  int toNumber(String stream, String path) => int.parse(RegExp('/streams/$stream/(\\d+)').firstMatch(path)?.group(1));

  void _toAtomItemContentResponse(HttpRequest request, int number, Map<String, dynamic> data) {
    if (request.headers.value('accept')?.contains('application/vnd.eventstore.atom+json') != true) {
      _unsupported(
        request,
        message: "TestStream only supports 'Accept:application/vnd.eventstore.atom+json'",
      );
    } else {
      final selfUrl = toSelfURL(canonicalStream);
      request.response
        ..statusCode = HttpStatus.ok
        ..write(json.encode(_toAtomItem(
          toHost(),
          canonicalStream,
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
      _unsupported(
        request,
        message: "TestStream only supports 'Accept:application/vnd.eventstore.atom+json'",
      );
    } else if (offset < 0 || count < 0 || offset > _canonical.length) {
      _notFound(request);
    } else if (offset == 0 && count == 0) {
      request.response.statusCode = HttpStatus.ok;
    } else {
      final selfUrl = toSelfURL(canonicalStream);
      final events = _canonical.values.skip(offset).take(count).toList();
      final data = _toAtomFeed(
        toHost(),
        selfUrl,
        canonicalStream,
        offset,
        events,
      );
      request.response
        ..statusCode = HttpStatus.ok
        ..write(json.encode(data));
    }
  }

  void _notFound(HttpRequest request) => request.response
    ..statusCode = HttpStatus.notFound
    ..reasonPhrase = 'Not found';

  void _toCompetingAtomFeedResponse(HttpRequest request, String pattern, String path) {
    if (request.headers.value('accept')?.contains('application/vnd.eventstore.competingatom+json') != true) {
      _unsupported(
        request,
        message: "TestSubscription only supports 'Accept:application/vnd.eventstore.competingatom+json'",
      );
    } else {
      final match = RegExp(pattern).firstMatch(path);
      final group = match.group(1);
      if (!_groups.containsKey(group)) {
        _notFound(request);
      } else {
        _groups[group].consume(this, request);
      }
    }
  }
}

class TestSubscription {
  TestSubscription(
    this.stream,
    this.group,
    this.strategy,
    int offset, {
    int timeout = 10000,
  })  : _offset = offset,
        pattern = RegExp(
          asGroup(
            RegExp.escape(stream),
            RegExp.escape(group),
          ),
        ),
        timeout = timeout ?? 10000;

  final int timeout;
  final String stream;
  final String group;
  final RegExp pattern;
  final ConsumerStrategy strategy;

  int _offset = 0;
  int get offset => _offset;
  Map<String, _Consumed> consumed = {};
  Set<String> acknowledged = LinkedHashSet.of({});

  void consume(TestStream stream, HttpRequest request) {
    final path = request.uri.path;
    final match = RegExp(asCount(RegExp.escape(this.stream), RegExp.escape(group))).firstMatch(path);
    final count = int.parse(match.group(1) ?? '1');
    final selfUrl = '${stream.toHost()}/${asGroup(this.stream, group)}';
    final consumed = _evict(stream);
    final events = stream._canonical.values
        .skip(_offset)
        .where((event) => !consumed.containsKey(event['eventId']))
        .take(count)
        .toList();
    final data = _toAtomFeed(
      stream.toHost(),
      selfUrl,
      this.stream,
      offset,
      events,
      group: group,
      consume: count,
      isSubscription: true,
    );
    consumed.addEntries(
      events.map(
        (event) => MapEntry(event['eventId'], _Consumed.from(event)),
      ),
    );
    _offset += events.length;
    request.response
      ..statusCode = HttpStatus.ok
      ..write(json.encode(data));
  }

  Map<String, _Consumed> _evict(TestStream stream) {
    final now = DateTime.now();
    final evicted = consumed.keys.where(
      (uuid) => !consumed[uuid].acknowledged && now.difference(consumed[uuid].timestamp).inMilliseconds > timeout,
    );
    if (evicted.isNotEmpty) {
      _offset = evicted.fold(
        _offset,
        (offset, next) => min(offset, stream._canonical.keys.toList().indexOf(consumed[next].uuid)),
      );
      consumed.removeWhere((uuid, _) => evicted.contains(uuid));
    }
    return consumed;
  }

  static String asSubscription(String stream) => 'subscriptions/$stream/([\\w:-]+)';
  static String asGroup(String stream, String group) => 'subscriptions/$stream/$group';
  static String asCount(String stream, String group) => 'subscriptions/$stream/$group/(\\d+)';
  static String asAck(String stream) => 'subscriptions/$stream/([\\w:-]+)/ack';
  static String asNack(String stream) => 'subscriptions/$stream/([\\w:-]+)/nack';

  void ack(TestStream stream, HttpRequest request, List<String> ids) {
    // only acknowledge known ids
    final known = ids.toList()..removeWhere((id) => !stream._canonical.containsKey(id));
    if (known.isNotEmpty) {
      known.forEach((uuid) => consumed[uuid].acknowledged = true);
    }
    request.response..statusCode = HttpStatus.accepted;
  }

  void nack(TestStream stream, HttpRequest request, List<String> ids) {
    // only acknowledge known ids
    final known = ids.toList()..removeWhere((id) => !stream._canonical.containsKey(id));
    if (known.isNotEmpty) {
      consumed.removeWhere((id, _) => known.contains(id));
    }
    request.response..statusCode = HttpStatus.accepted;
  }
}

class _Consumed {
  _Consumed(this.uuid, this.timestamp);

  factory _Consumed.from(Map<String, dynamic> event) => _Consumed(
        event['eventId'] as String,
        DateTime.now(),
      );

  final String uuid;
  final DateTime timestamp;
  bool acknowledged = false;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is _Consumed && runtimeType == other.runtimeType && uuid == other.uuid;

  @override
  int get hashCode => uuid.hashCode;
}

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

AtomFeed _toAtomFeed(
  String host,
  String selfUrl,
  String stream,
  int offset,
  List<Map<String, dynamic>> events, {
  int consume,
  String group,
  bool isSubscription = false,
}) {
  final ids = events.map((event) => event['eventId'] as String).join(',');

  return AtomFeed(
    id: selfUrl, // Dummy
    title: "Event stream '$stream'",
    author: AtomAuthor(name: '${typeOf<EventStoreMockServer>()}'),
    updated: _lastUpdated(events),
    eTag: '26;-2060438500', // Dummy
    streamId: stream,
    headOfStream: true,
    selfUrl: selfUrl,
    links: [
      AtomLink(uri: selfUrl, relation: 'self'),
      if (!isSubscription) AtomLink(uri: '$selfUrl/head/backward/20', relation: 'first'),
      if (!isSubscription) AtomLink(uri: '$selfUrl/1/forward/20', relation: 'previous'),
      if (!isSubscription) AtomLink(uri: '$selfUrl/metadata', relation: 'meta'),
      if (isSubscription) AtomLink(uri: '$selfUrl/ack?ids=$ids', relation: 'ackAll'),
      if (isSubscription) AtomLink(uri: '$selfUrl/nack?ids=$ids', relation: 'nackAll'),
      if (isSubscription) AtomLink(uri: '$selfUrl/$consume', relation: 'previous'),
    ],
    entries: _toAtomItems(
      host,
      stream,
      events,
      offset,
      selfUrl,
      group: group,
      isSubscription: isSubscription,
    ),
  );
}

List<AtomItem> _toAtomItems(
  String host,
  String stream,
  List<Map<String, dynamic>> events,
  int offset,
  String selfUrl, {
  String group,
  bool withContent = false,
  bool isSubscription = false,
}) {
  final entries = <AtomItem>[];
  var i = 0;
  events.forEach((event) {
    final number = offset + (i++);
    entries.add(
      AtomItem.fromJson(Map.from(event)
        ..addAll(_toAtomItem(
          host,
          stream,
          number,
          selfUrl,
          event,
          group: group,
          withContent: withContent,
          isSubscription: isSubscription,
        ))),
    );
  });
  return entries;
}

Map<String, dynamic> _toAtomItem(
  String host,
  String stream,
  int number,
  String selfUrl,
  Map<String, dynamic> data, {
  String group,
  bool withContent = false,
  bool isSubscription = false,
}) =>
    {
      'id': '${isSubscription ? "$host/streams/$stream" : selfUrl}/$number',
      'title': '$number@$stream',
      'author': _toAtomAuthor(),
      'updated': data['updated'],
      'summary': data['eventType'],
      if (!withContent) 'eventNumber': number,
      if (!withContent) 'streamId': stream,
      if (!withContent) 'isJSON': true,
      if (!withContent) 'isMetaData': false,
      if (!withContent) 'isLinkMetaData': false,
      if (withContent)
        'content': {
          'eventStreamId': stream,
          'eventNumber': number,
          'eventId': data['eventId'],
          'eventType': data['eventType'],
          'data': data['data'],
          'metadata': '',
        },
      'links': [
        {
          'uri': '${isSubscription ? "$host/streams/$stream" : selfUrl}/$number',
          'relation': 'edit',
        },
        {
          'uri': '${isSubscription ? "$host/streams/$stream" : selfUrl}/$number',
          'relation': 'alternate',
        },
        if (isSubscription) {'uri': '$selfUrl/ack/${data['eventId']}', 'relation': 'ack'},
        if (isSubscription) {'uri': '$selfUrl/nack/${data['eventId']}', 'relation': 'nack'},
      ]
    };

Map<String, String> _toAtomAuthor() => {
      'name': '${typeOf<EventStoreMockServer>()}',
    };
