import 'package:event_source/event_source.dart';
import 'package:logging/logging.dart';

import 'package:meta/meta.dart';
import 'package:test/test.dart';

typedef _Creator<T extends AggregateRoot> = Repository<Command, T> Function(EventStore store);

class EventSourceHarness {
  final Map<int, EventStoreMockServer> _servers = {};
  EventStoreMockServer server({int port = 4000}) => _servers[port];

  final Map<int, EventStoreConnection> _connections = {};
  EventStoreConnection connection({int port = 4000}) => _connections[port];

  String _tenant;
  String get tenant => _tenant;
  EventSourceHarness withTenant({String tenant = 'discoos'}) {
    _tenant = tenant;
    return this;
  }

  String _prefix;
  String get prefix => _prefix;
  EventSourceHarness withPrefix({String prefix = 'test'}) {
    _prefix = prefix;
    return this;
  }

  final Map<String, Map<String, bool>> _streams = {};
  List<String> get streams => _streams.keys.toList(growable: false);
  EventSourceHarness withStream(
    String stream, {
    bool useInstanceStreams = true,
    bool useCanonicalName = true,
  }) {
    _streams[stream] = {
      'useInstanceStreams': useInstanceStreams,
      'useCanonicalName': useCanonicalName,
    };
    return this;
  }

  final Set<String> _projections = {};
  List<String> get projections => _projections.toList(growable: false);
  EventSourceHarness withProjections({List<String> projections = const ['\$by_category']}) {
    _projections.addAll(projections);
    return this;
  }

  final Map<String, Set<String>> _subscriptions = {};
  Map<String, String> get subscriptions => Map.unmodifiable(_subscriptions);
  EventSourceHarness withSubscription(String stream, {String group}) {
    _subscriptions.update(stream, (groups) => groups..add(group), ifAbsent: () => {group});
    return this;
  }

  final _bus = MessageBus();
  MessageBus get bus => _bus;

  EventSourceHarness withRepository<T extends AggregateRoot>(
    Repository<Command, T> Function(EventStore) create, {
    int instances = 1,
    bool useInstanceStreams = true,
  }) {
    _builders.putIfAbsent(
      typeOf<T>(),
      () => _RepositoryBuilder<T>(
        instances,
        create,
        useInstanceStreams: useInstanceStreams,
      ),
    );
    return this;
  }

  Logger _logger;
  EventSourceHarness withLogger() {
    _logger = Logger('$runtimeType');
    _logger.onRecord.listen((rec) {
      print(
        '${rec.time}: ${rec.level.name}: ${rec.loggerName}: '
        '${rec.message} ${rec.error ?? ''} ${rec.stackTrace ?? ''}',
      );
    });
    return this;
  }

  final Map<Type, _RepositoryBuilder> _builders = {};
  T get<T extends Repository>({int port = 4000, int instance = 1}) => _managers[port][instance - 1].get<T>();

  final Map<int, List<RepositoryManager>> _managers = {};

  void add({
    @required int port,
  }) {
    _servers.putIfAbsent(
      port,
      () => EventStoreMockServer(
        _tenant,
        _prefix,
        port,
        replicate: replicate,
        logger: _logger,
        verbose: _logger != null,
      ),
    );
  }

  void install() {
    if (_servers.isEmpty) {
      add(port: 4000);
    }

    setUpAll(() async {
      return await Future.forEach<MapEntry<int, EventStoreMockServer>>(
        _servers.entries,
        (entry) => _open(entry.key, entry.value),
      );
    });

    setUp(() async {
      return await Future.forEach<MapEntry<int, EventStoreMockServer>>(
        _servers.entries,
        (entry) => _build(entry.key, entry.value),
      );
    });

    tearDown(() {
      _servers.forEach(_clear);
    });

    tearDownAll(() async {
      return await Future.forEach<MapEntry<int, EventStoreMockServer>>(
        _servers.entries,
        (entry) => _close(entry.key, entry.value),
      );
    });
  }

  void _open(int port, EventStoreMockServer server) async {
    await server.open();
    _connections[port] = EventStoreConnection(
      host: 'http://localhost',
      port: port,
    );
  }

  void _build(int port, EventStoreMockServer server) async {
    _streams.forEach(
      (stream, flags) => server.withStream(
        stream,
        useCanonicalName: flags['useCanonicalName'],
        useInstanceStreams: flags['useInstanceStreams'],
      ),
    );
    _projections.forEach(
      (projection) => server.withProjection(projection),
    );
    _subscriptions.forEach(
      (stream, groups) => groups.forEach((group) => server.withSubscription(stream, group: group)),
    );
    final list = _managers.putIfAbsent(port, () => []);
    _builders.values.forEach((builder) {
      for (var i = 0; i < builder.instances; i++) {
        if (list.length == i) {
          list.add(RepositoryManager(
            _bus,
            _connections[port],
            prefix: EventStore.toCanonical([
              _tenant,
              _prefix,
            ]),
          ));
        }
        builder(list[i]);
      }
      server.withStream(builder.stream);
    });
    await Future.wait(
      list.map(
        (manager) => manager.build(withProjections: _projections.toList()),
      ),
    );
  }

  void _clear(int port, EventStoreMockServer server) {
    server.clear();
    if (_managers.containsKey(port)) {
      _managers[port]
        ..forEach((manager) => manager.dispose())
        ..clear();
    }
  }

  void _close(int port, EventStoreMockServer server) async {
    await server.close();
    _managers[port]
      ..forEach((manager) => manager.dispose())
      ..clear();
    _connections[port]?.close();
  }

  void replicate(int port, String stream, String path, List<Map<String, dynamic>> data) {
    _servers.values
        .where(
          (server) => server.isOpen,
        )
        .where(
          (server) => server.port != port,
        )
        .forEach((server) {
      server.getStream(stream).append(path, data);
    });
  }
}

class _RepositoryBuilder<T extends AggregateRoot> {
  _RepositoryBuilder(
    this.instances,
    _Creator<T> create, {
    @required this.useInstanceStreams,
  }) : _create = create;
  final int instances;
  final _Creator<T> _create;
  final bool useInstanceStreams;
  String get stream => typeOf<T>().toColonCase();

  void call(RepositoryManager manager) {
    manager.register<T>(
      _create,
      stream: stream,
      useInstanceStreams: useInstanceStreams,
    );
  }
}

Map<String, dynamic> createTracking(String uuid) => {
      'uuid': '$uuid',
    };

Map<String, dynamic> createSource({String id, String uuid = 'string', String type = 'device'}) => {
      if (id != null) 'id': '$id',
      'uuid': '$uuid',
      'type': '$type',
    };

Map<String, dynamic> createTrack({String id, String uuid = 'string', String type = 'device'}) => {
      if (id != null) 'id': '$id',
      'source': createSource(
        uuid: uuid,
        type: type,
      ),
    };

Map<String, Object> createPosition() => {
      'type': 'Feature',
      'geometry': {
        'type': 'Point',
        'coordinates': [0.0, 0.0]
      },
      'properties': {
        'name': 'string',
        'description': 'string',
        'accuracy': 0,
        'timestamp': DateTime.now().toIso8601String(),
        'type': 'manual'
      }
    };

Map<String, dynamic> createDevice(String uuid) => {
      'uuid': '$uuid',
      'name': 'string',
      'alias': 'string',
      'network': 'string',
      'networkId': 'string',
    };
