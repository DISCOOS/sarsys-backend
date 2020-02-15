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

  String _projection;
  String get projection => _projection;
  EventSourceHarness withProjection() {
    _projection = 'by_category';
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
        '${rec.time}: ${rec.level.name}: '
        '${rec.message} ${rec.error ?? ''} ${rec.stackTrace ?? ''}',
      );
    });
    return this;
  }

  final Map<Type, _RepositoryBuilder> _builders = {};
  Repository get<T extends Repository>({int port = 4000, int instance = 0}) => _managers[port][instance].get<T>();

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
    if (_projection?.isNotEmpty == true) {
      server.withProjection('by_category');
    }
    final list = _managers.putIfAbsent(port, () => []);
    _builders.values.forEach((builder) {
      for (var i = 0; i < builder.instances; i++) {
        final manager = RepositoryManager(
          _bus,
          _connections[port],
          prefix: EventStore.toCanonical([
            _tenant,
            _prefix,
          ]),
        );
        builder(manager);
        list.add(manager);
      }
      server.withStream(builder.stream);
    });
    await Future.wait(list.map((manager) => manager.build()));
  }

  void _clear(int port, EventStoreMockServer server) {
    server.clear();
    _managers[port]
      ..forEach((manager) => manager.dispose())
      ..clear();
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
