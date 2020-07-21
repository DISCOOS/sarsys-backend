import 'package:sarsys_domain/sarsys_domain.dart' hide Operation;
import 'package:sarsys_domain/sarsys_domain.dart' as sar show Operation;
import 'package:event_source/event_source.dart';
import 'package:uuid/uuid.dart';
import 'package:test/test.dart';

import 'harness.dart';

Future main() async {
  final harness = SarSysHarness()
    ..withEventStoreMock()
    ..install(restartForEachTest: true);

  test("POST /api/units returns 405", () async {
    await _prepare(harness);
    final uuid = Uuid().v4();
    final body = createUnit(uuid);
    expectResponse(await harness.agent.post("/api/units", body: body), 405, body: null);
  });

  test("GET /api/units/{uuid} returns 200", () async {
    final ouuid = await _prepare(harness);
    final uuid = Uuid().v4();
    final body = createUnit(uuid);
    expectResponse(await harness.agent.post("/api/operations/$ouuid/units", body: body), 201, body: null);
    final response = expectResponse(await harness.agent.get("/api/units/$uuid"), 200);
    final actual = await response.body.decode();
    expect(
      actual['data'],
      equals(body
        ..addAll({
          'operation': {'uuid': ouuid}
        })),
    );
  });

  test("GET /api/units returns 200 with offset=1 and limit=2", () async {
    final ouuid = await _prepare(harness);
    await harness.agent.post("/api/operations/$ouuid/units", body: createUnit(Uuid().v4()));
    await harness.agent.post("/api/operations/$ouuid/units", body: createUnit(Uuid().v4()));
    await harness.agent.post("/api/operations/$ouuid/units", body: createUnit(Uuid().v4()));
    await harness.agent.post("/api/operations/$ouuid/units", body: createUnit(Uuid().v4()));
    final response = expectResponse(await harness.agent.get("/api/units?offset=1&limit=2"), 200);
    final actual = await response.body.decode();
    expect(actual['total'], equals(4));
    expect(actual['offset'], equals(1));
    expect(actual['limit'], equals(2));
    expect(actual['entries'].length, equals(2));
  });

  test("PATCH /api/units/{uuid} is idempotent", () async {
    final ouuid = await _prepare(harness);
    final uuid = Uuid().v4();
    final body = createUnit(uuid);
    expectResponse(await harness.agent.post("/api/operations/$ouuid/units", body: body), 201, body: null);
    expectResponse(await harness.agent.execute("PATCH", "/api/units/$uuid", body: body), 204, body: null);
    final response = expectResponse(await harness.agent.get("/api/units/$uuid"), 200);
    final actual = await response.body.decode();
    expect(
      actual['data'],
      equals(body
        ..addAll({
          'operation': {'uuid': ouuid}
        })),
    );
  });

  test("PATCH /api/units/{uuid} returns 200 with personnels that exists", () async {
    final ouuid = await _prepare(harness);
    final uuid = Uuid().v4();
    final tuuid = Uuid().v4();
    final puuid1 = Uuid().v4();
    final puuid2 = Uuid().v4();
    await _createPersonnel(harness, ouuid, puuid1);
    await _createPersonnel(harness, ouuid, puuid2);
    final body = createUnit(uuid, tuuid: tuuid);
    expectResponse(await harness.agent.post("/api/operations/$ouuid/units", body: body), 201, body: null);
    final next = Map.from(body)
      ..addAll({
        'personnels': [puuid1, puuid2]
      });
    expectResponse(await harness.agent.execute("PATCH", "/api/units/$uuid", body: next), 200, body: null);
  });

  test("PATCH /api/units/{uuid} returns 404 with personnels that does not exists", () async {
    final ouuid = await _prepare(harness);
    final uuid = Uuid().v4();
    final tuuid = Uuid().v4();
    final puuid1 = Uuid().v4();
    final puuid2 = Uuid().v4();
    await _createPersonnel(harness, ouuid, puuid1);
    final body = createUnit(uuid, tuuid: tuuid);
    expectResponse(await harness.agent.post("/api/operations/$ouuid/units", body: body), 201, body: null);
    final next = Map.from(body)
      ..addAll({
        'personnels': [puuid1, puuid2]
      });
    expectResponse(await harness.agent.execute("PATCH", "/api/units/$uuid", body: next), 404, body: null);
  });

  test("PATCH /api/units/{uuid} does not remove value objects", () async {
    final ouuid = await _prepare(harness);
    final uuid = Uuid().v4();
    final body = createUnit(uuid);
    expectResponse(await harness.agent.post("/api/operations/$ouuid/units", body: body), 201, body: null);
    expectResponse(await harness.agent.execute("PATCH", "/api/units/$uuid", body: {}), 204, body: null);
    final response = expectResponse(await harness.agent.get("/api/units/$uuid"), 200);
    final actual = await response.body.decode();
    expect(
      actual['data'],
      equals(body
        ..addAll({
          'operation': {'uuid': ouuid}
        })),
    );
  });

  test("DELETE /api/units/{uuid} returns 204", () async {
    final ouuid = await _prepare(harness);
    final uuid = Uuid().v4();
    final body = createUnit(uuid);
    expectResponse(await harness.agent.post("/api/operations/$ouuid/units", body: body), 201, body: null);
    expectResponse(await harness.agent.delete("/api/units/$uuid"), 204);
  });

  test("DELETE /api/units/{uuid} returns 204 with tracking enabled", () async {
    final ouuid = await _prepare(harness);
    final uuid = Uuid().v4();
    final tuuid = Uuid().v4();
    final body = createUnit(uuid, tuuid: tuuid);
    expectResponse(await harness.agent.post("/api/operations/$ouuid/units", body: body), 201, body: null);
    expectResponse(await harness.agent.delete("/api/units/$uuid"), 204);
  });
}

