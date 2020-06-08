import 'package:aqueduct_test/aqueduct_test.dart';
import 'package:event_source/event_source.dart';
import 'package:jaguar_jwt/jaguar_jwt.dart';
import 'package:sarsys_app_server/sarsys_app_server.dart';
import 'package:test/test.dart';

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
///           test("GET /path returns 200", () async {
///             final response = await harness.agent.get("/path");
///             expectResponse(response, 200);
///           });
///         }
///
class SarSysHarness extends TestHarness<SarSysAppServerChannel> {
  EventStoreMockServer eventStoreMockServer;

  EventStoreMockServer withEventStoreMock() => eventStoreMockServer = EventStoreMockServer(
        'discoos',
        'test',
        4000,
      );

  @override
  Future beforeStart() async {
    if (eventStoreMockServer != null) {
      await eventStoreMockServer.open();
    }
  }

  @override
  Future onSetUp() async {
    if (eventStoreMockServer != null) {
      eventStoreMockServer.withProjection('\$by_category');
      eventStoreMockServer.withProjection('\$by_event_type');
    }
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
    if (eventStoreMockServer != null) {
      await eventStoreMockServer.close();
    }
    return super.stop();
  }
}

//////////////////////////////////
// Common assertions
//////////////////////////////////

Future expectAggregateInList(
  SarSysHarness harness, {
  String uri,
  String uuid,
  Map<String, dynamic> data,
  String listField,
  List<String> uuids,
}) async {
  final response = expectResponse(await harness.agent.get("$uri/$uuid"), 200);
  final actual = await response.body.decode();
  expect(
    actual['data'],
    equals(data..addAll({listField: uuids})),
  );
}

Future expectAggregateReference(
  SarSysHarness harness, {
  String uri,
  String childUuid,
  Map<String, dynamic> child,
  String parentField,
  String parentUuid,
}) async {
  final response = expectResponse(await harness.agent.get("$uri/$childUuid"), 200);
  final actual = await response.body.decode();
  expect(
    actual['data'],
    equals(child
      ..addAll({
        '$parentField': {
          'uuid': parentUuid,
        }
      })),
  );
}

Map<String, String> createAuthn(String value) => {'Authorization': value};

String createAuthnAdmin({List<String> required = const ['personnel']}) => createBearerToken(
      createJWT(
        ['admin']..addAll(required),
      ),
    );

String createAuthnCommander({List<String> required = const ['personnel']}) => createBearerToken(
      createJWT(
        ['commander']..addAll(required),
      ),
    );

String createAuthnUnitLeader({List<String> required = const ['personnel']}) => createBearerToken(
      createJWT(
        ['unit_leader']..addAll(required),
      ),
    );

