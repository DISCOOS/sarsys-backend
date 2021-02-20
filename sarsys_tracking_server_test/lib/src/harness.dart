import 'package:event_source_test/event_source_test.dart';
import 'package:grpc/grpc.dart';
import 'package:hive/hive.dart';
import 'package:sarsys_core/sarsys_core.dart';
import 'package:sarsys_tracking_server/sarsys_tracking_server.dart';
import 'package:test/test.dart';

import 'package:event_source/event_source.dart';
import 'package:sarsys_domain/sarsys_domain.dart';
import 'package:sarsys_tracking_server/src/server.dart';

class SarSysTrackingHarness {
  static const group = 'TrackingService';
  static const sub = '\$et-TrackingCreated';
  static const testDataPath = 'test/.hive';

  SarSysTrackingServer server;
  HttpClient httpClient = HttpClient();
  EventStoreMockServer eventStoreMockServer;

  String _tenant;
  String get tenant => _tenant;
  SarSysTrackingHarness withTenant({String tenant = 'discoos'}) {
    _tenant = tenant;
    return this;
  }

  String _prefix;
  String get prefix => _prefix;
  SarSysTrackingHarness withPrefix({String prefix = 'test'}) {
    _prefix = prefix;
    return this;
  }

  int get healthPort => _healthPort;
  int _healthPort = 8082;

  int get grpcPort => _grpcPort;
  int _grpcPort = 8083;

  SarSysTrackingHarness withServerPorts({
    int healthPort = 8082,
    int grpcPort = 8083,
  }) {
    assert(_grpcChannel == null, 'withGrpc is already configured');
    _grpcPort = grpcPort;
    _healthPort = healthPort;
    return this;
  }

  int _keep;
  int _threshold;
  bool _automatic;
  bool _withSnapshots = false;
  SarSysTrackingHarness withSnapshots({
    int threshold = 100,
    int keep = 10,
    bool automatic = true,
  }) {
    _keep = keep;
    _automatic = automatic;
    _threshold = threshold;
    _withSnapshots = true;
    return this;
  }

  bool _startup = false;
  SarSysTrackingHarness withStartupOnBuild() {
    _startup = true;
    return this;
  }

  ClientChannel get grpcChannel => _grpcChannel;
  ClientChannel _grpcChannel;
  SarSysTrackingServiceClient get grpcClient => _grpcClient;
  SarSysTrackingServiceClient _grpcClient;
  SarSysTrackingHarness withGrpcClient({int port = 8083}) {
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

  SarSysTrackingHarness withLogger({bool debug = false}) {
    if (debug) {
      Logger.root.level = Level.FINE;
    }
    return this;
  }

  EventStoreMockServer withEventStoreMock([EventStoreMockServer server]) => eventStoreMockServer ??= server ??
      EventStoreMockServer(
        _tenant,
        _prefix,
        4000,
      );

  void install({
    SarSysTrackingConfig config,
    String file = 'config.src.yaml',
  }) {
    config ??= SarSysTrackingConfig.fromFile(file);
    config.grpcPort = _grpcPort;
    config.healthPort = _healthPort;
    config.prefix = _prefix;
    config.tenant = _tenant;
    config.startup = _startup;
    config.logging.stdout = false;
    if (_withSnapshots) {
      config.data.path = testDataPath;
      config.data.enabled = true;
      config.data.snapshots.keep = _keep;
      config.data.snapshots.enabled = true;
      config.data.snapshots.threshold = _threshold;
      config.data.snapshots.automatic = _automatic;
    }

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

    tearDownAll(() async {
      await _grpcChannel.terminate();
      return eventStoreMockServer.close();
    });
  }
}

//////////////////////////////////
// Common domain objects
//////////////////////////////////

Map<String, dynamic> createPoint() => {
      'type': 'Point',
      'coordinates': [0.0, 0.0]
    };

Map<String, dynamic> createAddress() => {
      'lines': ['string'],
      'city': 'string',
      'postalCode': 'string',
      'countryCode': 'string',
    };

Map<String, dynamic> createLocation() => {
      'point': createPoint(),
      'address': createAddress(),
      'description': 'string',
    };

Map<String, dynamic> createTracking(String uuid, {String status, List<Map<String, dynamic>> sources}) => {
      'uuid': uuid,
      if (status != null) 'status': status,
      if (sources != null) 'sources': sources,
    };

Map<String, dynamic> createSource({String uuid = 'string', String type = 'device'}) => {
      'uuid': uuid,
      'type': '$type',
    };

Map<String, dynamic> createTrack({
  String id,
  String uuid = 'string',
  String type = 'device',
  Iterable<Map<String, dynamic>> positions,
}) =>
    {
      if (id != null) 'id': '$id',
      'source': createSource(
        uuid: uuid,
        type: type,
      ),
      if (positions != null) 'positions': positions,
    };

Map<String, Object> createPosition({
  String type = 'manual',
  double lat = 0.0,
  double lon = 0.0,
  double alt,
  double acc,
  double speed,
  double bearing,
  String activity,
  int confidence,
  DateTime timestamp,
}) =>
    {
      'type': 'Feature',
      'geometry': {
        'type': 'Point',
        'coordinates': [lat, lon, if (alt != null) alt]
      },
      'properties': {
        'name': 'string',
        'description': 'string',
        'source': '$type',
        if (acc != null) 'accuracy': acc,
        if (speed != null) 'speed': speed,
        if (bearing != null) 'bearing': bearing,
        'timestamp': (timestamp ?? DateTime.now()).toIso8601String(),
        if (activity != null)
          'activity': {
            'type': '$activity',
            if (confidence != null) 'confidence': confidence,
          }
      }
    };

Map<String, dynamic> createDevice(String uuid) => {
      'uuid': uuid,
      'alias': 'string',
      'trackable': true,
      'number': 'string',
      'network': 'string',
      'networkId': 'string',
    };
