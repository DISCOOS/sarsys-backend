import 'package:sarsys_domain/sarsys_domain.dart' hide Operation;
import 'package:uuid/uuid.dart';
import 'package:test/test.dart';
import 'package:collection_x/collection_x.dart';

import 'package:sarsys_app_server_test/sarsys_app_server_test.dart';

Future main() async {
  final harness = SarSysAppHarness()
    ..withEventStoreMock()
    ..install(restartForEachTest: true);

  test("POST /api/personnels not allowed", () async {
    await _prepare(harness, Uuid().v4());
    final uuid = Uuid().v4();
    final body = createPersonnel(uuid);
    expectResponse(
      await harness.agent.post("/api/personnels/$uuid", body: body),
      405,
    );
  });

  test("POST /api/operations/{uuid}/personnels/ returns status code 201 with empty body", () async {
    final puuid = Uuid().v4();
    final auuid = Uuid().v4();
    final ouuid = await _prepare(harness, auuid);
    final body = createPersonnel(puuid, auuid: auuid);
    expectResponse(await harness.agent.post("/api/operations/$ouuid/personnels", body: body), 201, body: null);
  });

  test("POST /api/operations/{uuid}/personnels/ returns status code 201 with tracking enabled", () async {
    final puuid = Uuid().v4();
    final auuid = Uuid().v4();
    final tuuid = Uuid().v4();
    final ouuid = await _prepare(harness, auuid);
    final body = createPersonnel(puuid, auuid: auuid, tuuid: tuuid);
    expectResponse(await harness.agent.post("/api/operations/$ouuid/personnels", body: body), 201, body: null);
  });

  test("POST /api/operations/{uuid}/personnels/ returns status code 400 when 'incident/uuid' is given", () async {
    final puuid = Uuid().v4();
    final auuid = Uuid().v4();
    final ouuid = await _prepare(harness, auuid);
    final body = createPersonnel(puuid, auuid: auuid)
      ..addAll({
        'operation': {'uuid': 'string'}
      });
    expectResponse(
      await harness.agent.post("/api/operations/$ouuid/personnels", body: body),
      400,
      body: 'Schema Personnel has 1 errors: [/operation: is read only]',
    );
  });

  test("GET /api/personnels/{uuid} returns status code 200", () async {
    await _testGet(harness, expand: false);
  });

  test("GET /api/personnels/{uuid} returns status code 200 with expand=person", () async {
    await _testGet(harness, expand: true);
  });

  test("GET /api/personnels returns status code 200 with offset=1&limit=2", () async {
    await _testGetAll(harness, expand: false);
  });

  test("GET /api/personnels returns status code 200 with offset=1&limit=2&expand=person", () async {
    await _testGetAll(harness, expand: true);
  });

  test("PATCH /api/personnels/{uuid} is idempotent", () async {
    final puuid = Uuid().v4();
    final auuid = Uuid().v4();
    final ouuid = await _prepare(harness, auuid);
    final body = createPersonnel(puuid, auuid: auuid);
    expectResponse(await harness.agent.post("/api/operations/$ouuid/personnels", body: body), 201, body: null);
    expectResponse(await harness.agent.execute("PATCH", "/api/personnels/$puuid", body: body), 204, body: null);
    final response = expectResponse(await harness.agent.get("/api/personnels/$puuid"), 200);
    final actual = await response.body.decode();
    expect(
      actual['data'],
      equals(body
        ..addAll({
          'operation': {'uuid': ouuid}
        })),
    );
  });

  test("PATCH /api/personnels/{uuid} does not remove value objects", () async {
    final puuid = Uuid().v4();
    final auuid = Uuid().v4();
    final ouuid = await _prepare(harness, auuid);
    final body = createPersonnel(puuid, auuid: auuid);
    expectResponse(await harness.agent.post("/api/operations/$ouuid/personnels", body: body), 201, body: null);
    expectResponse(await harness.agent.execute("PATCH", "/api/personnels/$puuid", body: {}), 204, body: null);
    final response = expectResponse(await harness.agent.get("/api/personnels/$puuid"), 200);
    final actual = await response.body.decode();
    expect(
      actual['data'],
      equals(body
        ..addAll({
          'operation': {'uuid': ouuid}
        })),
    );
  });

  test("DELETE /api/personnels/{uuid} returns status code 204", () async {
    final puuid = Uuid().v4();
    final auuid = Uuid().v4();
    final ouuid = await _prepare(harness, auuid);
    final body = createPersonnel(puuid, auuid: auuid);
    expectResponse(await harness.agent.post("/api/operations/$ouuid/personnels", body: body), 201, body: null);
    expectResponse(await harness.agent.delete("/api/personnels/$puuid"), 204);
  });

  test("DELETE /api/personnels/{uuid} returns status code 204 when assigned to unit", () async {
    final uuuid = Uuid().v4();
    final puuid = Uuid().v4();
    final auuid = Uuid().v4();
    final ouuid = await _prepare(harness, auuid);
    await harness.channel.manager.get<UnitRepository>().readyAsync();
    final unit = createUnit(uuuid);
    expectResponse(await harness.agent.post("/api/operations/$ouuid/units", body: unit), 201, body: null);
    final personnel = createPersonnel(puuid, auuid: auuid);
    expectResponse(await harness.agent.post("/api/operations/$ouuid/personnels", body: personnel), 201, body: null);
    expectResponse(
      await harness.agent.execute('patch', "/api/units/$uuuid/personnels", body: {
        'personnels': [puuid]
      }),
      204,
      body: null,
    );
    expectResponse(await harness.agent.delete("/api/personnels/$puuid"), 204);
  });

  test("DELETE /api/units/{uuid} returns status code 204 with tracking enabled", () async {
    final puuid = Uuid().v4();
    final auuid = Uuid().v4();
    final tuuid = Uuid().v4();
    final ouuid = await _prepare(harness, auuid);
    final body = createPersonnel(puuid, auuid: auuid, tuuid: tuuid);
    expectResponse(await harness.agent.post("/api/operations/$ouuid/personnels", body: body), 201, body: null);
    expectResponse(await harness.agent.delete("/api/personnels/$puuid"), 204);
  });
}

