import 'package:sarsys_app_server/domain/organisation/organisation.dart';
import 'package:sarsys_app_server/domain/division/division.dart';
import 'package:sarsys_app_server/eventsource/eventsource.dart';
import 'package:uuid/uuid.dart';
import 'package:test/test.dart';

import 'harness.dart';

Future main() async {
  final harness = SarSysHarness()
    ..withEventStoreMock()
    ..install(restartForEachTest: true);

  test("POST /api/organisation/{uuid}/division adds division to aggregate list", () async {
    await _install(harness);
    final organisationUuid = Uuid().v4();
    final organisation = createOrganisation(organisationUuid);
    expectResponse(await harness.agent.post("/api/organisations", body: organisation), 201, body: null);
    final divisionUuid = Uuid().v4();
    final division = _createData(divisionUuid);
    expectResponse(
      await harness.agent.post("/api/organisations/$organisationUuid/divisions", body: division),
      201,
      body: null,
    );
    await expectAggregateReference(
      harness,
      uri: '/api/divisions',
      childUuid: divisionUuid,
      child: division,
      parentField: 'organisation',
      parentUuid: organisationUuid,
    );
    await expectAggregateInList(
      harness,
      uri: '/api/organisations',
      uuid: organisationUuid,
      data: organisation,
      listField: 'divisions',
      uuids: [
        'string',
        divisionUuid,
      ],
    );
  });

  test("GET /api/organisation/{uuid}/divisions returns status code 200 with offset=1 and limit=2", () async {
    await _install(harness);
    final uuid = Uuid().v4();
    final organisation = createOrganisation(uuid);
    expectResponse(await harness.agent.post("/api/organisations", body: organisation), 201, body: null);
    await harness.agent.post("/api/organisations/$uuid/divisions", body: _createData(Uuid().v4()));
    await harness.agent.post("/api/organisations/$uuid/divisions", body: _createData(Uuid().v4()));
    await harness.agent.post("/api/organisations/$uuid/divisions", body: _createData(Uuid().v4()));
    await harness.agent.post("/api/organisations/$uuid/divisions", body: _createData(Uuid().v4()));
    final response = expectResponse(await harness.agent.get("/api/divisions?offset=1&limit=2"), 200);
    final actual = await response.body.decode();
    expect(actual['total'], equals(4));
    expect(actual['offset'], equals(1));
    expect(actual['limit'], equals(2));
    expect(actual['entries'].length, equals(2));
  });

  test("DELETE /api/divisions/{uuid} should remove {uuid} from divisions list in organisation", () async {
    await _install(harness);
    final organisationUuid = Uuid().v4();
    final organisation = createOrganisation(organisationUuid);
    expectResponse(await harness.agent.post("/api/organisations", body: organisation), 201, body: null);
    final divisionUuid = Uuid().v4();
    final body = _createData(divisionUuid);
    expectResponse(await harness.agent.post("/api/organisations/$organisationUuid/divisions", body: body), 201,
        body: null);
    expectResponse(await harness.agent.delete("/api/divisions/$divisionUuid"), 204);
    final response = expectResponse(await harness.agent.get("/api/organisations/$organisationUuid"), 200);
    final actual = await response.body.decode();
    expect(actual['data'], equals(organisation));
  });
}

Future _install(SarSysHarness harness) async {
  harness.eventStoreMockServer
    ..withStream(typeOf<Organisation>().toColonCase())
    ..withStream(typeOf<Division>().toColonCase());
  await harness.channel.manager.get<OrganisationRepository>().readyAsync();
  await harness.channel.manager.get<DivisionRepository>().readyAsync();
}

Map<String, Object> _createData(String uuid) => createDivision(uuid);
