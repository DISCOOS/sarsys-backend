import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import '../harness/app.dart';

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

  /// EventStore routes
  final Map<String, _Route> _router = <String, _Route>{};

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
        print('NOT FOUND: ${request.method} ${request.uri.path}');
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
  }

  EventStoreMockServer withProjection(String name) {
    _router.putIfAbsent(
      name,
      () => _Route(
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

  EventStoreMockServer withStream(String name) {
    _router.putIfAbsent(
      name,
      () => _Route(
        '/streams/$tenant:$prefix:$name',
        _Stream('$tenant:$prefix:$name'),
      ),
    );
    return this;
  }

  /// Shuts down the server listening for HTTP requests.
  Future close() {
    return _server?.close();
  }
}

class _Route {
  _Route(this.path, this.handle);
  final String path;
  final FutureOr Function(HttpRequest request) handle;

  bool isMatch(HttpRequest request) => request.uri.path.startsWith(path);
}

class _Stream {
  _Stream(this.name);
  final String name;
  final Map<String, Map<String, dynamic>> events = LinkedHashMap.of({});

  void call(HttpRequest request) async {
    try {
      switch (request.method) {
        case 'GET':
          handleGet(request);
          break;
        case 'POST':
          final content = await utf8.decoder.bind(request).join();
          final data = json.decode(content);
          final list = data is List ? List<Map<String, dynamic>>.from(data) : [data as Map<String, dynamic>];
          events.addEntries(list.map((event) => MapEntry(event['eventId'] as String, event)));
          request.response
            ..headers.add('Location', '${request.uri.path}/${events.length - 1}')
            ..statusCode = HttpStatus.created;
          break;
        default:
          request.response.statusCode = HttpStatus.forbidden;
          break;
      }
    } on Exception catch (e) {
      print(e);
    }
  }

  void handleGet(HttpRequest request) {
    final path = request.uri.path;
    if (path.startsWith('/streams/$name/head/backward/(\d+)')) {
      // Fetch events from head and backwards
      final count = toCount(path, '/streams/$name/head/backward/');
    } else if (path.startsWith('/streams/$name/(\d+)/backward/(\d+)')) {
      // Fetch events from given number and backwards
      final count = toCount(path, '/streams/$name/(\d+)/backward/');
    } else if (path.startsWith('/streams/$name/(\d+)/forward/(\d+)')) {
      // Fetch events from given number and forwards
      final count = toCount(path, '/streams/$name/(\d+)/forward/');
    } else if (path.endsWith('/streams/$name/(\s+)')) {
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
