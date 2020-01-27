import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

class EventStoreMockServer {
  EventStoreMockServer(
    this.tenant,
    this.prefix,
    this.port,
  );

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

  /// The underlying [HttpServer] listening for requests.
  HttpServer _server;

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
    _streams.clear();
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
    _router.putIfAbsent(
      name,
      () => TestRoute(
        '/streams/$tenant:$prefix:$name',
        _addStream(name, useInstanceStreams),
      ),
    );
    return this;
  }

  TestStream _addStream(String name, bool useInstanceStreams) => _streams.putIfAbsent(
        name,
        () => TestStream(
          '$tenant:$prefix:$name',
          useInstanceStreams: useInstanceStreams,
        ),
      );

  TestRoute getRoute(String name) => _router[name];
  TestStream getStream(String name) => _streams[name];

  /// Shuts down the server listening for HTTP requests.
  Future close() {
    return _server?.close();
  }
}

class TestRoute {
  TestRoute(this.path, this.handle);
  final String path;
  final FutureOr Function(HttpRequest request) handle;

  bool isMatch(HttpRequest request) => request.uri.path.startsWith(path);
}

class TestStream {
  TestStream(this.name, {this.useInstanceStreams = true});
  final String name;
  final bool useInstanceStreams;
  final List<Map<String, Map<String, dynamic>>> _instances = [];

  void call(HttpRequest request) async {
    switch (request.method) {
      case 'GET':
        handleGet(request);
        break;
      case 'POST':
        final path = request.uri.path;
        final content = await utf8.decoder.bind(request).join();
        final data = json.decode(content);
        final list = data is List ? List<Map<String, dynamic>>.from(data) : [data as Map<String, dynamic>];
        final events = _toEventsFromPath(path);
        events.addEntries(list.map((event) => MapEntry(event['eventId'] as String, event)));
        request.response
          ..headers.add('location', '$path/${events.length - 1}')
          ..statusCode = HttpStatus.created;
        break;
      default:
        request.response.statusCode = HttpStatus.forbidden;
        break;
    }
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
    final stream = useInstanceStreams ? '\$ce-$name' : name;
    if (path.startsWith('/streams/$stream/head/backward/(\d+)')) {
      // Fetch events from head and backwards
      final count = toCount(path, '/streams/$stream/head/backward/');
    } else if (path.startsWith('/streams/$stream/(\d+)/backward/(\d+)')) {
      // Fetch events from given number and backwards
      final count = toCount(path, '/streams/$stream/(\d+)/backward/');
    } else if (path.startsWith('/streams/$stream/(\d+)/forward/(\d+)')) {
      // Fetch events from given number and forwards
      final count = toCount(path, '/streams/$stream/(\d+)/forward/');
    } else if (path.endsWith('/streams/$stream/(\s+)')) {
      // Fetch events with given uuid
      final uuid = toUuid(path);
    } else {
      request.response.statusCode = HttpStatus.notFound;
    }
  }

  int toCount(String path, String page) => int.tryParse(path.substring(path.indexOf(page)));

  String toUuid(String path) => RegExp('/streams/$name/(\s+)').firstMatch(path)?.group(0);
}

class _Feed {
  _Feed(this.name);
  final String name;
  final Map<String, Map<String, dynamic>> events = LinkedHashMap.of({});

  void call(HttpRequest request) async {
    switch (request.method) {
      case 'GET':
        break;
    }
  }
}
