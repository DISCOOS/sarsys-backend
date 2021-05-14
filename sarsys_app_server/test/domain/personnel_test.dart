import 'dart:ffi';

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
    // Arrange
    final puuid = Uuid().v4();
    final auuid = Uuid().v4();
    final ouuid = await _prepare(harness, auuid);
    final personnel = createPersonnel(puuid, auuid: auuid);
    final updated = personnel;

    // Act
    expectResponse(await harness.agent.post("/api/operations/$ouuid/personnels", body: personnel), 201, body: null);
    expectResponse(await harness.agent.execute("PATCH", "/api/personnels/$puuid", body: updated), 204, body: null);

    // Assert
    final response = expectResponse(await harness.agent.get("/api/personnels/$puuid"), 200);
    final actual = await response.body.decode();
    expect(
      actual['data'],
      equals(personnel
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

  test("PATCH /api/personnels/{uuid} created tracking if not exists", () async {
    final puuid = Uuid().v4();
    final auuid = Uuid().v4();
    final tuuid = Uuid().v4();
    final ouuid = await _prepare(harness, auuid);
    final existing = createPersonnel(puuid, auuid: auuid);
    expectResponse(await harness.agent.post("/api/operations/$ouuid/personnels", body: existing), 201, body: null);
    final response1 = expectResponse(
      await harness.agent.execute(
        "PATCH",
        "/api/personnels/$puuid",
        body: {
          'tracking': {'uuid': tuuid}
        },
      ),
      200,
    );
    final personnel = await response1.body.decode();
    expect(
      personnel['data'],
      equals(existing
        ..addAll({
          'tracking': {'uuid': tuuid},
          'operation': {'uuid': ouuid},
        })),
    );
    final response2 = expectResponse(await harness.agent.get("/api/trackings/$tuuid"), 200);
    final tracking = await response2.body.decode();
    expect(
      tracking['data'],
      equals({
        'uuid': tuuid,
        'tracks': [],
        'sources': [
          {'uuid': puuid, 'type': 'trackable'}
        ]
      }),
    );
  });

  test("PATCH /api/personnels/{uuid} not allowed if tracking already exist", () async {
    final puuid = Uuid().v4();
    final auuid = Uuid().v4();
    final tuuid1 = Uuid().v4();
    final tuuid2 = Uuid().v4();
    final ouuid = await _prepare(harness, auuid);
    final existing = createPersonnel(puuid, auuid: auuid, tuuid: tuuid1);
    final updated = Map.from(existing)
      ..addAll({
        'tracking': {'uuid': tuuid2},
        'operation': {'uuid': ouuid},
      });
    expectResponse(await harness.agent.post("/api/operations/$ouuid/personnels", body: existing), 201, body: null);
    final response = expectResponse(
      await harness.agent.execute("PATCH", "/api/personnels/$puuid", body: updated),
      409,
    );
    final actual = Map.from(await response.body.decode());
    expect(
      actual,
      equals({
        'mine': null,
        'yours': null,
        'base': Map.from(existing)
          ..addAll({
            'tracking': {'uuid': tuuid1},
            'operation': {'uuid': ouuid},
          }),
        'type': 'exists',
        'code': 'duplicate_tracking_uuid',
        'error': 'Personnel $puuid is already tracked by $tuuid1',
      }),
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
  final orguuid = Uuid().v4();
  final ouuid = await _prepare(harness, auuid, puuid: puuid, orguuid: orguuid);
  final person = expand ? createPerson(puuid) : <String, dynamic>{'uuid': puuid};
  final affiliation = createAffiliation(auuid, person: person, orguuid: orguuid);
  final personnel = createPersonnel(puuid, affiliate: affiliation);
  expectResponse(
    await harness.agent.post("/api/operations/$ouuid/personnels", body: personnel),
    201,
    body: null,
  );
  final response = expectResponse(
    await harness.agent.get("/api/personnels/$puuid${expand ? '?expand=person' : ''}"),
    200,
  );
  final actual = await response.body.decode();
  expect(
    actual['data'],
    equals(
      personnel
        ..addAll({
          'operation': {'uuid': ouuid},
        }),
    ),
  );
}

Future _testGetAll(SarSysAppHarness harness, {bool expand = false}) async {
  final auuid = Uuid().v4();
  final ouuid = await _prepare(harness, auuid);
  await harness.agent.post(
    "/api/operations/$ouuid/personnels",
    body: createPersonnel(
      Uuid().v4(),
      auuid: await _createAffiliation(harness, Uuid().v4(), Uuid().v4(), Uuid().v4()),
    ),
  );
  await harness.agent.post(
    "/api/operations/$ouuid/personnels",
    body: createPersonnel(
      Uuid().v4(),
      auuid: await _createAffiliation(harness, Uuid().v4(), Uuid().v4(), Uuid().v4()),
    ),
  );
  await harness.agent.post(
    "/api/operations/$ouuid/personnels",
    body: createPersonnel(
      Uuid().v4(),
      auuid: await _createAffiliation(harness, Uuid().v4(), Uuid().v4(), Uuid().v4()),
    ),
  );
  await harness.agent.post(
    "/api/operations/$ouuid/personnels",
    body: createPersonnel(
      Uuid().v4(),
      auuid: await _createAffiliation(harness, Uuid().v4(), Uuid().v4(), Uuid().v4()),
    ),
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
  expect(actual.elementAt('entries/0/data/affiliation/person/fname'), expand ? equals('fname') : isNull);
}

Future<String> _prepare(
  SarSysAppHarness harness,
  String auuid, {
  String puuid,
  String orguuid,
}) async {
  await _createAffiliation(harness, puuid ?? Uuid().v4(), auuid, orguuid ?? Uuid().v4());
  final iuuid = Uuid().v4();
  expectResponse(await harness.agent.post("/api/incidents", body: createIncident(iuuid)), 201);
  final ouuid = Uuid().v4();
  expectResponse(await harness.agent.post("/api/incidents/$iuuid/operations", body: createOperation(ouuid)), 201);
  return ouuid;
}

Future<String> _createAffiliation(SarSysAppHarness harness, String puuid, String auuid, String orguuid) async {
  expectResponse(await harness.agent.post("/api/persons", body: createPerson(puuid)), 201);
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
