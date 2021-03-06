import 'package:uuid/uuid.dart';
import 'package:test/test.dart';

import 'package:sarsys_app_server_test/sarsys_app_server_test.dart';

Future main() async {
  final harness = SarSysAppHarness()
    ..withEventStoreMock()
    ..install(restartForEachTest: true);

  test("POST /api/units/{uuid}/personnels not allowed", () async {
    final auuid = Uuid().v4();
    final puuid = Uuid().v4();
    final ouuid = Uuid().v4();
    final uuuid = await _prepare(harness, auuid, ouuid);
    expectResponse(
      await harness.agent.post("/api/units/$uuuid/personnels", body: createPersonnel(puuid)),
      405,
    );
  });

  test("PATCH /api/units/{uuid}/personnels adds personnel to aggregate list", () async {
    final auuid = Uuid().v4();
    final ouuid = Uuid().v4();
    final uuuid = await _prepare(harness, auuid, ouuid);
    final puuid = await _createPersonnel(harness, ouuid, auuid);
    expectResponse(
      await harness.agent.execute('PATCH', "/api/units/$uuuid/personnels", body: {
        'personnels': [puuid]
      }),
      204,
    );
    await expectAggregateReference(
      harness,
      uri: '/api/personnels',
      childUuid: puuid,
      child: createPersonnel(
        puuid,
        auuid: auuid,
        ouuid: ouuid,
        uuuid: uuuid,
      ),
      parentField: 'unit',
      parentUuid: uuuid,
    );
    await expectAggregateInList(
      harness,
      uri: '/api/units',
      uuid: uuuid,
      listField: 'personnels',
      uuids: [puuid],
    );
  });

  test("GET /api/unit/{uuid}/personnels returns status code 200 with offset=1 and limit=2", () async {
    final auuid = Uuid().v4();
    final ouuid = Uuid().v4();
    final uuuid = await _prepare(harness, auuid, ouuid);
    final puuid1 = await _createPersonnel(harness, ouuid, auuid);
    final puuid2 = await _createPersonnel(harness, ouuid, await _createAffiliation(harness, Uuid().v4()));
    final puuid3 = await _createPersonnel(harness, ouuid, await _createAffiliation(harness, Uuid().v4()));
    final puuid4 = await _createPersonnel(harness, ouuid, await _createAffiliation(harness, Uuid().v4()));
    expectResponse(
      await harness.agent.execute("PATCH", "/api/units/$uuuid/personnels", body: {
        "personnels": [
          puuid1,
          puuid2,
          puuid3,
          puuid4,
        ]
      }),
      204,
    );
    final response = expectResponse(
      await harness.agent.get("/api/units/$uuuid/personnels?offset=1&limit=2"),
      200,
    );
    final actual = await response.body.decode();
    expect(actual['total'], equals(4));
    expect(actual['offset'], equals(1));
    expect(actual['limit'], equals(2));
    expect(actual['entries'].length, equals(2));
  });

  test("DELETE /api/units/{uuid}/personnels should remove from personnels from list in unit", () async {
    final auuid = Uuid().v4();
    final ouuid = Uuid().v4();
    final uuuid = await _prepare(harness, auuid, ouuid);
    final puuid = await _createPersonnel(harness, ouuid, auuid);
    expectResponse(
      await harness.agent.execute('PATCH', "/api/units/$uuuid/personnels", body: {
        'personnels': [puuid]
      }),
      204,
    );
    expectResponse(
        await harness.agent.delete("/api/units/$uuuid/personnels", body: {
          'personnels': [puuid]
        }),
        204);
    await expectAggregateInList(
      harness,
      uri: '/api/units',
      uuid: uuuid,
      listField: 'personnels',
      uuids: [],
    );
  });

  test("DELETE /api/personnels/{uuid} should remove {uuid} from personnels list in unit", () async {
    final auuid = Uuid().v4();
    final ouuid = Uuid().v4();
    final uuuid = await _prepare(harness, auuid, ouuid);
    final puuid = await _createPersonnel(harness, ouuid, auuid);
    expectResponse(
      await harness.agent.execute('PATCH', "/api/units/$uuuid/personnels", body: {
        'personnels': [puuid]
      }),
      204,
    );
    expectResponse(await harness.agent.delete("/api/personnels/$puuid"), 204);
    await expectAggregateInList(
      harness,
      uri: '/api/units',
      uuid: uuuid,
      listField: 'personnels',
      uuids: [],
    );
  });
}

Future<String> _createPersonnel(SarSysAppHarness harness, String ouuid, String auuid) async {
  final puuid = Uuid().v4();
  await harness.agent.post(
    "/api/operations/$ouuid/personnels",
    body: createPersonnel(puuid, auuid: auuid),
  );
  return puuid;
}

Future<String> _prepare(SarSysAppHarness harness, String auuid, String ouuid) async {
  await _createAffiliation(harness, auuid);
  final iuuid = Uuid().v4();
  expectResponse(await harness.agent.post("/api/incidents", body: createIncident(iuuid)), 201);
  expectResponse(await harness.agent.post("/api/incidents/$iuuid/operations", body: createOperation(ouuid)), 201);
  final uuuid = Uuid().v4();
  expectResponse(await harness.agent.post("/api/operations/$ouuid/units", body: createUnit(uuuid)), 201);
  return uuuid;
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
