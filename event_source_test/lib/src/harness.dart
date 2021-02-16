import 'dart:async';
import 'dart:io';

import 'package:event_source/event_source.dart';
import 'package:hive/hive.dart';
import 'package:logging/logging.dart';

import 'package:meta/meta.dart';
import 'package:test/test.dart';

import 'mock.dart';

typedef _Creator<T extends AggregateRoot> = Repository<Command, T> Function(
  RepositoryManager manager,
  EventStore store,
  int instance,
);

class EventSourceHarness {
  EventSourceHarness._();
  factory EventSourceHarness() {
    if (!exists) {
      _singleton = EventSourceHarness._();
    }
    return _singleton;
  }

  static EventSourceHarness _singleton;
  static EventSourceHarness get instance => _singleton;
  static bool get exists => _singleton != null;

  final Map<int, EventStoreMockServer> _servers = {};
  int get serverCount => _servers.length;
  List<int> get ports => _servers.keys.toList();
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

  int _master;
  int get master => _master;
  EventSourceHarness withMaster(int port) {
    assert(_servers.isEmpty, 'Master must be set before adding server');
    _master = port;
    return this;
  }

  StreamSubscription _printer;
  final Map<String, Map<String, bool>> _streams = {};
  List<String> get streams => _streams.keys.toList(growable: false);
  EventSourceHarness withStream(
    String stream, {
    bool useInstanceStreams = true,
    bool useCanonicalName = true,
  }) {
    _streams[stream] = {
      'useCanonicalName': useCanonicalName,
      'useInstanceStreams': useInstanceStreams,
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

  EventSourceHarness withRepository<T extends AggregateRoot>(
    Repository<Command, T> Function(RepositoryManager, EventStore, int) create, {
    int instances = 1,
    bool useInstanceStreams = true,
  }) {
    _builders.putIfAbsent(
      typeOf<T>(),
      () => _RepositoryBuilder<T>(
        instances,
        create,
        keep: _keep,
        threshold: _threshold,
        withSnapshots: _withSnapshots,
        useInstanceStreams: useInstanceStreams,
      ),
    );
    return this;
  }

  bool get isDebug => _debug;
  bool _debug = false;

  Logger _logger;
  EventSourceHarness withLogger({bool debug = false, Level level = Level.INFO}) {
    _logger = Logger('$runtimeType');
    if (debug) {
      _debug = debug;
      Logger.root.level = level;
    }
    return this;
  }

  int _keep;
  int _threshold;
  bool _withSnapshots = false;
  EventSourceHarness withSnapshot({int threshold = 100, int keep = 10}) {
    _keep = keep;
    _threshold = threshold;
    _withSnapshots = true;
    return this;
  }

  final Map<Type, _RepositoryBuilder> _builders = {};
  final List<StreamSubscription> _errorDetectors = [];
  Stream<LogRecord> get onRecord => _logger?.onRecord;

  T get<T extends Repository>({int port = 4000, int instance = 1}) => manager(
        port: port,
        instance: instance,
      ).get<T>();

  RepositoryManager manager({int port = 4000, int instance = 1}) => _managers[port][instance - 1];
  final Map<int, List<RepositoryManager>> _managers = {};

  EventSourceHarness addServer({
    @required int port,
  }) {
    _servers.putIfAbsent(
      port,
      () => EventStoreMockServer(
        _tenant,
        _prefix,
        port,
        master: port == _master ? null : _master,
        replicate: replicate,
        logger: _logger,
        verbose: _logger != null,
      ),
    );
    return this;
  }

  void install() {
    if (_servers.isEmpty) {
      addServer(port: 4000);
    }

    final hiveDir = Directory('test/.hive');

    setUpAll(() async {
      _initHiveDir(hiveDir);
      Hive.init(hiveDir.path);

      // Initialize
      await Storage.init();

      for (var entry in _servers.entries) {
        await _open(entry.key, entry.value);
      }
      return Future.value();
    });

    setUp(() async {
      _logger.info('---setUp---');
      _initHiveDir(hiveDir);
      _printer = onRecord.listen(
        (rec) => Context.printRecord(rec, debug: _debug),
      );
      for (var entry in _servers.entries) {
        await _build(entry.key, entry.value);
      }
      _logger.info('---setUp--->ok');
      return Future.value();
    });

    tearDown(() async {
      _logger.info('---tearDown---');
      for (var entry in _servers.entries) {
        await _clear(entry.key, entry.value);
      }
      _logger.info('---tearDown---ok');
      await Hive.deleteFromDisk();
      await hiveDir.delete(recursive: true);
      return _printer.cancel();
    });

    tearDownAll(() async {
      for (var entry in _servers.entries) {
        await _close(entry.key, entry.value);
      }
      return await Hive.deleteFromDisk();
    });
  }

  void _initHiveDir(Directory hiveDir) {
    if (hiveDir.existsSync()) {
      hiveDir.deleteSync(recursive: true);
    }
    hiveDir.createSync();
  }

  Future<void> _open(int port, EventStoreMockServer server) async {
    await server.open();
    _connections[port] = EventStoreConnection(
      host: 'localhost',
      port: port,
      requireMaster: _master != null,
    );
  }

  Future<void> _build(int port, EventStoreMockServer server) async {
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
            MessageBus(),
            _connections[port],
            prefix: EventStore.toCanonical([
              _tenant,
              _prefix,
            ]),
          ));
        }
        builder(port, list[i], i);
      }
      server.withStream(builder.stream);
    });

    for (var manager in list) {
      await manager.prepare(withProjections: _projections.toList());
      await manager.build();
      manager.repos.forEach(
        (r) => _errorDetectors.add(
          r.store.asStream().listen((_) {}, onError: onError),
        ),
      );
    }
  }

  Future<void> _clear(int port, EventStoreMockServer server) async {
    server.clear();
    if (_managers.containsKey(port)) {
      for (var manager in _managers[port]) {
        await manager.dispose();
      }
      _managers[port].clear();
    }
    _errorDetectors.forEach((s) => s.cancel());
  }

  Future<void> _close(int port, EventStoreMockServer server) async {
    if (_managers.containsKey(port)) {
      for (var manager in _managers[port]) {
        await manager.dispose();
      }
      _managers[port].clear();
    }
    _connections[port]?.close();
    await server.close();
  }

  void replicate(
    int port, {
    @required String path,
    @required String stream,
    @required List<Map<String, dynamic>> events,
    int offset,
  }) {
    _logger.fine('---replicate---');
    _logger.fine('port: $port');
    _logger.fine('path: $path');
    _logger.fine('offset: $offset');
    _logger.fine('events: $events');
    _logger.fine('stream: $stream');
    _servers.values.where((server) => server.isOpen).forEach((server) {
      if (server.port != port) {
        _logger.fine('append to $stream in server:${server.port}');
        server.getStream(stream).append(
              path,
              events,
              notify: false,
              offset: offset,
            );
      }
    });
    _logger.fine('---replicate--->ok');
  }

  void onError(Object error, StackTrace stackTrace) {
    throw error;
  }

  /// Pause all subscriptions in all managers
  Map<int, Map<Type, EventNumber>> pause() {
    final numbers = <int, Map<Type, EventNumber>>{};
    _managers.entries.fold(
      numbers,
      (numbers, entry) {
        final list = entry.value.fold<Map<Type, EventNumber>>(
          <Type, EventNumber>{},
          (list, manager) => list
            ..addAll(
              manager.pause(),
            ),
        );
        numbers[entry.key] = list;
        return numbers;
      },
    );
    return numbers;
  }

  /// Resume all subscriptions in all managers
  Map<int, Map<Type, EventNumber>> resume() {
    final numbers = <int, Map<Type, EventNumber>>{};
    _managers.entries.fold(
      numbers,
      (numbers, entry) {
        final list = entry.value.fold<Map<Type, EventNumber>>(
          <Type, EventNumber>{},
          (list, manager) => list
            ..addAll(
              manager.resume(),
            ),
        );
        numbers[entry.key] = list;
        return numbers;
      },
    );
    return numbers;
  }
}

class _RepositoryBuilder<T extends AggregateRoot> {
  _RepositoryBuilder(
    this.instances,
    _Creator<T> create, {
    @required this.useInstanceStreams,
    this.keep,
    this.threshold,
    this.withSnapshots,
  }) : _create = create;
  final int keep;
  final int threshold;
  final int instances;
  final bool withSnapshots;
  final _Creator<T> _create;
  final bool useInstanceStreams;
  String get stream => typeOf<T>().toColonCase();

  void call(int port, RepositoryManager manager, int instance) {
    final snapshots = withSnapshots
        ? Storage.fromType<T>(
            keep: keep,
            threshold: threshold,
            // Servers do no share snapshots
            prefix: '$port',
          )
        : null;
    manager.register<T>(
      (store) => _create(manager, store, instance),
      stream: stream,
      snapshots: snapshots,
      useInstanceStreams: useInstanceStreams,
    );
  }
}