Future _createPersonnel(SarSysHarness harness, String ouuid, String puuid) async {
  final auuid = Uuid().v4();
  await _createAffiliation(harness, puuid, auuid);
  expectResponse(
    await harness.agent.post("/api/operations/$ouuid/personnels", body: createPersonnel(puuid, auuid: auuid)),
    201,
    body: null,
  );
}

Future<String> _createAffiliation(SarSysHarness harness, String puuid, String auuid) async {
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

Future<String> _prepare(SarSysHarness harness) async {
  harness.eventStoreMockServer.withStream(typeOf<Incident>().toColonCase());
  harness.eventStoreMockServer.withStream(typeOf<sar.Operation>().toColonCase());
  harness.eventStoreMockServer.withStream(typeOf<Unit>().toColonCase());
  harness.eventStoreMockServer.withStream(typeOf<Person>().toColonCase());
  harness.eventStoreMockServer.withStream(typeOf<Affiliation>().toColonCase());
  harness.eventStoreMockServer.withStream(typeOf<Organisation>().toColonCase());
  harness.eventStoreMockServer.withStream(typeOf<Personnel>().toColonCase());
  harness.eventStoreMockServer.withStream(typeOf<Tracking>().toColonCase());
  await harness.channel.manager.get<IncidentRepository>().readyAsync();
  await harness.channel.manager.get<OperationRepository>().readyAsync();
  await harness.channel.manager.get<UnitRepository>().readyAsync();
  await harness.channel.manager.get<OrganisationRepository>().readyAsync();
  await harness.channel.manager.get<AffiliationRepository>().readyAsync();
  await harness.channel.manager.get<PersonRepository>().readyAsync();
  await harness.channel.manager.get<PersonnelRepository>().readyAsync();
  await harness.channel.manager.get<TrackingRepository>().readyAsync();
  final iuuid = Uuid().v4();
  expectResponse(await harness.agent.post("/api/incidents", body: createIncident(iuuid)), 201);
  final ouuid = Uuid().v4();
  expectResponse(await harness.agent.post("/api/incidents/$iuuid/operations", body: createOperation(ouuid)), 201);
  return ouuid;
}
