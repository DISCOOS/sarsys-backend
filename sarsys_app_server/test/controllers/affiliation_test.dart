import 'package:event_source/event_source.dart';
import 'package:sarsys_domain/sarsys_domain.dart';
import 'package:uuid/uuid.dart';
import 'package:test/test.dart';
import 'package:meta/meta.dart';

import 'harness.dart';

Future main() async {
  final harness = SarSysHarness()
    ..withEventStoreMock()
    ..install(restartForEachTest: true);

  test("POST /api/affiliations/ returns status code 201 with empty body", () async {
    final auuid = Uuid().v4();
    final puuid = Uuid().v4();
    final orguuid = Uuid().v4();
    await _prepare(harness, puuid: puuid, orguuid: orguuid);
    final body = _createData(auuid, puuid: puuid, orguuid: orguuid);
    expectResponse(await harness.agent.post("/api/affiliations", body: body), 201, body: null);
  });

  test("GET /api/affiliations/{uuid} returns status code 200", () async {
    await _testGet(harness, expand: false);
  });

  test("GET /api/affiliations/{uuid} returns status code 200 with expand=person", () async {
    await _testGet(harness, expand: true);
  });

  test("GET /api/affiliations returns status code 200 with offset=1&limit=2", () async {
    await _testGetAll(harness, expand: false);
  });

  test("GET /api/affiliations returns status code 200 with offset=1&limit=2&expand=person", () async {
    await _testGetAll(harness, expand: true);
  });

  test("GET /api/affiliations returns status code 200 with offset=1&limit=2&filter=fname", () async {
    await _testGetAll(harness, filter: true);
  });

  test("GET /api/affiliations returns status code 200 with offset=1&limit=2&expand=person&filter=fname", () async {
    await _testGetAll(harness, expand: true, filter: true);
  });

  test("PATCH /api/affiliations/{uuid} is idempotent", () async {
    final auuid = Uuid().v4();
    final puuid = Uuid().v4();
    final orguuid = Uuid().v4();
    await _prepare(harness, puuid: puuid, orguuid: orguuid);
    final body = _createData(auuid, puuid: puuid, orguuid: orguuid);
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
    final body = _createData(auuid, puuid: puuid, orguuid: orguuid);
    expectResponse(await harness.agent.post("/api/affiliations", body: body), 201, body: null);
    expectResponse(await harness.agent.execute("PATCH", "/api/affiliations/$auuid", body: {}), 204, body: null);
    final response = expectResponse(await harness.agent.get("/api/affiliations/$auuid"), 200);
    final actual = await response.body.decode();
    expect(actual['data'], equals(body));
  });

  test("DELETE /api/affiliations/{uuid} returns status code 204", () async {
    final auuid = Uuid().v4();
    final puuid = Uuid().v4();
    final orguuid = Uuid().v4();
    await _prepare(harness, puuid: puuid, orguuid: orguuid);
    final body = _createData(auuid, puuid: puuid, orguuid: orguuid);
    expectResponse(await harness.agent.post("/api/affiliations", body: body), 201, body: null);
    expectResponse(await harness.agent.delete("/api/affiliations/$auuid"), 204);
  });

  test("DELETE person returns status code 204 after affiliations are deleted", () async {
    final puuid = Uuid().v4();
    final orguuid = Uuid().v4();
    await _prepare(harness, puuid: puuid, orguuid: orguuid);
    final a1 = _createData(Uuid().v4(), puuid: puuid, orguuid: orguuid);
    final a2 = _createData(Uuid().v4(), puuid: puuid, orguuid: orguuid);
    final a3 = _createData(Uuid().v4(), puuid: puuid, orguuid: orguuid);
    final a4 = _createData(Uuid().v4(), puuid: puuid, orguuid: orguuid);
    await harness.agent.post("/api/affiliations", body: a1);
    await harness.agent.post("/api/affiliations", body: a2);
    await harness.agent.post("/api/affiliations", body: a3);
    await harness.agent.post("/api/affiliations", body: a4);
    expectResponse(await harness.agent.delete("/api/persons/$puuid"), 204);
    expectResponse(await harness.agent.get("/api/affiliations/${a1.elementAt('uuid')}"), 404);
    expectResponse(await harness.agent.get("/api/affiliations/${a2.elementAt('uuid')}"), 404);
    expectResponse(await harness.agent.get("/api/affiliations/${a3.elementAt('uuid')}"), 404);
    expectResponse(await harness.agent.get("/api/affiliations/${a4.elementAt('uuid')}"), 404);
  });

  test("DELETE division returns status code 204 after affiliations are deleted", () async {
    final puuid = Uuid().v4();
    final orguuid = Uuid().v4();
    final divuuid = Uuid().v4();
    await _prepare(harness, puuid: puuid, orguuid: orguuid, divuuid: divuuid);
    final a1 = _createData(Uuid().v4(), puuid: puuid, orguuid: orguuid, divuuid: divuuid);
    final a2 = _createData(Uuid().v4(), puuid: puuid, orguuid: orguuid, divuuid: divuuid);
    final a3 = _createData(Uuid().v4(), puuid: puuid, orguuid: orguuid, divuuid: divuuid);
    final a4 = _createData(Uuid().v4(), puuid: puuid, orguuid: orguuid, divuuid: divuuid);
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

  test("DELETE department returns status code 204 after affiliations are deleted", () async {
    final puuid = Uuid().v4();
    final orguuid = Uuid().v4();
    final divuuid = Uuid().v4();
    final depuuid = Uuid().v4();
    await _prepare(harness, puuid: puuid, orguuid: orguuid, divuuid: divuuid, depuuid: depuuid);
    final a1 = _createData(Uuid().v4(), puuid: puuid, orguuid: orguuid, divuuid: divuuid, depuuid: depuuid);
    final a2 = _createData(Uuid().v4(), puuid: puuid, orguuid: orguuid, divuuid: divuuid, depuuid: depuuid);
    final a3 = _createData(Uuid().v4(), puuid: puuid, orguuid: orguuid, divuuid: divuuid, depuuid: depuuid);
    final a4 = _createData(Uuid().v4(), puuid: puuid, orguuid: orguuid, divuuid: divuuid, depuuid: depuuid);
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

Future _testGet(SarSysHarness harness, {bool expand = false}) async {
  final auuid = Uuid().v4();
  final puuid = Uuid().v4();
  final orguuid = Uuid().v4();
  await _prepare(harness, puuid: puuid, orguuid: orguuid);
  final body = _createData(auuid, puuid: puuid, orguuid: orguuid);
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
  SarSysHarness harness, {
  bool expand = false,
  bool filter = false,
}) async {
  final puuid = Uuid().v4();
  final orguuid = Uuid().v4();
  await _prepare(harness, puuid: puuid, orguuid: orguuid);
  await harness.agent.post(
    "/api/affiliations",
    body: _createData(Uuid().v4(), puuid: puuid, orguuid: orguuid),
  );
  await harness.agent.post("/api/affiliations", body: _createData(Uuid().v4(), puuid: puuid, orguuid: orguuid));
  await harness.agent.post("/api/affiliations", body: _createData(Uuid().v4(), puuid: puuid, orguuid: orguuid));
  await harness.agent.post("/api/affiliations", body: _createData(Uuid().v4(), puuid: puuid, orguuid: orguuid));
  final query = <String>[
    if (filter) 'filter=fname',
    if (expand) 'expand=person',
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

Future _prepare(
  SarSysHarness harness, {
  String puuid,
  String orguuid,
  String divuuid,
  String depuuid,
}) async {
  harness.eventStoreMockServer.withStream(typeOf<Person>().toColonCase());
  harness.eventStoreMockServer.withStream(typeOf<Affiliation>().toColonCase());
  if (orguuid != null) {
    harness.eventStoreMockServer.withStream(typeOf<Organisation>().toColonCase());
  }
  if (divuuid != null) {
    harness.eventStoreMockServer.withStream(typeOf<Division>().toColonCase());
  }
  if (depuuid != null) {
    harness.eventStoreMockServer.withStream(typeOf<Department>().toColonCase());
  }
  await harness.channel.manager.get<PersonRepository>().readyAsync();
  await harness.channel.manager.get<AffiliationRepository>().readyAsync();
  if (orguuid != null) {
    await harness.channel.manager.get<OrganisationRepository>().readyAsync();
    expectResponse(
      await harness.agent.post("/api/organisations", body: createOrganisation(orguuid)),
      201,
    );
  }
  if (divuuid != null) {
    await harness.channel.manager.get<DivisionRepository>().readyAsync();
    expectResponse(
      await harness.agent.post("/api/organisations/$orguuid/divisions", body: createDivision(divuuid)),
      201,
    );
  }
  if (depuuid != null) {
    await harness.channel.manager.get<OrganisationRepository>().readyAsync();
    expectResponse(
      await harness.agent.post("/api/divisions/$divuuid/departments", body: createDepartment(depuuid)),
      201,
    );
  }
  expectResponse(await harness.agent.post("/api/persons", body: createPerson(puuid ?? Uuid().v4())), 201);
}

Map<String, Object> _createData(
  String uuid, {
  @required String puuid,
  @required String orguuid,
  String divuuid,
  String depuuid,
}) =>
    createAffiliation(
      uuid,
      puuid: puuid,
      orguuid: orguuid,
      divuuid: divuuid,
      depuuid: depuuid,
    );
