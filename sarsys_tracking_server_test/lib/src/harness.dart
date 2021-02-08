import 'package:event_source_test/event_source_test.dart';
import 'package:grpc/grpc.dart';
import 'package:hive/hive.dart';
import 'package:sarsys_http_core/sarsys_http_core.dart';
import 'package:sarsys_tracking_server/sarsys_tracking_server.dart';
import 'package:test/test.dart';

import 'package:event_source/event_source.dart';
import 'package:sarsys_domain/sarsys_domain.dart';
import 'package:sarsys_tracking_server/src/server.dart';

class SarSysTrackingHarness {
  SarSysTrackingServer server;
  HttpClient httpClient = HttpClient();
  EventStoreMockServer eventStoreMockServer;

  int get grpcPort => _grpcPort;
  int _grpcPort = 8083;

  int get healthPort => _healthPort;
  int _healthPort = 8082;

  SarSysTrackingHarness withServerPorts({
    int grpcPort = 8083,
    int healthPort = 8082,
  }) {
    _grpcPort = grpcPort;
    _healthPort = healthPort;
    return this;
  }

  ClientChannel get grpcChannel => _grpcChannel;
  ClientChannel _grpcChannel;
  SarSysTrackingServiceClient get grpcClient => _grpcClient;
  SarSysTrackingServiceClient _grpcClient;
  SarSysTrackingHarness withGrpc({int port = 8083}) {
    _grpcChannel = ClientChannel(
      '127.0.0.1',
      port: port,
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

  Logger _logger;
  SarSysTrackingHarness withLogger({bool debug = false}) {
    _logger = Logger('$runtimeType');
    if (debug) {
      Logger.root.level = Level.FINE;
    }
    return this;
  }

  EventStoreMockServer withEventStoreMock() => eventStoreMockServer = EventStoreMockServer(
        'discoos',
        'test',
        4000,
        logger: _logger,
      );

  void install() {
    setUpAll(() async {
      assert(eventStoreMockServer != null, 'Forgot to call withEventStoreMock()?');
      // Define required projections
      eventStoreMockServer.withProjection('\$by_category');
      eventStoreMockServer.withProjection('\$by_event_type');

      // Define required streams
      eventStoreMockServer.withStream(typeOf<Device>().toColonCase());
      eventStoreMockServer.withStream(typeOf<Tracking>().toColonCase());
      await eventStoreMockServer.open();
    });

    setUp(() async {
      assert(server == null);
      server = SarSysTrackingServer();
      final config = SarSysTrackingConfig.fromFile('config.src.yaml');
      config.grpcPort = _grpcPort;
      config.healthPort = _healthPort;
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
      await server.stop();
      server = null;
      return await Hive.deleteFromDisk();
    });

    tearDownAll(() async {});
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