Future _testGet(SarSysAppHarness harness, {bool expand = false}) async {
  final puuid = Uuid().v4();
  final auuid = Uuid().v4();
  final ouuid = await _prepare(harness, auuid, puuid: puuid);
  final body = createPersonnel(puuid, auuid: auuid);
  expectResponse(
    await harness.agent.post("/api/operations/$ouuid/personnels", body: body),
    201,
    body: null,
  );
  final response = expectResponse(
    await harness.agent.get("/api/personnels/$puuid${expand ? '?expand=person' : ''}"),
    200,
  );
  final actual = await response.body.decode();
  final person = expand ? createPerson(puuid) : <String, dynamic>{};
  expect(
    actual['data'],
    equals(
      body
        ..addAll({
          'operation': {'uuid': ouuid},
        })
        ..addAll({if (expand) 'person': person}),
    ),
  );
}

Future _testGetAll(SarSysAppHarness harness, {bool expand = false}) async {
  final auuid = Uuid().v4();
  final ouuid = await _prepare(harness, auuid);
  await harness.agent.post(
    "/api/operations/$ouuid/personnels",
    body: createPersonnel(Uuid().v4(), auuid: await _createAffiliation(harness, Uuid().v4(), Uuid().v4())),
  );
  await harness.agent.post(
    "/api/operations/$ouuid/personnels",
    body: createPersonnel(Uuid().v4(), auuid: await _createAffiliation(harness, Uuid().v4(), Uuid().v4())),
  );
  await harness.agent.post(
    "/api/operations/$ouuid/personnels",
    body: createPersonnel(Uuid().v4(), auuid: await _createAffiliation(harness, Uuid().v4(), Uuid().v4())),
  );
  await harness.agent.post(
    "/api/operations/$ouuid/personnels",
    body: createPersonnel(Uuid().v4(), auuid: await _createAffiliation(harness, Uuid().v4(), Uuid().v4())),
  );
  final response = expectResponse(
    await harness.agent.get("/api/personnels?offset=1&limit=2${expand ? '&expand=person' : ''}"),
    200,
  );
  final actual = await response.body.decode() as Map<String, dynamic>;
  expect(actual['total'], equals(4));
  expect(actual['offset'], equals(1));
  expect(actual['limit'], equals(2));
  expect(actual['entries'].length, equals(2));
  expect(actual.elementAt('entries/0/data/person/fname'), expand ? equals('fname') : isNull);
}

Future<String> _prepare(
  SarSysAppHarness harness,
  String auuid, {
  String puuid,
}) async {
  await _createAffiliation(harness, puuid ?? Uuid().v4(), auuid);
  final iuuid = Uuid().v4();
  expectResponse(await harness.agent.post("/api/incidents", body: createIncident(iuuid)), 201);
  final ouuid = Uuid().v4();
  expectResponse(await harness.agent.post("/api/incidents/$iuuid/operations", body: createOperation(ouuid)), 201);
  return ouuid;
}

Future<String> _createAffiliation(SarSysAppHarness harness, String puuid, String auuid) async {
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
