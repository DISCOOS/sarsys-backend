import 'package:aqueduct_test/aqueduct_test.dart';
import 'package:event_source/event_source.dart';
import 'package:event_source_test/event_source_test.dart';
import 'package:jaguar_jwt/jaguar_jwt.dart';
import 'package:sarsys_app_server/controllers/tenant/app_config.dart';
import 'package:sarsys_app_server/sarsys_app_server.dart';
import 'package:sarsys_domain/sarsys_domain.dart' hide Operation;
import 'package:sarsys_domain/sarsys_domain.dart' as sar show Operation;
import 'package:test/test.dart';
import 'package:meta/meta.dart';
import 'package:hive/hive.dart';

import 'package:collection_x/collection_x.dart';
export 'package:event_source/event_source.dart';
export 'package:aqueduct_test/aqueduct_test.dart';
export 'package:test/test.dart';
export 'package:aqueduct/aqueduct.dart';

/// A testing harness for sarsys_app_server.
///
/// A harness for testing an aqueduct application. Example test file:
///
///         void main() {
///           Harness harness = Harness()..install();
///
///           test('GET /path returns 200', () async {
///             final response = await harness.agent.get('/path');
///             expectResponse(response, 200);
///           });
///         }
///
class SarSysAppHarness extends TestHarness<SarSysAppServerChannel> {
  EventStoreMockServer eventStoreMockServer;

  static const testDataPath = 'test/.hive';

  final Set<int> _ports = {};
  final Map<int, Agent> _agents = {};
  final List<Application<SarSysAppServerChannel>> _instances = [];

  Map<int, Agent> get agents => _agents;

  EventStoreMockServer withEventStoreMock() => eventStoreMockServer = EventStoreMockServer(
        'discoos',
        'test',
        4000,
      );

