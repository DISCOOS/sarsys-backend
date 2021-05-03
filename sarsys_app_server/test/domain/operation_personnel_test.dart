import 'package:uuid/uuid.dart';
import 'package:test/test.dart';
import 'package:collection_x/collection_x.dart';

import 'package:sarsys_app_server_test/sarsys_app_server_test.dart';

Future main() async {
  final harness = SarSysAppHarness()
    ..withEventStoreMock()
    ..install(restartForEachTest: true);

  test("POST /api/operations/{uuid}/personnels/ returns status code 201 with empty body", () async {
    // Arrange
    final puuid = Uuid().v4();
    final auuid = Uuid().v4();
    final ouuid = await _prepare(harness);
    final person = createPerson(puuid);
    final affiliation = createAffiliation(auuid, person: person);
    final personnel = createPersonnel(puuid, affiliate: affiliation);

    // Assert
    expectResponse(
      await harness.agent.post("/api/operations/$ouuid/personnels", body: personnel),
      201,
      body: null,
    );
  });

  test("POST /api/operations/{uuid}/personnels/ returns status code 201 with tracking enabled", () async {
    // Arrange
    final puuid = Uuid().v4();
    final auuid = Uuid().v4();
    final tuuid = Uuid().v4();
    final ouuid = await _prepare(harness);
    final person = createPerson(puuid);
    final affiliation = createAffiliation(auuid, person: person);
    final personnel = createPersonnel(puuid, affiliate: affiliation, tuuid: tuuid);
    expectResponse(
      await harness.agent.post("/api/operations/$ouuid/personnels", body: personnel),
      201,
      body: null,
    );
  });

  test("POST /api/operations/{uuid}/personnels returns status code 400 when 'operation/uuid' is given", () async {
    final puuid = Uuid().v4();
    final auuid = Uuid().v4();
    final ouuid = await _prepare(harness);
    final person = createPerson(puuid);
    final affiliation = createAffiliation(auuid, person: person);
    final personnel = createPersonnel(puuid, affiliate: affiliation)
      ..addAll({
        'operation': {'uuid': 'string'}
      });
    expectResponse(
      await harness.agent.post("/api/operations/$ouuid/personnels", body: personnel),
      400,
      body: 'Schema Personnel has 1 errors: [/operation: is read only]',
    );
  });

  test("POST /api/operations/{uuid}/personnels creates permanent person", () async {
    final auuid = Uuid().v4();
    final puuid = Uuid().v4();
    final ouuid = await _prepare(harness);
    final person = createPerson(puuid);
    final affiliation = createAffiliation(auuid, person: person);
    final personnel = createPersonnel(puuid, affiliate: affiliation);
    final affiliate = Map.from(affiliation);
    affiliate['person'] = person;

    // Act
    expectResponse(
      await harness.agent.post("/api/operations/$ouuid/personnels", body: personnel),
      201,
      body: null,
    );

    // Assert
    final response1 = expectResponse(await harness.agent.get("/api/persons/$puuid"), 200);
    final actualPerson = await response1.body.decode();
    expect(actualPerson['data'], person);
    final response2 = expectResponse(await harness.agent.get("/api/affiliations/$auuid?expand=person"), 200);
    final actualAffiliation = await response2.body.decode();
    expect(actualAffiliation['data'], affiliation);
  });

  test("POST /api/operations/{uuid}/personnels creates temporary person", () async {
    final auuid = Uuid().v4();
    final puuid = Uuid().v4();
    final ouuid = await _prepare(harness);
    final person = createPerson(puuid, temporary: true);
    final affiliation = createAffiliation(auuid, person: person);
    final personnel = createPersonnel(puuid, affiliate: affiliation);
    final affiliate = Map.from(affiliation);
    affiliate['person'] = person;

    // Act
    expectResponse(
      await harness.agent.post("/api/operations/$ouuid/personnels", body: personnel),
      201,
      body: null,
    );

    // Assert
    final response1 = expectResponse(await harness.agent.get("/api/persons/$puuid"), 200);
    final actualPerson = await response1.body.decode();
    expect(actualPerson['data'], person);
    final response2 = expectResponse(await harness.agent.get("/api/affiliations/$auuid?expand=person"), 200);
    final actualAffiliation = await response2.body.decode();
    expect(actualAffiliation['data'], affiliation);
  });

  test("POST /api/operations/{uuid}/personnels returns status code 201 when same person exists", () async {
    final auuid = Uuid().v4();
    final puuid = Uuid().v4();
    final ouuid = await _prepare(harness);
    final person = createPerson(puuid);
    final affiliation = createAffiliation(auuid, person: person);
    final personnel = createPersonnel(puuid, affiliate: affiliation);

    // Act
    expectResponse(await harness.agent.post("/api/persons", body: person), 201);

    // Assert
    expectResponse(
      await harness.agent.post("/api/operations/$ouuid/personnels", body: personnel),
      201,
      body: null,
    );
    final response1 = expectResponse(await harness.agent.get("/api/persons/$puuid"), 200);
    final actualPerson = await response1.body.decode();
    expect(actualPerson['data'], person);
    final response2 = expectResponse(await harness.agent.get("/api/affiliations/$auuid?expand=person"), 200);
    final actualAffiliation = await response2.body.decode();
    expect(actualAffiliation['data'], affiliation);
  });

  test("POST /api/operations/{uuid}/personnels returns status code 201 when person is updated", () async {
    final auuid = Uuid().v4();
    final puuid = Uuid().v4();
    final ouuid = await _prepare(harness);
    final person = createPerson(puuid);
    final affiliation = createAffiliation(auuid, puuid: puuid);
    final updated = Map.from(person)..addAll({'fname': 'updated'});
    final affiliate = Map<String, dynamic>.from(affiliation);
    affiliate['person'] = updated;
    final personnel = createPersonnel(puuid, affiliate: affiliate);

    // Act
    expectResponse(await harness.agent.post("/api/persons", body: person), 201);

    // Assert
    expectResponse(
      await harness.agent.post("/api/operations/$ouuid/personnels", body: personnel),
      201,
      body: null,
    );
    final response1 = expectResponse(await harness.agent.get("/api/persons/$puuid"), 200);
    final actualPerson = await response1.body.decode();
    expect(actualPerson['data'], updated);
  });

  test("POST /api/operations/{uuid}/personnels returns status code 409 when same user exists", () async {
    const userId = 'user1';
    final ouuid = await _prepare(harness);
    final existing = createAffiliation(Uuid().v4(), person: createPerson(Uuid().v4(), userId: userId));
    final duplicate = createAffiliation(Uuid().v4(), person: createPerson(Uuid().v4(), userId: userId));
    final personnel = createPersonnel(Uuid().v4(), affiliate: duplicate);

    // Act
    expectResponse(await harness.agent.post("/api/affiliations", body: existing), 201);

    // Assert
    final response = expectResponse(
      await harness.agent.post("/api/operations/$ouuid/personnels", body: personnel),
      409,
    );

    // Assert
    final conflict = await response.body.decode() as Map<String, dynamic>;
    expect(
      conflict.elementAt<String>('code'),
      'duplicate_user_id',
    );
    expect(
      conflict.mapAt<String, dynamic>('base'),
      existing.mapAt('person'),
    );
    expect(
      conflict.listAt<Map<String, dynamic>>('mine'),
      [existing],
    );
    expect(
      conflict.listAt<Map<String, dynamic>>('yours'),
      [duplicate],
    );
  });

  test("POST /api/operations/{uuid}/personnels returns status code 409 when unorganized affiliate exists", () async {
    // Arrange
    final puuid = Uuid().v4();
    final ouuid = await _prepare(harness);
    final unorganized = createAffiliation(Uuid().v4(), puuid: puuid);
    final duplicate = createAffiliation(Uuid().v4(), puuid: puuid);
    final personnel = createPersonnel(puuid, affiliate: duplicate);

    // Act
    expectResponse(await harness.agent.post("/api/affiliations", body: unorganized), 201);

    // Assert
    final response = expectResponse(
      await harness.agent.post("/api/operations/$ouuid/personnels", body: personnel),
      409,
    );

    // Assert
    final conflict = await response.body.decode() as Map<String, dynamic>;
    expect(
      conflict.elementAt<String>('code'),
      'duplicate_affiliations',
    );
    expect(
      conflict.mapAt<String, dynamic>('base'),
      isNull,
    );
    expect(
      conflict.listAt<Map<String, dynamic>>('mine'),
      [unorganized],
    );
    expect(
      conflict.listAt<Map<String, dynamic>>('yours'),
      [duplicate],
    );
  });

  test("POST /api/operations/{uuid}/personnels returns status code 409 when organized affiliate exists", () async {
    // Arrange
    final puuid = Uuid().v4();
    final ouuid = await _prepare(harness);
    final organized = createAffiliation(Uuid().v4(), puuid: puuid, orguuid: ouuid);
    final duplicate = createAffiliation(Uuid().v4(), puuid: puuid, orguuid: ouuid);
    final personnel = createPersonnel(puuid, affiliate: duplicate);

    // Act
    expectResponse(await harness.agent.post("/api/affiliations", body: organized), 201);

    // Assert
    final response = expectResponse(
      await harness.agent.post("/api/operations/$ouuid/personnels", body: personnel),
      409,
    );

    // Assert
    final conflict = await response.body.decode() as Map<String, dynamic>;
    expect(
      conflict.elementAt<String>('code'),
      'duplicate_affiliations',
    );
    expect(
      conflict.mapAt<String, dynamic>('base'),
      isNull,
    );
    expect(
      conflict.listAt<Map<String, dynamic>>('mine'),
      [organized],
    );
    expect(
      conflict.listAt<Map<String, dynamic>>('yours'),
      [duplicate],
    );
  });

  test("POST /api/operations/{uuid}/personnels adds personnel to aggregate list", () async {
    final puuid = Uuid().v4();
    final auuid = Uuid().v4();
    final ouuid = await _prepare(harness);
    final personnel = createPersonnel(
      puuid,
      affiliate: createAffiliation(
        auuid,
        person: createPerson(puuid),
      ),
    );
    expectResponse(
      await harness.agent.post(
        "/api/operations/$ouuid/personnels",
        body: personnel,
      ),
      201,
      body: null,
    );
    await expectAggregateReference(
      harness,
      uri: '/api/personnels',
      childUuid: puuid,
      child: personnel,
      parentField: 'operation',
      parentUuid: ouuid,
    );
    await expectAggregateInList(
      harness,
      uri: '/api/operations',
      uuid: ouuid,
      listField: 'personnels',
      uuids: [
        puuid,
      ],
    );
  });

  test("GET /api/operations/{uuid}/personnels returns 200 with offset=1&limit=2", () async {
    await _testGetAll(harness, expand: false);
  });

  test("GET /api/operations/{uuid}/personnels returns 200 with offset=1&limit=2&expand=person", () async {
    await _testGetAll(harness, expand: true);
  });

  test("DELETE /api/personnels/{uuid} should remove {uuid} from personnels list in operation", () async {
    final ouuid = await _prepare(harness);
    final puuid = Uuid().v4();
    final auuid = Uuid().v4();
    await _createAffiliation(harness, auuid);
    final personnel = createPersonnel(
      puuid,
      auuid: auuid,
    );
    expectResponse(await harness.agent.post("/api/operations/$ouuid/personnels", body: personnel), 201, body: null);
    expectResponse(await harness.agent.delete("/api/personnels/$puuid"), 204);
    await expectAggregateInList(
      harness,
      uri: '/api/operations',
      uuid: ouuid,
      listField: 'personnels',
      uuids: [],
    );
  });
}

