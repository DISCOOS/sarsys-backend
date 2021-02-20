import 'package:uuid/uuid.dart';
import 'package:test/test.dart';

import 'package:sarsys_app_server_test/sarsys_app_server_test.dart';

Future main() async {
  final harness = SarSysAppHarness()
    ..withEventStoreMock()
    ..install(restartForEachTest: true);

  test("POST /api/affiliations/onboard creates permanent person", () async {
    final auuid = Uuid().v4();
    final puuid = Uuid().v4();
    final orguuid = Uuid().v4();
    await _prepare(harness, puuid: puuid, orguuid: orguuid);
    final person = createPerson(puuid);
    final affiliation = createAffiliation(auuid, puuid: puuid, orguuid: orguuid);
    final body = {
      'person': person,
      'affiliation': affiliation,
    };

    // Act
    expectResponse(await harness.agent.post("/api/affiliations/onboard", body: body), 201, body: null);

    // Assert
    final response1 = expectResponse(await harness.agent.get("/api/persons/$puuid"), 200);
    final actualPerson = await response1.body.decode();
    expect(actualPerson['data'], person);
    final response2 = expectResponse(await harness.agent.get("/api/affiliations/$auuid"), 200);
    final actualAffiliation = await response2.body.decode();
    expect(actualAffiliation['data'], affiliation);
  });

  test("POST /api/affiliations/onboard returns status code 409 when temporary person exists", () async {
    final auuid = Uuid().v4();
    final puuid = Uuid().v4();
    final orguuid = Uuid().v4();
    await _prepare(harness, puuid: puuid, orguuid: orguuid);
    final person = createPerson(puuid, temporary: true);
    final affiliation = createAffiliation(auuid, puuid: puuid, orguuid: orguuid);
    final body = {
      'person': createPerson(puuid, temporary: false),
      'affiliation': affiliation,
    };
    // Act
    expectResponse(await harness.agent.post("/api/persons", body: person), 201);

    // Assert
    expectResponse(await harness.agent.post("/api/affiliations/onboard", body: body), 409, body: null);
  });

  test("POST /api/affiliations/onboard creates temporary person", () async {
    final auuid = Uuid().v4();
    final puuid = Uuid().v4();
    final orguuid = Uuid().v4();
    await _prepare(harness, puuid: puuid, orguuid: orguuid);
    final person = createPerson(puuid);
    final affiliation = createAffiliation(auuid, puuid: puuid, orguuid: orguuid);
    final body = {
      'person': person,
      'affiliation': affiliation,
    };

    // Act
    expectResponse(await harness.agent.post("/api/affiliations/onboard", body: body), 201, body: null);

    // Assert
    final response1 = expectResponse(await harness.agent.get("/api/persons/$puuid"), 200);
    final actualPerson = await response1.body.decode();
    expect(actualPerson['data'], person);
    final response2 = expectResponse(await harness.agent.get("/api/affiliations/$auuid"), 200);
    final actualAffiliation = await response2.body.decode();
    expect(actualAffiliation['data'], affiliation);
  });

  test("POST /api/affiliations/temporary returns status code 409 when permanent person exists", () async {
    final auuid = Uuid().v4();
    final puuid = Uuid().v4();
    final orguuid = Uuid().v4();
    await _prepare(harness, puuid: puuid, orguuid: orguuid);
    final person = createPerson(puuid, temporary: false);
    final affiliation = createAffiliation(auuid, puuid: puuid, orguuid: orguuid);
    final body = {
      'person': createPerson(puuid, temporary: true),
      'affiliation': affiliation,
    };

    // Act
    expectResponse(await harness.agent.post("/api/persons", body: person), 201);

    // Assert
    expectResponse(await harness.agent.post("/api/affiliations/onboard", body: body), 409, body: null);
  });
}

Future _prepare(
  SarSysAppHarness harness, {
  String puuid,
  String orguuid,
  String divuuid,
  String depuuid,
}) async {
  await harness.channel.manager.readyAsync();
  if (orguuid != null) {
    expectResponse(
      await harness.agent.post("/api/organisations", body: createOrganisation(orguuid)),
      201,
    );
  }
  if (divuuid != null) {
    expectResponse(
      await harness.agent.post("/api/organisations/$orguuid/divisions", body: createDivision(divuuid)),
      201,
    );
  }
  if (depuuid != null) {
    expectResponse(
      await harness.agent.post("/api/divisions/$divuuid/departments", body: createDepartment(depuuid)),
      201,
    );
  }
}
