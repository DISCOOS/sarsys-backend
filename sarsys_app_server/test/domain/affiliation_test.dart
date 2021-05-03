import 'package:uuid/uuid.dart';
import 'package:test/test.dart';
import 'package:meta/meta.dart';
import 'package:collection_x/collection_x.dart';

import 'package:sarsys_app_server_test/sarsys_app_server_test.dart';

Future main() async {
  final harness = SarSysAppHarness()
    ..withEventStoreMock()
    ..install(restartForEachTest: true);

  test("POST /api/affiliations returns 201 with empty body", () async {
    final auuid = Uuid().v4();
    final puuid = Uuid().v4();
    final orguuid = Uuid().v4();
    await _prepare(harness, puuid: puuid, orguuid: orguuid);
    final body = createAffiliation(auuid, puuid: puuid, orguuid: orguuid);
    expectResponse(await harness.agent.post("/api/affiliations", body: body), 201, body: null);
  });

  test("POST /api/affiliations creates permanent person", () async {
    final auuid = Uuid().v4();
    final puuid = Uuid().v4();
    final orguuid = Uuid().v4();
    await _prepare(harness, puuid: puuid, orguuid: orguuid);
    final person = createPerson(puuid);
    final affiliation = createAffiliation(auuid, puuid: puuid, orguuid: orguuid);
    final affiliate = Map.from(affiliation);
    affiliate['person'] = person;

    // Act
    expectResponse(await harness.agent.post("/api/affiliations", body: affiliate), 201, body: null);

    // Assert
    final response1 = expectResponse(await harness.agent.get("/api/persons/$puuid"), 200);
    final actualPerson = await response1.body.decode();
    expect(actualPerson['data'], person);
    final response2 = expectResponse(await harness.agent.get("/api/affiliations/$auuid"), 200);
    final actualAffiliation = await response2.body.decode();
    expect(actualAffiliation['data'], affiliation);
  });

  test("POST /api/affiliations creates temporary person", () async {
    final auuid = Uuid().v4();
    final puuid = Uuid().v4();
    final orguuid = Uuid().v4();
    await _prepare(harness, orguuid: orguuid);
    final person = createPerson(puuid, temporary: true);
    final affiliation = createAffiliation(auuid, puuid: puuid, orguuid: orguuid);
    final affiliate = Map.from(affiliation);
    affiliate['person'] = person;

    // Act
    expectResponse(
      await harness.agent.post("/api/affiliations", body: affiliate),
      201,
      body: null,
    );

    // Assert
    final response1 = expectResponse(await harness.agent.get("/api/persons/$puuid"), 200);
    final actualPerson = await response1.body.decode();
    expect(actualPerson['data'], person);
    final response2 = expectResponse(await harness.agent.get("/api/affiliations/$auuid"), 200);
    final actualAffiliation = await response2.body.decode();
    expect(actualAffiliation['data'], affiliation);
  });

  test("POST /api/affiliations returns status code 201 when same person exists", () async {
    final auuid = Uuid().v4();
    final puuid = Uuid().v4();
    final orguuid = Uuid().v4();
    await _prepare(harness, orguuid: orguuid);
    final person = createPerson(puuid);
    final affiliation = createAffiliation(auuid, puuid: puuid, orguuid: orguuid);
    final affiliate = Map.from(affiliation);
    affiliate['person'] = person;

    // Act
    expectResponse(await harness.agent.post("/api/persons", body: person), 201);

    // Assert
    expectResponse(
      await harness.agent.post("/api/affiliations", body: affiliate),
      201,
      body: null,
    );
  });

  test("POST /api/affiliations returns status code 201 when person is updated", () async {
    final auuid = Uuid().v4();
    final puuid = Uuid().v4();
    final orguuid = Uuid().v4();
    await _prepare(harness, orguuid: orguuid);
    final person = createPerson(puuid);
    final updated = Map.from(person)..addAll({'fname': 'updated'});
    final affiliation = createAffiliation(auuid, puuid: puuid, orguuid: orguuid);
    final affiliate = Map.from(affiliation);
    affiliate['person'] = updated;

    // Act
    expectResponse(await harness.agent.post("/api/persons", body: person), 201);

    // Assert
    expectResponse(
      await harness.agent.post("/api/affiliations", body: affiliate),
      201,
      body: null,
    );
    final response1 = expectResponse(await harness.agent.get("/api/persons/$puuid"), 200);
    final actualPerson = await response1.body.decode();
    expect(actualPerson['data'], updated);
  });

  test("POST /api/affiliations returns status code 409 when same user exists", () async {
    const userid = 'user1';

    final auuid = Uuid().v4();
    final puuid1 = Uuid().v4();
    final puuid2 = Uuid().v4();
    final orguuid = Uuid().v4();
    final user1 = createPerson(puuid1, userId: userid);
    final duplicate = createPerson(puuid2, userId: userid);
    await _prepare(harness, orguuid: orguuid);
    final affiliation = createAffiliation(auuid, puuid: puuid1, orguuid: orguuid);
    final affiliate = Map.from(affiliation);
    affiliate['person'] = duplicate;

    // Act
    expectResponse(await harness.agent.post("/api/persons", body: user1), 201);

    // Assert
    final response = expectResponse(
      await harness.agent.post("/api/affiliations", body: affiliate),
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
      isNull,
    );
    expect(
      conflict.listAt<Map<String, dynamic>>('mine'),
      [user1],
    );
    expect(
      conflict.listAt<Map<String, dynamic>>('yours'),
      [affiliate],
    );
  });

  test("POST /api/affiliations returns status code 409 when unorganized affiliate exists", () async {
    // Arrange
    final puuid = Uuid().v4();
    await _prepare(harness, puuid: puuid) as Map<String, dynamic>;
    final unorganized = createAffiliation(Uuid().v4(), puuid: puuid);
    final duplicate = createAffiliation(Uuid().v4(), puuid: puuid);

    // Act
    expectResponse(await harness.agent.post("/api/affiliations", body: unorganized), 201);

    // Assert
    final response = expectResponse(
      await harness.agent.post("/api/affiliations", body: duplicate),
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

  test("POST /api/affiliations returns status code 409 when organized affiliate exists", () async {
    // Arrange
    final puuid = Uuid().v4();
    final ouuid = Uuid().v4();
    await _prepare(harness, puuid: puuid);
    final organized = createAffiliation(Uuid().v4(), puuid: puuid, orguuid: ouuid);
    final duplicate = createAffiliation(Uuid().v4(), puuid: puuid, orguuid: ouuid);

    // Act
    expectResponse(await harness.agent.post("/api/affiliations", body: organized), 201);

    // Assert
    final response = expectResponse(
      await harness.agent.post("/api/affiliations", body: duplicate),
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

  test("GET /api/affiliations/{uuid} returns 200", () async {
    await _testGet(harness, expand: false);
  });

  test("GET /api/affiliations/{uuid} returns 200 with expand=person", () async {
    await _testGet(harness, expand: true);
  });

  test("GET /api/affiliations returns 200 with offset=1&limit=2", () async {
    await _testGetAll(harness, expand: false);
  });

  test("GET /api/affiliations returns 200 with offset=1&limit=2&expand=person", () async {
    await _testGetAll(harness, expand: true);
  });

  test("GET /api/affiliations returns 200 with offset=1&limit=2&filter=fname", () async {
    await _testGetAll(harness, filter: true);
  });

  test("GET /api/affiliations returns 200 with offset=1&limit=2&expand=person&filter=fname", () async {
    await _testGetAll(harness, expand: true, filter: true);
  });

  test("GET /api/affiliations returns 200 with offset=1&limit=2&uuids=auuid1,auuid2,auuid3,auuid4", () async {
    await _testGetAll(harness, expand: false, filter: false, uuids: true);
  });

  test("PATCH /api/affiliations/{uuid} is idempotent", () async {
    final auuid = Uuid().v4();
    final puuid = Uuid().v4();
    final orguuid = Uuid().v4();
    await _prepare(harness, puuid: puuid, orguuid: orguuid);
    final body = createAffiliation(auuid, puuid: puuid, orguuid: orguuid);
    expectResponse(await harness.agent.post("/api/affiliations", body: body), 201, body: null);
    expectResponse(await harness.agent.execute("PATCH", "/api/affiliations/$auuid", body: body), 204, body: null);
    final response = expectResponse(await harness.agent.get("/api/affiliations/$auuid"), 200);
    final actual = await response.body.decode();
    expect(actual['data'], equals(body));
  });

  test("PATCH /api/affiliations/{uuid} does not remove value objects", () async {
    final auuid = Uuid().v4();
    final puuid = Uuid().v4();
    final orguuid = Uuid().v4();
    await _prepare(harness, puuid: puuid, orguuid: orguuid);
    final body = createAffiliation(auuid, puuid: puuid, orguuid: orguuid);
    expectResponse(await harness.agent.post("/api/affiliations", body: body), 201, body: null);
    expectResponse(await harness.agent.execute("PATCH", "/api/affiliations/$auuid", body: {}), 204, body: null);
    final response = expectResponse(await harness.agent.get("/api/affiliations/$auuid"), 200);
    final actual = await response.body.decode();
    expect(actual['data'], equals(body));
  });

  test("DELETE /api/affiliations/{uuid} returns 204", () async {
    final auuid = Uuid().v4();
    final puuid = Uuid().v4();
    final orguuid = Uuid().v4();
    await _prepare(harness, puuid: puuid, orguuid: orguuid);
    final body = createAffiliation(auuid, puuid: puuid, orguuid: orguuid);
    expectResponse(await harness.agent.post("/api/affiliations", body: body), 201, body: null);
    expectResponse(await harness.agent.delete("/api/affiliations/$auuid"), 204);
  });

  test("DELETE person returns 204 after affiliations are deleted", () async {
    final puuid1 = Uuid().v4();
    final puuid2 = Uuid().v4();
    final puuid3 = Uuid().v4();
    final puuid4 = Uuid().v4();
    final orguuid = Uuid().v4();
    await _prepare(harness, orguuid: orguuid);
    final a1 = createAffiliation(Uuid().v4(), puuid: puuid1, orguuid: orguuid);
    final a2 = createAffiliation(Uuid().v4(), puuid: puuid2, orguuid: orguuid);
    final a3 = createAffiliation(Uuid().v4(), puuid: puuid3, orguuid: orguuid);
    final a4 = createAffiliation(Uuid().v4(), puuid: puuid4, orguuid: orguuid);
    await harness.agent.post("/api/affiliations", body: a1);
    await harness.agent.post("/api/affiliations", body: a2);
    await harness.agent.post("/api/affiliations", body: a3);
    await harness.agent.post("/api/affiliations", body: a4);
    expectResponse(await harness.agent.delete("/api/persons/$puuid1"), 204);
    expectResponse(await harness.agent.delete("/api/persons/$puuid2"), 204);
    expectResponse(await harness.agent.delete("/api/persons/$puuid3"), 204);
    expectResponse(await harness.agent.delete("/api/persons/$puuid4"), 204);
    expectResponse(await harness.agent.get("/api/affiliations/${a1.elementAt('uuid')}"), 404);
    expectResponse(await harness.agent.get("/api/affiliations/${a2.elementAt('uuid')}"), 404);
    expectResponse(await harness.agent.get("/api/affiliations/${a3.elementAt('uuid')}"), 404);
    expectResponse(await harness.agent.get("/api/affiliations/${a4.elementAt('uuid')}"), 404);
  });

  test("DELETE division returns 204 after affiliations are deleted", () async {
    final orguuid = Uuid().v4();
    final divuuid = Uuid().v4();
    await _prepare(harness, orguuid: orguuid, divuuid: divuuid);
    final a1 = createAffiliation(Uuid().v4(), puuid: Uuid().v4(), orguuid: orguuid, divuuid: divuuid);
    final a2 = createAffiliation(Uuid().v4(), puuid: Uuid().v4(), orguuid: orguuid, divuuid: divuuid);
    final a3 = createAffiliation(Uuid().v4(), puuid: Uuid().v4(), orguuid: orguuid, divuuid: divuuid);
    final a4 = createAffiliation(Uuid().v4(), puuid: Uuid().v4(), orguuid: orguuid, divuuid: divuuid);
    await harness.agent.post("/api/affiliations", body: a1);
    await harness.agent.post("/api/affiliations", body: a2);
    await harness.agent.post("/api/affiliations", body: a3);
    await harness.agent.post("/api/affiliations", body: a4);
    expectResponse(await harness.agent.delete("/api/divisions/$divuuid"), 204);
    expectResponse(await harness.agent.get("/api/affiliations/${a1.elementAt('uuid')}"), 404);
    expectResponse(await harness.agent.get("/api/affiliations/${a2.elementAt('uuid')}"), 404);
    expectResponse(await harness.agent.get("/api/affiliations/${a3.elementAt('uuid')}"), 404);
    expectResponse(await harness.agent.get("/api/affiliations/${a4.elementAt('uuid')}"), 404);
  });

  test("DELETE department returns 204 after affiliations are deleted", () async {
    final orguuid = Uuid().v4();
    final divuuid = Uuid().v4();
    final depuuid = Uuid().v4();
    await _prepare(harness, orguuid: orguuid, divuuid: divuuid, depuuid: depuuid);
    final a1 = createAffiliation(Uuid().v4(), puuid: Uuid().v4(), orguuid: orguuid, divuuid: divuuid, depuuid: depuuid);
    final a2 = createAffiliation(Uuid().v4(), puuid: Uuid().v4(), orguuid: orguuid, divuuid: divuuid, depuuid: depuuid);
    final a3 = createAffiliation(Uuid().v4(), puuid: Uuid().v4(), orguuid: orguuid, divuuid: divuuid, depuuid: depuuid);
    final a4 = createAffiliation(Uuid().v4(), puuid: Uuid().v4(), orguuid: orguuid, divuuid: divuuid, depuuid: depuuid);
    await harness.agent.post("/api/affiliations", body: a1);
    await harness.agent.post("/api/affiliations", body: a2);
    await harness.agent.post("/api/affiliations", body: a3);
    await harness.agent.post("/api/affiliations", body: a4);
    expectResponse(await harness.agent.delete("/api/departments/$depuuid"), 204);
    expectResponse(await harness.agent.get("/api/affiliations/${a1.elementAt('uuid')}"), 404);
    expectResponse(await harness.agent.get("/api/affiliations/${a2.elementAt('uuid')}"), 404);
    expectResponse(await harness.agent.get("/api/affiliations/${a3.elementAt('uuid')}"), 404);
    expectResponse(await harness.agent.get("/api/affiliations/${a4.elementAt('uuid')}"), 404);
  });
}

Future _testGet(SarSysAppHarness harness, {bool expand = false}) async {
  final auuid = Uuid().v4();
  final puuid = Uuid().v4();
  final orguuid = Uuid().v4();
  await _prepare(harness, puuid: puuid, orguuid: orguuid);
  final body = createAffiliation(auuid, puuid: puuid, orguuid: orguuid);
  expectResponse(await harness.agent.post("/api/affiliations", body: body), 201, body: null);
  final response = expectResponse(
    await harness.agent.get("/api/affiliations/$auuid${expand ? '?expand=person' : ''}"),
    200,
  );
  final actual = await response.body.decode() as Map<String, dynamic>;
  final person = expand ? createPerson(puuid) : <String, dynamic>{};
  expect(
    actual['data'],
    equals(
      body..addAll({if (expand) 'person': person}),
    ),
  );
  expect(actual.elementAt('data/person/fname'), expand ? equals('fname') : isNull);
}

Future _testGetAll(
  SarSysAppHarness harness, {
  bool expand = false,
  bool filter = false,
  bool uuids = false,
}) async {
  final orguuid = Uuid().v4();
  await _prepare(harness, orguuid: orguuid);
  final auuid1 = Uuid().v4();
  final auuid2 = Uuid().v4();
  final auuid3 = Uuid().v4();
  final auuid4 = Uuid().v4();
  expectResponse(
    await harness.agent.post(
      "/api/affiliations",
      body: createAffiliation(auuid1, person: createPerson(Uuid().v4()), orguuid: orguuid),
    ),
    201,
  );
  expectResponse(
    await harness.agent.post(
      "/api/affiliations",
      body: createAffiliation(auuid2, person: createPerson(Uuid().v4()), orguuid: orguuid),
    ),
    201,
  );
  expectResponse(
    await harness.agent.post(
      "/api/affiliations",
      body: createAffiliation(auuid3, person: createPerson(Uuid().v4()), orguuid: orguuid),
    ),
    201,
  );
  expectResponse(
    await harness.agent.post(
      "/api/affiliations",
      body: createAffiliation(auuid4, person: createPerson(Uuid().v4()), orguuid: orguuid),
    ),
    201,
  );
  final query = <String>[
    if (filter) 'filter=fname',
    if (expand) 'expand=person',
    if (uuids) 'uuids=$auuid1,$auuid2,$auuid3,$auuid4',
  ];
  final response = expectResponse(
    await harness.agent.get("/api/affiliations?offset=1&limit=2&${query.join('&')}"),
    200,
  );
  final actual = await response.body.decode() as Map<String, dynamic>;
  expect(actual['total'], equals(4));
  expect(actual['offset'], equals(1));
  expect(actual['limit'], equals(2));
  expect(actual['entries'].length, equals(2));
  expect(actual.elementAt('entries/0/data/person/fname'), expand ? equals('fname') : isNull);
}

Future<dynamic> _prepare(
  SarSysAppHarness harness, {
  String puuid,
  String orguuid,
  String divuuid,
  String depuuid,
}) async {
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
  if (puuid != null) {
    final person = createPerson(puuid ?? Uuid().v4());
    expectResponse(
      await harness.agent.post("/api/persons", body: person),
      201,
    );
    return person;
  }
}