String createAuthnPersonnel({List<String> required = const ['personnel']}) => createBearerToken(
      createJWT(required),
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

String createBearerToken(String jwt) => "Bearer $jwt";

//////////////////////////////////
// Common domain objects
//////////////////////////////////

Map<String, dynamic> createIncident(String uuid) => {
      "uuid": "$uuid",
      "name": "string",
      "summary": "string",
      "type": "lost",
      "status": "registered",
      "resolution": "unresolved",
      "occurred": DateTime.now().toIso8601String(),
      "subjects": ["string"],
      "operations": ["string"]
    };

Map<String, dynamic> createClue(String id) => {
      "id": id,
      "name": "string",
      "description": "string",
      "type": "find",
      "quality": "confirmed",
      "location": {
        "point": createPoint(),
        "address": createAddress(),
        "description": "string",
      }
    };

Map<String, dynamic> createSubject(String uuid) => {
      "uuid": "$uuid",
      "name": "string",
      "situation": "string",
      "type": "person",
      "location": createLocation(),
    };

Map<String, dynamic> createPoint() => {
      "type": "Point",
      "coordinates": [0.0, 0.0]
    };

Map<String, String> createAddress() => {
      "lines": "string",
      "city": "string",
      "postalCode": "string",
      "countryCode": "string",
    };

Map<String, dynamic> createOperation(String uuid) => {
      "uuid": "$uuid",
      "name": "string",
      "type": "search",
      "status": "planned",
      "resolution": "unresolved",
      "reference": "string",
      "justification": "string",
      "commander": {
        "uuid": "string",
      },
      "ipp": createLocation(),
      "meetup": createLocation(),
      "missions": ["string"],
      "units": ["string"],
      "personnels": ["string"],
      "passcodes": {"commander": "string", "personnel": "string"},
    };

Map<String, dynamic> createObjective(String id) => {
      "id": id,
      "name": "string",
      "description": "string",
      "type": "locate",
      "location": [
        {
          "point": createPoint(),
          "address": createAddress(),
          "description": "string",
        }
      ],
      "resolution": "unresolved"
    };

Map<String, dynamic> createTalkGroup(String id) => {
      "id": id,
      "name": 'string',
      "type": "tetra",
    };

Map<String, dynamic> createLocation() => {
      "point": createPoint(),
      "address": createAddress(),
      "description": "string",
    };

Map<String, dynamic> createMission(String uuid) => {
      "uuid": "$uuid",
      "description": "string",
      "type": "search",
      "status": "created",
      "priority": "medium",
      "resolution": "unresolved",
    };

Map<String, dynamic> createMissionPart(String id) => {
      "id": id,
      "name": "string",
      "description": "string",
      "data": {
        "type": "FeatureCollection",
        "features": [
          {
            "type": "Feature",
            "geometry": {"type": "Point"},
            "properties": {"name": "string", "description": "string"}
          }
        ]
      }
    };

Map<String, dynamic> createMissionResult(String id) => {
      "id": id,
      "name": "string",
      "description": "string",
      "data": {
        "type": "FeatureCollection",
        "features": [
          {
            "type": "Feature",
            "geometry": {"type": "Point"},
            "properties": {"name": "string", "description": "string"}
          }
        ]
      }
    };

Map<String, dynamic> createPersonnel(String uuid, {String tuuid}) => {
      "uuid": "$uuid",
      "fname": "string",
      "lname": "string",
      "phone": "string",
      "status": "mobilized",
      if (tuuid != null) "tracking": {"uuid": tuuid}
    };

Map<String, dynamic> createUnit(String uuid, {String tuuid}) => {
      "uuid": "$uuid",
      "type": "team",
      "number": 0,
      "phone": "string",
      "callsign": "string",
      "status": "mobilized",
      "personnels": ["string"],
      if (tuuid != null) "tracking": {"uuid": tuuid}
    };

Map<String, dynamic> createOrganisation(String uuid) => {
      "uuid": "$uuid",
      "name": "string",
      "alias": "string",
      "icon": "https://icon.com",
      "divisions": ["string"],
    };

Map<String, dynamic> createDivision(String uuid) => {
      "uuid": "$uuid",
      "name": "string",
      "alias": "string",
      "departments": ["string"],
    };

Map<String, dynamic> createDepartment(String uuid) => {
      "uuid": "$uuid",
      "name": "string",
      "alias": "string",
    };

Map<String, dynamic> createTracking(String uuid) => {
      "uuid": "$uuid",
    };

Map<String, dynamic> createSource({String uuid = 'string', String type = 'device'}) => {
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

Map<String, Object> createPosition({String type = 'manual'}) => {
      "type": "Feature",
      "geometry": {
        "type": "Point",
        "coordinates": [0.0, 0.0]
      },
      "properties": {
        "name": "string",
        "description": "string",
        "accuracy": 0,
        "timestamp": DateTime.now().toIso8601String(),
        "source": "$type"
      }
    };

Map<String, dynamic> createDevice(String uuid) => {
      "uuid": "$uuid",
      "name": "string",
      "alias": "string",
      "network": "string",
      "networkId": "string",
    };

Map<String, dynamic> createMessage(String id) => {
      "id": id,
      "type": "clue",
      "subject": "string",
      "body": {"additionalProp1": {}}
    };
