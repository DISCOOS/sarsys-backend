import 'package:sarsys_app_server/sarsys_app_server.dart';
import 'package:aqueduct_test/aqueduct_test.dart';
import 'package:test/test.dart';

import '../eventsource/eventstore_mock_server.dart';

export 'package:sarsys_app_server/sarsys_app_server.dart';
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
      eventStoreMockServer.withProjection('by_category');
    }
  }

  @override
  Future onTearDown() async {
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

// =====================
// Common assertions
// =====================

Future expectAggregateInList(
  SarSysHarness harness, {
  String uri,
  String uuid,
  Map<String, Object> data,
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
  Map<String, Object> child,
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

// =====================
// Common domain objects
// =====================

Map<String, Object> createIncident(String uuid) => {
      "uuid": "$uuid",
      "name": "string",
      "summary": "string",
      "type": "lost",
      "status": "registered",
      "resolution": "unresolved",
      "occurred": DateTime.now().toIso8601String(),
      "clues": [
        createClue(0),
      ],
      "subjects": ["string"],
      "operations": ["string"]
    };

Map<String, dynamic> createClue(int id) => {
      "id": id,
      "name": "string",
      "description": "string",
      "type": "find",
      "quality": "confirmed",
      "location": {
        "position": createPoint(),
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

Map<String, Object> createPoint() => {
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
        "type": "manual"
      }
    };

Map<String, String> createAddress() => {
      "lines": "string",
      "city": "string",
      "postalCode": "string",
      "countryCode": "string",
    };

Map<String, Object> createOperation(String uuid) => {
      "uuid": "$uuid",
      "name": "string",
      "type": "search",
      "status": "planned",
      "resolution": "unresolved",
      "reference": "string",
      "justification": "string",
      "commander": "string",
      "talkgroups": [
        {"id": 0, "name": true, "type": "tetra"}
      ],
      "ipp": createLocation(),
      "meetup": createLocation(),
      "objectives": [
        createObjective(0),
        createObjective(1),
      ],
      "missions": ["string"],
      "units": ["string"],
      "personnels": ["string"],
      "passcodes": {"commander": "string", "personnel": "string"},
    };

Map<String, Object> createObjective(int id) => {
      "id": id,
      "name": "string",
      "description": "string",
      "type": "locate",
      "location": [
        {
          "position": createPoint(),
          "address": createAddress(),
          "description": "string",
        }
      ],
      "resolution": "unresolved"
    };

Map<String, Object> createLocation() => {
      "position": createPoint(),
      "address": createAddress(),
      "description": "string",
    };

Map<String, Object> createMission(String uuid) => {
      "uuid": "$uuid",
      "description": "string",
      "type": "search",
      "status": "created",
      "priority": "medium",
      "resolution": "unresolved",
      "parts": [
        createMissionPart(0),
        createMissionPart(1),
      ],
      "results": [
        createMissionResult(0),
        createMissionResult(1),
      ],
      "assignedTo": "string"
    };

Map<String, Object> createMissionPart(int id) => {
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

Map<String, Object> createMissionResult(int id) => {
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

Map<String, Object> createPersonnel(String uuid) => {
      "uuid": "$uuid",
      "fname": "string",
      "lname": "string",
      "phone": "string",
      "status": "mobilized",
    };

Map<String, Object> createUnit(String uuid) => {
      "uuid": "$uuid",
      "type": "team",
      "number": 0,
      "phone": "string",
      "callsign": "string",
      "status": "mobilized",
      "personnels": ["string"],
    };

Map<String, Object> createOrganisation(String uuid) => {
      "uuid": "$uuid",
      "name": "string",
      "alias": "string",
      "icon": "https://icon.com",
      "divisions": ["string"],
    };

Map<String, Object> createDivision(String uuid) => {
      "uuid": "$uuid",
      "name": "string",
      "alias": "string",
      "departments": ["string"],
    };

Map<String, Object> createDepartment(String uuid) => {
      "uuid": "$uuid",
      "name": "string",
      "alias": "string",
    };
