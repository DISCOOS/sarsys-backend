import 'package:aqueduct_test/aqueduct_test.dart';
import 'package:event_source_test/event_source_test.dart';
import 'package:grpc/grpc.dart';
import 'package:hive/hive.dart';
import 'package:sarsys_domain/sarsys_domain.dart';
import 'package:sarsys_http_core/sarsys_http_core.dart';

import 'package:sarsys_ops_server/sarsys_ops_channel.dart';
import 'package:sarsys_ops_server/src/config.dart';
import 'package:sarsys_tracking_server/sarsys_tracking_server.dart';
import 'package:test/test.dart';

class SarSysOpsHarness extends TestHarness<SarSysOpsServerChannel> {
  static const testDataPath = 'test/.hive';
  static const sub = _SarSysTrackingHarness.sub;
  static const group = _SarSysTrackingHarness.group;

  SarSysTrackingServer get trackingServer => _trackingHarness?.server;
  EventStoreMockServer get esServer => _trackingHarness?.eventStoreMockServer;
  SarSysTrackingServiceClient get trackingClient => _trackingHarness?.grpcClient;
  _SarSysTrackingHarness _trackingHarness;

  SarSysOpsHarness withTrackingServer({
    bool debug = false,
    int grpcPort = 8083,
    int healthPort = 8084,
  }) {
    _trackingHarness = _SarSysTrackingHarness()
      ..withTenant()
      ..withPrefix()
      ..withServerPorts(
        grpcPort: grpcPort,
        healthPort: healthPort,
      )
      ..withEventStoreMock()
      ..withLogger(debug: debug)
      ..withGrpcClient(port: grpcPort);
    _context.addAll({
      'TRACKING_SERVER_GRPC_PORT': _trackingHarness.grpcPort,
      'TRACKING_SERVER_HEALTH_PORT': _trackingHarness.healthPort,
    });
    return this;
  }

  SarSysOpsHarness withLogger({bool debug = false}) {
    if (debug) {
      Logger.root.level = Level.FINE;
    }
    return this;
  }

  final Map<String, dynamic> _context = {};
  SarSysOpsHarness withContext({
    String podName = 'bar',
    String dataPath,
    String apiSpecPath,
  }) {
    _context.addAll({
      if (podName != null) 'POD_NAME': podName,
      if (dataPath != null) 'DATA_PATH': dataPath,
      if (apiSpecPath != null) 'API_SPEC_PATH': apiSpecPath,
    });
    return this;
  }

  @override
  void install({
    String file = 'config.src.yaml',
    bool restartForEachTest = false,
  }) {
    options.configurationFilePath = file;
    _trackingHarness?.install(
      SarSysOpsConfig(file).tracking,
    );
    super.install(
      restartForEachTest: restartForEachTest,
    );
  }

  @override
  Future beforeStart() async {
    await _deleteTestData();
    _configureContext(application);
  }

  Future _deleteTestData() async {
    await Hive.deleteFromDisk();
    final dataPath = Directory((_context['DATA_PATH'] ?? testDataPath) as String);
    if (dataPath.existsSync()) {
      dataPath.deleteSync(recursive: true);
    }
  }

  void _configureContext(Application application) {
    application.options.context.addAll(_context);
  }

  @override
  Future stop() async {
    await _deleteTestData();
    assert(channel.router.getContexts().isEmpty, 'Contexts should be empty');
    return super.stop();
  }
}

class _SarSysTrackingHarness {
  static const sub = '\$et-TrackingCreated';
  static const group = 'TrackingService';

  SarSysTrackingServer server;
  HttpClient httpClient = HttpClient();
  EventStoreMockServer eventStoreMockServer;

  String _tenant;
  String get tenant => _tenant;
  _SarSysTrackingHarness withTenant({String tenant = 'discoos'}) {
    _tenant = tenant;
    return this;
  }

  String _prefix;
  String get prefix => _prefix;
  _SarSysTrackingHarness withPrefix({String prefix = 'test'}) {
    _prefix = prefix;
    return this;
  }

  int get healthPort => _healthPort;
  int _healthPort = 8082;

  int get grpcPort => _grpcPort;
  int _grpcPort = 8083;

  _SarSysTrackingHarness withServerPorts({
    int healthPort = 8082,
    int grpcPort = 8083,
  }) {
    assert(_grpcChannel == null, 'withGrpc is already configured');
    _grpcPort = grpcPort;
    _healthPort = healthPort;
    return this;
  }

  bool _startup = false;
  _SarSysTrackingHarness withStartupOnBuild() {
    _startup = true;
    return this;
  }

  ClientChannel get grpcChannel => _grpcChannel;
  ClientChannel _grpcChannel;
  SarSysTrackingServiceClient get grpcClient => _grpcClient;
  SarSysTrackingServiceClient _grpcClient;
  _SarSysTrackingHarness withGrpcClient({int port = 8083}) {
    _grpcChannel = ClientChannel(
      '127.0.0.1',
      port: _grpcPort = port,
      options: const ChannelOptions(
        credentials: ChannelCredentials.insecure(),
      ),
    );
    _grpcClient = SarSysTrackingServiceClient(
      grpcChannel,
      options: CallOptions(
        timeout: const Duration(
          seconds: 30,
        ),
      ),
    );
    return this;
  }

  _SarSysTrackingHarness withLogger({bool debug = false}) {
    if (debug) {
      Logger.root.level = Level.FINE;
    }
    return this;
  }

  EventStoreMockServer withEventStoreMock() => eventStoreMockServer = EventStoreMockServer(
        _tenant,
        _prefix,
        4000,
      );

  void install(SarSysTrackingConfig config) {
    config.grpcPort = _grpcPort;
    config.healthPort = _healthPort;
    config.prefix = _prefix;
    config.tenant = _tenant;
    config.startup = _startup;
    config.logging.stdout = false;

    setUpAll(
      () async => await eventStoreMockServer.open(),
    );

    setUp(() async {
      assert(server == null);
      assert(eventStoreMockServer != null, 'Forgot to call withEventStoreMock()?');

      // Define required projections, streams and subscriptions
      eventStoreMockServer
        ..withProjection('\$by_category')
        ..withProjection('\$by_event_type')
        ..withStream(typeOf<Device>().toColonCase())
        ..withStream(typeOf<Tracking>().toColonCase())
        ..withStream(sub, useInstanceStreams: false, useCanonicalName: false)
        ..withSubscription(sub, group: group);

      server = SarSysTrackingServer();
      await server.start(
        config,
      );
      // Assert that all repos have a stream
      final missing = <String>[];
      for (var repo in server.manager.repos) {
        if (!eventStoreMockServer.hasStream(repo.aggregateType.toColonCase())) {
          missing.add(repo.aggregateType.toString());
        }
      }
      if (missing.isNotEmpty) {
        throw 'Following streams are not defined: \n\n'
            '   $missing\n\n'
            '>> Add missing stream(s) to SarSysHarness.onSetUp()';
      }
      return server.manager.readyAsync();
    });

    tearDown(() async {
      await server?.stop();
      server = null;
      eventStoreMockServer?.clear();
      return await Hive.deleteFromDisk();
    });

    tearDownAll(
      () => eventStoreMockServer.close(),
    );
  }
}

FutureOr<String> createTracking(TrackingRepository repo, TestStream stream, String subscription) async {
  final uuid = Uuid().v4();
  final events = await repo.execute(CreateTracking({
    'uuid': '$uuid',
  }));
  stream.append(subscription, [
    TestStream.fromDomainEvent(events.first),
  ]);
  return uuid;
}
