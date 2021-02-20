import 'package:uuid/uuid.dart';
import 'package:test/test.dart';

import 'package:sarsys_app_server_test/sarsys_app_server_test.dart';

Future main() async {
  final harness = SarSysAppHarness()
    ..withEventStoreMock()
    ..install(restartForEachTest: true);

  test("GET /api/operations/{uuid}/tracking returns status code 200", () async {
    // Arrange
    final ouuid = await _prepare(harness);
    final tuuid1 = Uuid().v4();
    final tuuid2 = Uuid().v4();
    await _addUnit(harness, ouuid: ouuid, tuuid: tuuid1);
    await _addPersonnel(harness, ouuid: ouuid, tuuid: tuuid2);

    // Act
    final response = expectResponse(await harness.agent.get("/api/operations/$ouuid/trackings"), 200);

    // Assert
    final actual = await response.body.decode();
    expect(actual['total'], equals(2));
    expect(actual['entries'].length, equals(2));
  });

  test("GET /api/operations/{uuid}/tracking returns status code 200 with include=unit", () async {
    // Arrange
    final ouuid = await _prepare(harness);
    final tuuid1 = Uuid().v4();
    final tuuid2 = Uuid().v4();
    await _addUnit(harness, ouuid: ouuid, tuuid: tuuid1);
    await _addPersonnel(harness, ouuid: ouuid, tuuid: tuuid2);

    // Act
    final response = expectResponse(await harness.agent.get("/api/operations/$ouuid/trackings?include=unit"), 200);

    // Assert
    final actual = await response.body.decode();
    expect(actual['total'], equals(1));
    expect(actual['entries'].length, equals(1));
  });

  test("GET /api/operations/{uuid}/tracking returns status code 200 with include=personnel", () async {
    // Arrange
    final ouuid = await _prepare(harness);
    final tuuid1 = Uuid().v4();
    final tuuid2 = Uuid().v4();
    await _addUnit(harness, ouuid: ouuid, tuuid: tuuid1);
    await _addPersonnel(harness, ouuid: ouuid, tuuid: tuuid2);

    // Act
    final response = expectResponse(await harness.agent.get("/api/operations/$ouuid/trackings?include=personnel"), 200);

    // Assert
    final actual = await response.body.decode();
    expect(actual['total'], equals(1));
    expect(actual['entries'].length, equals(1));
  });
}

Future<String> _prepare(SarSysAppHarness harness) async {
  final iuuid = Uuid().v4();
  expectResponse(await harness.agent.post("/api/incidents", body: createIncident(iuuid)), 201);
  final ouuid = Uuid().v4();
  expectResponse(await harness.agent.post("/api/incidents/$iuuid/operations", body: createOperation(ouuid)), 201);
  return ouuid;
}

Future _addUnit(SarSysAppHarness harness, {String ouuid, String tuuid}) async {
  final uuuid = Uuid().v4();
  final unit = createUnit(uuuid, tuuid: tuuid);
  expectResponse(await harness.agent.post("/api/operations/$ouuid/units", body: unit), 201, body: null);
}

Future _addPersonnel(SarSysAppHarness harness, {String ouuid, String tuuid}) async {
  final puuid = Uuid().v4();
  final personnel = createPersonnel(puuid, auuid: await _createAffiliation(harness, Uuid().v4()), tuuid: tuuid);
  expectResponse(await harness.agent.post("/api/operations/$ouuid/personnels", body: personnel), 201, body: null);
}

Future<String> _createAffiliation(SarSysAppHarness harness, String auuid) async {
  final puuid = Uuid().v4();
  expectResponse(await harness.agent.post("/api/persons", body: createPerson(puuid)), 201);
  final orguuid = Uuid().v4();
  expectResponse(await harness.agent.post("/api/organisations", body: createOrganisation(orguuid)), 201);
  expectResponse(
      await harness.agent.post("/api/affiliations",
          body: createAffiliation(
            auuid,
            puuid: puuid,
            orguuid: orguuid,
          )),
      201);
  return auuid;
}
