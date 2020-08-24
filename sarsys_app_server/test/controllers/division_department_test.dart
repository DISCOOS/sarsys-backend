import 'package:sarsys_domain/sarsys_domain.dart';
import 'package:event_source/event_source.dart';
import 'package:uuid/uuid.dart';
import 'package:test/test.dart';

import 'harness.dart';

Future main() async {
  final harness = SarSysHarness()
    ..withEventStoreMock()
    ..install(restartForEachTest: true);

  test("POST /api/division/{uuid}/departments adds department to aggregate list", () async {
    final divuuid = await _prepare(harness);
    final depuuid = Uuid().v4();
    final department = _createData(depuuid);
    expectResponse(
      await harness.agent.post("/api/divisions/$divuuid/departments", body: department),
      201,
      body: null,
    );
    await expectAggregateReference(
      harness,
      uri: '/api/departments',
      childUuid: depuuid,
      child: department,
      parentField: 'division',
      parentUuid: divuuid,
    );
    await expectAggregateInList(
      harness,
      uri: '/api/divisions',
      uuid: divuuid,
      listField: 'departments',
      uuids: [
        depuuid,
      ],
    );
  });

  test("GET /api/division/{uuid}/departments returns status code 200 with offset=1 and limit=2", () async {
    final divuuid = await _prepare(harness);
    await harness.agent.post("/api/divisions/$divuuid/departments", body: _createData(Uuid().v4()));
    await harness.agent.post("/api/divisions/$divuuid/departments", body: _createData(Uuid().v4()));
    await harness.agent.post("/api/divisions/$divuuid/departments", body: _createData(Uuid().v4()));
    await harness.agent.post("/api/divisions/$divuuid/departments", body: _createData(Uuid().v4()));
    final response = expectResponse(
      await harness.agent.get("/api/divisions/$divuuid/departments?offset=1&limit=2"),
      200,
    );
    final actual = await response.body.decode();
    expect(actual['total'], equals(4));
    expect(actual['offset'], equals(1));
    expect(actual['limit'], equals(2));
    expect(actual['entries'].length, equals(2));
  });

  test("DELETE /api/departments/{uuid} should remove {uuid} from departments list in division", () async {
    final divuuid = await _prepare(harness);
    final depuuid = Uuid().v4();
    final body = _createData(depuuid);
    expectResponse(await harness.agent.post("/api/divisions/$divuuid/departments", body: body), 201, body: null);
    expectResponse(await harness.agent.delete("/api/departments/$depuuid"), 204);
    final response = expectResponse(await harness.agent.get("/api/divisions/$divuuid"), 200);
    final actual = await response.body.decode();
    expect((actual['data'] as Map)?.elementAt('departments'), isEmpty);
  });
}

Future<String> _prepare(SarSysHarness harness) async {
  final orguuid = Uuid().v4();
  final divuuid = Uuid().v4();
  expectResponse(await harness.agent.post("/api/organisations", body: createOrganisation(orguuid)), 201);
  expectResponse(await harness.agent.post("/api/organisations/$orguuid/divisions", body: createDivision(divuuid)), 201);
  return divuuid;
}

Map<String, Object> _createData(String uuid) => createDepartment(uuid);
