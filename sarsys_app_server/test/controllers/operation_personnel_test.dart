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

  test("POST /api/operations/{uuid}/personnel adds personnel to aggregate list", () async {
    final ouuid = await _prepare(harness);
    final puuid = Uuid().v4();
    final personnel = createPersonnel(
      puuid,
      auuid: await _createAffiliation(harness, Uuid().v4()),
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

  test("GET /api/operations/{uuid}/personnels returns status code 200 with offset=1 and limit=2", () async {
    final ouuid = await _prepare(harness);
    await harness.agent.post(
      "/api/operations/$ouuid/personnels",
      body: createPersonnel(Uuid().v4(), auuid: await _createAffiliation(harness, Uuid().v4())),
    );
    await harness.agent.post(
      "/api/operations/$ouuid/personnels",
      body: createPersonnel(Uuid().v4(), auuid: await _createAffiliation(harness, Uuid().v4())),
    );
    await harness.agent.post(
      "/api/operations/$ouuid/personnels",
      body: createPersonnel(Uuid().v4(), auuid: await _createAffiliation(harness, Uuid().v4())),
    );
    await harness.agent.post(
      "/api/operations/$ouuid/personnels",
      body: createPersonnel(Uuid().v4(), auuid: await _createAffiliation(harness, Uuid().v4())),
    );
    final response = expectResponse(await harness.agent.get("/api/operations/$ouuid/personnels?offset=1&limit=2"), 200);
    final actual = await response.body.decode();
    expect(actual['total'], equals(4));
    expect(actual['offset'], equals(1));
    expect(actual['limit'], equals(2));
    expect(actual['entries'].length, equals(2));
  });

  test("DELETE /api/personnels/{uuid} should remove {uuid} from personnels list in operation", () async {
    final ouuid = await _prepare(harness);
    final puuid = Uuid().v4();
    final personnel = createPersonnel(
      puuid,
      auuid: await _createAffiliation(harness, Uuid().v4()),
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

Future<String> _prepare(SarSysHarness harness) async {
  harness.eventStoreMockServer.withStream(typeOf<Incident>().toColonCase());
  harness.eventStoreMockServer.withStream(typeOf<sar.Operation>().toColonCase());
  harness.eventStoreMockServer.withStream(typeOf<Organisation>().toColonCase());
  harness.eventStoreMockServer.withStream(typeOf<Person>().toColonCase());
  harness.eventStoreMockServer.withStream(typeOf<Personnel>().toColonCase());
  harness.eventStoreMockServer.withStream(typeOf<Affiliation>().toColonCase());
  await harness.channel.manager.get<IncidentRepository>().readyAsync();
  await harness.channel.manager.get<OrganisationRepository>().readyAsync();
  await harness.channel.manager.get<OperationRepository>().readyAsync();
  await harness.channel.manager.get<PersonRepository>().readyAsync();
  await harness.channel.manager.get<PersonnelRepository>().readyAsync();
  await harness.channel.manager.get<AffiliationRepository>().readyAsync();
  final iuuid = Uuid().v4();
  expectResponse(await harness.agent.post("/api/incidents", body: createIncident(iuuid)), 201);
  final ouuid = Uuid().v4();
  expectResponse(await harness.agent.post("/api/incidents/$iuuid/operations", body: createOperation(ouuid)), 201);
  return ouuid;
}

Future<String> _createAffiliation(SarSysHarness harness, String auuid) async {
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