Future _testGetAll(SarSysAppHarness harness, {bool expand = false}) async {
  final ouuid = await _prepare(harness);
  await harness.agent.post(
    "/api/operations/$ouuid/personnels",
    body: createPersonnel(Uuid().v4(), affiliate: await _createAffiliation(harness, Uuid().v4())),
  );
  await harness.agent.post(
    "/api/operations/$ouuid/personnels",
    body: createPersonnel(Uuid().v4(), affiliate: await _createAffiliation(harness, Uuid().v4())),
  );
  await harness.agent.post(
    "/api/operations/$ouuid/personnels",
    body: createPersonnel(Uuid().v4(), affiliate: await _createAffiliation(harness, Uuid().v4())),
  );
  await harness.agent.post(
    "/api/operations/$ouuid/personnels",
    body: createPersonnel(Uuid().v4(), affiliate: await _createAffiliation(harness, Uuid().v4())),
  );
  final response = expectResponse(
    await harness.agent.get("/api/operations/$ouuid/personnels?offset=1&limit=2${expand ? '&expand=person' : ''}"),
    200,
  );
  final actual = await response.body.decode() as Map<String, dynamic>;
  expect(actual['total'], equals(4));
  expect(actual['offset'], equals(1));
  expect(actual['limit'], equals(2));
  expect(actual['entries'].length, equals(2));
  expect(actual.elementAt('entries/0/data/person/fname'), expand ? equals('fname') : isNull);
}

Future<String> _prepare(SarSysAppHarness harness) async {
  final iuuid = Uuid().v4();
  expectResponse(await harness.agent.post("/api/incidents", body: createIncident(iuuid)), 201);
  final ouuid = Uuid().v4();
  expectResponse(await harness.agent.post("/api/incidents/$iuuid/operations", body: createOperation(ouuid)), 201);
  return ouuid;
}

Future<Map<String, dynamic>> _createAffiliation(SarSysAppHarness harness, String auuid) async {
  final puuid = Uuid().v4();
  final orguuid = Uuid().v4();
  expectResponse(
    await harness.agent.post("/api/organisations", body: createOrganisation(orguuid)),
    201,
  );
  final affiliation = createAffiliation(
    auuid,
    orguuid: orguuid,
    person: createPerson(puuid),
  );
  expectResponse(
    await harness.agent.post("/api/affiliations", body: affiliation),
    201,
  );
  return affiliation;
}