  int _keep;
  int _threshold;
  bool _automatic;
  bool _withSnapshots = false;
  SarSysAppHarness withSnapshot({
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

  int _grpcPort = 8080;
  bool _withGrpcServer = false;
  SarSysAppHarness withGrpcServer({int port = 8080}) {
    _grpcPort = port;
    _withGrpcServer = true;
    return this;
  }

  final Map<String, dynamic> _context = {};
  SarSysAppHarness withContext({
    String podName = 'bar',
    bool debug,
    String dataPath,
    String logLevel,
    bool printStdOut,
    String apiSpecPath,
  }) {
    _context.clear();
    _context.addAll({
      if (debug != null) 'DEBUG': debug,
      if (podName != null) 'POD_NAME': podName,
      if (dataPath != null) 'DATA_PATH': dataPath,
      if (logLevel != null) 'LOG_LEVEL': logLevel,
      if (printStdOut != null) 'LOG_STDOUT': printStdOut,
      if (apiSpecPath != null) 'API_SPEC_PATH': apiSpecPath,
    });
    return this;
  }

  SarSysAppHarness withInstance(int port) {
    assert(port != 80, 'Instance with port 80 exists');
    assert(!_ports.contains(port), 'Instance with port $port exists');
    _ports.add(port);
    return this;
  }

  @override
  Future beforeStart() async {
    await _deleteTestData();

    if (eventStoreMockServer != null) {
      // Define required projections
      eventStoreMockServer.withProjection('\$by_category');
      eventStoreMockServer.withProjection('\$by_event_type');

      // Define required streams
      eventStoreMockServer.withStream(typeOf<AppConfig>().toColonCase());
      eventStoreMockServer.withStream(typeOf<Incident>().toColonCase());
      eventStoreMockServer.withStream(typeOf<sar.Operation>().toColonCase());
      eventStoreMockServer.withStream(typeOf<Subject>().toColonCase());
      eventStoreMockServer.withStream(typeOf<Affiliation>().toColonCase());
      eventStoreMockServer.withStream(typeOf<Device>().toColonCase());
      eventStoreMockServer.withStream(typeOf<Department>().toColonCase());
      eventStoreMockServer.withStream(typeOf<Division>().toColonCase());
      eventStoreMockServer.withStream(typeOf<Organisation>().toColonCase());
      eventStoreMockServer.withStream(typeOf<Unit>().toColonCase());
      eventStoreMockServer.withStream(typeOf<Personnel>().toColonCase());
      eventStoreMockServer.withStream(typeOf<Tracking>().toColonCase());
      eventStoreMockServer.withStream(typeOf<Mission>().toColonCase());
      eventStoreMockServer.withStream(typeOf<Person>().toColonCase());
      await eventStoreMockServer.open();
    }
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
    _context['LOG_STDOUT'] ??= false;
    _context['LOG_LEVEL'] ??= 'SEVERE';
    application.options.context.addAll(_context);
    if (_withSnapshots) {
      application.options.context['DATA_ENABLED'] = true;
      application.options.context['DATA_PATH'] = testDataPath;
      application.options.context['DATA_SNAPSHOTS_KEEP'] = _keep;
      application.options.context['DATA_SNAPSHOTS_ENABLED'] = true;
      application.options.context['DATA_SNAPSHOTS_THRESHOLD'] = _threshold;
      application.options.context['DATA_SNAPSHOTS_AUTOMATIC'] = _automatic;
    } else {
      application.options.context['DATA_ENABLED'] = false;
      application.options.context['DATA_SNAPSHOTS_ENABLED'] = false;
    }
    if (_withGrpcServer) {
      application.options.context['GRPC_PORT'] = _grpcPort;
    }
    application.options.context['GRPC_ENABLED'] = _withGrpcServer;
  }

  @override
  Future afterStart() async {
    // Assert that all repos have a stream
    final missing = <String>[];
    for (var repo in channel.manager.repos) {
      if (!eventStoreMockServer.hasStream(repo.aggregateType.toColonCase())) {
        missing.add(repo.aggregateType.toString());
      }
    }
    if (missing.isNotEmpty) {
      throw 'Following streams are not defined: \n\n'
          '   $missing\n\n'
          '>> Add missing stream(s) to SarSysHarness.onSetUp()';
    }
    for (var port in _ports) {
      final agent = await _startInstance(port);
      _agents.putIfAbsent(port, () => agent);
    }
    _agents.putIfAbsent(80, () => agent);
    return channel.manager.readyAsync();
  }

  @override
  Future onSetUp() async {
    channel.resume();
  }

  @override
  Future onTearDown() async {
    channel.pause();
    if (eventStoreMockServer != null) {
      eventStoreMockServer.clear();
    }
  }

  @override
  Future stop() async {
    await _deleteTestData();
    await channel.dispose();
    for (var instance in _instances) {
      await instance.channel.dispose();
      await instance.stop();
    }
    if (eventStoreMockServer != null) {
      await eventStoreMockServer.close();
    }
    _agents.clear();
    _instances.clear();
    assert(
      SecureRouter.getContexts().isEmpty,
      'Contexts should be empty',
    );
    return super.stop();
  }

  Future<Agent> _startInstance(int port) async {
    final application = Application<SarSysAppServerChannel>()..options = options;
    _configureContext(application);
    await application.startOnCurrentIsolate();
    application.channel.config.logging.stdout = false;
    final agent = Agent(application);
    await application.channel.manager.readyAsync();
    _instances.add(application);
    if (_withGrpcServer) {
      application.options.context['GRPC_PORT'] = _grpcPort + _instances.length;
    }
    application.options.context['GRPC_ENABLED'] = _withGrpcServer;

    return agent;
  }
}

//////////////////////////////////
// Common assertions
//////////////////////////////////

Future expectAggregateInList(
  SarSysAppHarness harness, {
  String uri,
  String uuid,
  int port = 80,
  String listField,
  List<String> uuids,
}) async {
  final response = expectResponse(await harness.agents[port].get('$uri/$uuid'), 200);
  final actual = await response.body.decode();
  expect(
    Map.from(actual['data'] as Map).elementAt(listField),
    equals(uuids),
  );
}

Future expectAggregateReference(
  SarSysAppHarness harness, {
  String uri,
  int port = 80,
  String childUuid,
  Map<String, dynamic> child,
  String parentField,
  String parentUuid,
}) async {
  final response = expectResponse(await harness.agents[port].get('$uri/$childUuid'), 200);
  final actual = await response.body.decode();
  expect(
      Map.from(actual).elementAt('data/$parentField'),
      equals({
        'uuid': parentUuid,
      }));
}

Map<String, String> createAuthn(String value) => {'Authorization': value};

String createAuthnAdmin({List<String> required = const ['personnel']}) => createBearerToken(
      createJWT(
        ['admin', ...required],
      ),
    );

String createAuthnCommander({List<String> required = const ['personnel']}) => createBearerToken(
      createJWT(
        ['commander', ...required],
      ),
    );

String createAuthnUnitLeader({List<String> required = const ['personnel']}) => createBearerToken(
      createJWT(
        ['unit_leader', ...required],
      ),
    );

String createAuthnPersonnel() => createBearerToken(
      createJWT(const ['personnel']),
    );

String createJWT(List<String> roles) => issueJwtHS256(
      JwtClaim(
        subject: 'kleak',
        issuer: 'sarsys',
        otherClaims: <String, dynamic>{
          'roles': roles,
        },
        maxAge: const Duration(minutes: 5),
      ),
      's3cr3t',
    );

String createBearerToken(String jwt) => 'Bearer $jwt';

//////////////////////////////////
// Common domain objects
//////////////////////////////////

Map<String, dynamic> createIncident(String uuid) => {
      'uuid': uuid,
      'name': 'string',
      'summary': 'string',
      'type': 'lost',
      'status': 'registered',
      'resolution': 'unresolved',
      'occurred': DateTime.now().toIso8601String(),
    };

Map<String, dynamic> createClue(String id) => {
      'id': id,
      'name': 'string',
      'description': 'string',
      'type': 'find',
      'quality': 'confirmed',
      'location': {
        'point': createPoint(),
        'address': createAddress(),
        'description': 'string',
      }
    };

Map<String, dynamic> createSubject(String uuid) => {
      'uuid': uuid,
      'name': 'string',
      'situation': 'string',
      'type': 'person',
      'location': createLocation(),
    };

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

Map<String, dynamic> createOperation(String uuid) => {
      'uuid': uuid,
      'name': 'string',
      'type': 'search',
      'status': 'planned',
      'resolution': 'unresolved',
      'reference': 'string',
      'justification': 'string',
      'commander': {
        'uuid': 'string',
      },
      'ipp': createLocation(),
      'meetup': createLocation(),
      'passcodes': {'commander': 'string', 'personnel': 'string'},
    };

Map<String, dynamic> createObjective(String id) => {
      'id': id,
      'name': 'string',
      'description': 'string',
      'type': 'locate',
      'location': [
        {
          'point': createPoint(),
          'address': createAddress(),
          'description': 'string',
        }
      ],
      'resolution': 'unresolved'
    };

Map<String, dynamic> createTalkGroup(String id) => {
      'id': id,
      'name': 'string',
      'type': 'tetra',
    };

Map<String, dynamic> createLocation() => {
      'point': createPoint(),
      'address': createAddress(),
      'description': 'string',
    };

Map<String, dynamic> createMission(String uuid) => {
      'uuid': uuid,
      'description': 'string',
      'type': 'search',
      'status': 'created',
      'priority': 'medium',
      'resolution': 'unresolved',
    };

Map<String, dynamic> createMissionPart(String id) => {
      'id': id,
      'name': 'string',
      'description': 'string',
      'data': {
        'type': 'FeatureCollection',
        'features': [
          {
            'type': 'Feature',
            'geometry': {'type': 'Point'},
            'properties': {'name': 'string', 'description': 'string'}
          }
        ]
      }
    };

Map<String, dynamic> createMissionResult(String id) => {
      'id': id,
      'name': 'string',
      'description': 'string',
      'data': {
        'type': 'FeatureCollection',
        'features': [
          {
            'type': 'Feature',
            'geometry': {'type': 'Point'},
            'properties': {'name': 'string', 'description': 'string'}
          }
        ]
      }
    };

Map<String, dynamic> createPerson(
  String uuid, {
  String userId,
  String fname = 'fname',
  String lname = 'lname',
  String email = 'email',
  String phone = 'phone',
  bool temporary = false,
}) =>
    {
      'uuid': uuid,
      'fname': fname,
      'lname': lname,
      'phone': phone,
      'email': email,
      'temporary': temporary,
      if (userId != null) 'userId': userId,
    };

Map<String, dynamic> createPersonnel(
  String uuid, {
  String auuid,
  String ouuid,
  String uuuid,
  String tuuid,
  Map<String, dynamic> affiliate,
}) =>
    {
      'uuid': uuid,
      'status': 'alerted',
      'function': 'personnel',
      if (tuuid != null) 'tracking': {'uuid': tuuid},
      if (ouuid != null) 'operation': {'uuid': ouuid},
      if (uuuid != null) 'unit': {'uuid': uuuid},
      if (auuid != null || affiliate != null) 'affiliation': affiliate ?? {'uuid': auuid},
    };

Map<String, dynamic> createAffiliation(
  String uuid, {
  String puuid,
  String orguuid,
  String divuuid,
  String depuuid,
  Map<String, dynamic> person,
}) =>
    {
      'uuid': uuid,
      'type': 'member',
      'status': 'available',
      'active': true,
      if (puuid != null || person != null) 'person': person ?? {'uuid': puuid},
      if (orguuid != null) 'org': {'uuid': orguuid},
      if (divuuid != null) 'div': {'uuid': divuuid},
      if (depuuid != null) 'dep': {'uuid': depuuid},
    };

Map<String, dynamic> createUnit(String uuid, {String tuuid, List<String> puuids = const []}) => {
      'uuid': uuid,
      'type': 'team',
      'number': 0,
      'phone': 'string',
      'callsign': 'string',
      'status': 'mobilized',
      if (puuids.isNotEmpty) 'personnels': puuids,
      if (tuuid != null) 'tracking': {'uuid': tuuid}
    };

Map<String, dynamic> createOrganisation(String uuid) => {
      'uuid': uuid,
      'name': 'string',
      'prefix': 'string',
      'active': true,
    };

Map<String, dynamic> createDivision(String uuid) => {
      'uuid': uuid,
      'name': 'string',
      'suffix': 'string',
      'active': true,
    };

Map<String, dynamic> createDepartment(String uuid) => {
      'uuid': uuid,
      'name': 'string',
      'suffix': 'string',
      'active': true,
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

Map<String, dynamic> createMessage(String id) => {
      'id': id,
      'type': 'clue',
      'subject': 'string',
      'body': {'additionalProp1': {}}
    };
