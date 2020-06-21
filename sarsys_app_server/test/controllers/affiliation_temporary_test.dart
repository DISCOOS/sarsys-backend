import 'package:sarsys_domain/sarsys_domain.dart';
import 'package:uuid/uuid.dart';
import 'package:test/test.dart';
import 'package:meta/meta.dart';

import 'harness.dart';

Future main() async {
  final harness = SarSysHarness()
    ..withEventStoreMock()
    ..install(restartForEachTest: true);

  test("POST /api/affiliations/temporary returns status code 201 with empty body", () async {
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
    expectResponse(await harness.agent.post("/api/affiliations/temporary", body: body), 201, body: null);
  });

  test("POST /api/affiliations/temporary returns status code 409 when permanent person exists", () async {
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
    expectResponse(await harness.agent.post("/api/persons", body: person), 201);
    expectResponse(await harness.agent.post("/api/affiliations/temporary", body: body), 409, body: null);
  });
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
