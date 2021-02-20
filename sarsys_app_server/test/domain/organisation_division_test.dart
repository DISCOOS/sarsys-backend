import 'package:uuid/uuid.dart';
import 'package:test/test.dart';

import 'package:sarsys_app_server_test/sarsys_app_server_test.dart';

Future main() async {
  final harness = SarSysAppHarness()
    ..withEventStoreMock()
    ..install(restartForEachTest: true);

  test("POST /api/organisation/{uuid}/division adds division to aggregate list", () async {
    final orguuid = await _prepare(harness);
    final divuuid = Uuid().v4();
    final division = _createData(divuuid);
    expectResponse(
      await harness.agent.post("/api/organisations/$orguuid/divisions", body: division),
      201,
      body: null,
    );
    await expectAggregateReference(
      harness,
      uri: '/api/divisions',
      childUuid: divuuid,
      child: division,
      parentField: 'organisation',
      parentUuid: orguuid,
    );
    await expectAggregateInList(
      harness,
      uri: '/api/organisations',
      uuid: orguuid,
      listField: 'divisions',
      uuids: [
        divuuid,
      ],
    );
  });

  test("GET /api/organisation/{uuid}/divisions returns status code 200 with offset=1 and limit=2", () async {
    final orguuid = await _prepare(harness);
    await harness.agent.post("/api/organisations/$orguuid/divisions", body: _createData(Uuid().v4()));
    await harness.agent.post("/api/organisations/$orguuid/divisions", body: _createData(Uuid().v4()));
    await harness.agent.post("/api/organisations/$orguuid/divisions", body: _createData(Uuid().v4()));
    await harness.agent.post("/api/organisations/$orguuid/divisions", body: _createData(Uuid().v4()));
    final response = expectResponse(await harness.agent.get("/api/divisions?offset=1&limit=2"), 200);
    final actual = await response.body.decode();
    expect(actual['total'], equals(4));
    expect(actual['offset'], equals(1));
    expect(actual['limit'], equals(2));
    expect(actual['entries'].length, equals(2));
  });

  test("DELETE /api/divisions/{uuid} should remove {uuid} from divisions list in organisation", () async {
    final orguuid = await _prepare(harness);
    final divuuid = Uuid().v4();
    final body = _createData(divuuid);
    expectResponse(await harness.agent.post("/api/organisations/$orguuid/divisions", body: body), 201, body: null);
    expectResponse(await harness.agent.delete("/api/divisions/$divuuid"), 204);
    await expectAggregateInList(
      harness,
      uri: '/api/organisations',
      uuid: orguuid,
      listField: 'divisions',
      uuids: [],
    );
  });
}

Future<String> _prepare(SarSysAppHarness harness) async {
  final orguuid = Uuid().v4();
  final organisation = createOrganisation(orguuid);
  expectResponse(await harness.agent.post("/api/organisations", body: organisation), 201, body: null);
  return orguuid;
}

Map<String, Object> _createData(String uuid) => createDivision(uuid);
