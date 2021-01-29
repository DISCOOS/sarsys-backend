import 'package:aqueduct_test/aqueduct_test.dart';
import 'package:hive/hive.dart';
import 'package:sarsys_http_core/sarsys_http_core.dart';

import 'package:sarsys_ops_server/sarsys_ops_channel.dart';

class SarSysOpsHarness extends TestHarness<SarSysOpsServerChannel> {
  static const testDataPath = 'test/.hive';
  Application<SarSysOpsServerChannel> server;

  Logger _logger;
  SarSysOpsHarness withLogger({bool debug = false}) {
    _logger = Logger('$runtimeType');
    if (debug) {
      Logger.root.level = Level.FINE;
    }
    return this;
  }

  final Map<String, dynamic> _context = {};
  SarSysOpsHarness withContext({
    String podName = 'bar',
    String dataPath,
  }) {
    _context.clear();
    _context.addAll({
      if (podName != null) 'POD_NAME': podName,
      if (dataPath != null) 'data_path': testDataPath,
    });
    return this;
  }

  Stream<LogRecord> get onRecord => _logger?.onRecord;

  @override
  Future beforeStart() async {
    await _deleteTestData();
    _configureContext(application);
  }

  Future _deleteTestData() async {
    await Hive.deleteFromDisk();
    final dataPath = Directory((_context['data_path'] ?? testDataPath) as String);
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

//////////////////////////////////
// Common domain objects
//////////////////////////////////

Map<String, dynamic> createPoint() => {
      "type": "Point",
      "coordinates": [0.0, 0.0]
    };

Map<String, dynamic> createAddress() => {
      "lines": ["string"],
      "city": "string",
      "postalCode": "string",
      "countryCode": "string",
    };

Map<String, dynamic> createLocation() => {
      "point": createPoint(),
      "address": createAddress(),
      "description": "string",
    };

Map<String, dynamic> createops(String uuid, {String status, List<Map<String, dynamic>> sources}) => {
      "uuid": uuid,
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
      "type": "Feature",
      "geometry": {
        "type": "Point",
        "coordinates": [lat, lon, if (alt != null) alt]
      },
      "properties": {
        "name": "string",
        "description": "string",
        "source": "$type",
        if (acc != null) "accuracy": acc,
        if (speed != null) "speed": speed,
        if (bearing != null) "bearing": bearing,
        "timestamp": (timestamp ?? DateTime.now()).toIso8601String(),
        if (activity != null)
          'activity': {
            'type': '$activity',
            if (confidence != null) 'confidence': confidence,
          }
      }
    };

Map<String, dynamic> createDevice(String uuid) => {
      "uuid": uuid,
      "alias": "string",
      "trackable": true,
      "number": "string",
      "network": "string",
      "networkId": "string",
    };
