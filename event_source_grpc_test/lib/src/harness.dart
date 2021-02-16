import 'dart:async';

import 'package:event_source/event_source.dart';
import 'package:event_source_grpc/event_source_grpc.dart';
import 'package:event_source_test/event_source_test.dart';
import 'package:grpc/grpc.dart';
import 'package:logging/logging.dart';

import 'package:meta/meta.dart';
import 'package:test/test.dart';

class EventSourceGrpcHarness {
  EventSourceGrpcHarness._() : _harness = EventSourceHarness();
  factory EventSourceGrpcHarness() {
    if (!exists) {
      _singleton = EventSourceGrpcHarness._();
    }
    return _singleton;
  }

  static EventSourceGrpcHarness _singleton;
  static EventSourceGrpcHarness get instance => _singleton;
  static bool get exists => _singleton != null;

  final EventSourceHarness _harness;
  EventStoreMockServer server({int port = 4000}) => _harness.server(port: port);

  EventStoreConnection connection({int port = 4000}) => _harness.connection(port: port);

  String get tenant => _harness.tenant;
  EventSourceGrpcHarness withTenant({String tenant = 'discoos'}) {
    _harness.withTenant(tenant: tenant);
    return this;
  }

  String get prefix => _harness.prefix;
  EventSourceGrpcHarness withPrefix({String prefix = 'test'}) {
    _harness.withPrefix(prefix: tenant);
    return this;
  }

  int get master => _harness.master;
  EventSourceGrpcHarness withMaster(int port) {
    _harness.withMaster(port);
    return this;
  }

  List<String> get streams => _harness.streams;
  EventSourceGrpcHarness withStream(
    String stream, {
    bool useInstanceStreams = true,
    bool useCanonicalName = true,
  }) {
    _harness.withStream(
      stream,
      useCanonicalName: useCanonicalName,
      useInstanceStreams: useInstanceStreams,
    );
    return this;
  }

  List<String> get projections => _harness.projections.toList(growable: false);
  EventSourceGrpcHarness withProjections({List<String> projections = const ['\$by_category']}) {
    _harness.withProjections(projections: projections);
    return this;
  }

  Map<String, String> get subscriptions => _harness.subscriptions;
  EventSourceGrpcHarness withSubscription(String stream, {String group}) {
    _harness.withSubscription(stream, group: group);
    return this;
  }

  EventSourceGrpcHarness withRepository<T extends AggregateRoot>(
    Repository Function(RepositoryManager, EventStore, int) create, {
    int instances = 1,
    bool useInstanceStreams = true,
  }) {
    _harness.withRepository<T>(
      create,
      instances: instances,
      useInstanceStreams: useInstanceStreams,
    );
    return this;
  }

  bool get isDebug => _harness.isDebug;

  Logger _logger;
  EventSourceGrpcHarness withLogger({bool debug = false, Level level = Level.INFO}) {
    _harness.withLogger(
      debug: debug,
      level: level,
    );
    _logger = Logger('$runtimeType');
    return this;
  }

  bool _withAggregateService = false;
  EventSourceGrpcHarness withAggregateService() {
    _withAggregateService = true;
    return this;
  }

  bool _withRepositoryService = false;
  EventSourceGrpcHarness withRepositoryService() {
    _withRepositoryService = true;
    return this;
  }

  bool _withSnapshotService = false;
  EventSourceGrpcHarness withSnapshotService({
    int keep = 10,
    int threshold = 100,
  }) {
    _harness.withSnapshot(
      threshold: threshold,
      keep: keep,
    );
    _withSnapshotService = true;
    return this;
  }

  Stream<LogRecord> get onRecord => _logger?.onRecord;

  RepositoryManager manager({int port = 4000, int instance = 1}) => _harness.manager(
        port: port,
        instance: instance,
      );

  T get<T extends Repository>({int port = 4000, int instance = 1}) => _harness.get<T>(
        port: port,
        instance: instance,
      );

  EventSourceGrpcHarness addServer({
    @required int port,
  }) {
    _harness.addServer(port: port);
    return this;
  }

  final Set<Server> _servers = {};
  final Map<int, Set<Client>> _clients = {};
  final Map<int, ClientChannel> _channels = {};

  T client<T extends Client>({port = 8081}) => _clients[8081].whereType<T>().firstOrNull;

  void install() {
    _harness.install();
    setUp(() async {
      assert(_clients.isEmpty);
      assert(_servers.isEmpty);
      assert(_channels.isEmpty);
      for (var i = 0; i < _harness.serverCount; i++) {
        await _start(i);
      }
    });

    tearDown(() async {
      try {
        return Future.wait(
          [
            ..._servers.map((e) => e.shutdown()),
            ..._channels.values.map((e) => e.shutdown()),
          ],
        );
      } finally {
        _clients.clear();
        _servers.clear();
        _channels.clear();
      }
    });
  }

  Future _start(int i) async {
    final services = <Service>[];
    final port = 8081 + i;
    final manager = _harness.manager(
      port: _harness.ports.elementAt(i),
    );
    if (_withAggregateService) {
      _open(
        port,
        (channel) => AggregateServiceClient(
          channel,
          options: CallOptions(
            timeout: const Duration(
              seconds: 30,
            ),
          ),
        ),
      );
      services.add(
        AggregateGrpcService(manager),
      );
    }
    if (_withRepositoryService) {
      _open(
        port,
        (channel) => RepositoryServiceClient(
          channel,
          options: CallOptions(
            timeout: const Duration(
              seconds: 30,
            ),
          ),
        ),
      );
      services.add(
        RepositoryGrpcService(manager),
      );
    }
    if (_withSnapshotService) {
      _open(
        port,
        (channel) => SnapshotServiceClient(
          channel,
          options: CallOptions(
            timeout: const Duration(
              seconds: 30,
            ),
          ),
        ),
      );
    }
    assert(
      services.isNotEmpty,
      'no services, did you forget to enable a grpc service?',
    );

    // Start grpc services
    final server = Server(
      services,
    );
    _servers.add(server);
    return server.serve(
      port: port,
    );
  }

  T _open<T extends Client>(int port, T Function(ClientChannel) create) {
    var channel;
    _channels.putIfAbsent(
      port,
      () => channel = ClientChannel(
        '127.0.0.1',
        port: port,
        options: const ChannelOptions(
          credentials: ChannelCredentials.insecure(),
        ),
      ),
    );
    var client = create(channel);
    _clients.update(
      port,
      (clients) => clients..add(client),
      ifAbsent: () => {client},
    );
    return client;
  }

  void replicate(
    int port, {
    @required String path,
    @required String stream,
    @required List<Map<String, dynamic>> events,
    int offset,
  }) {
    _harness.replicate(
      port,
      path: path,
      stream: stream,
      events: events,
    );
  }

  void onError(Object error, StackTrace stackTrace) {
    throw error;
  }

  /// Pause all subscriptions in all managers
  Map<int, Map<Type, EventNumber>> pause() {
    return _harness.pause();
  }

  /// Resume all subscriptions in all managers
  Map<int, Map<Type, EventNumber>> resume() {
    return _harness.resume();
  }
}
