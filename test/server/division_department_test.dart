import 'package:sarsys_app_server/domain/division/division.dart';
import 'package:sarsys_app_server/domain/department/department.dart';
import 'package:sarsys_app_server/eventsource/eventsource.dart';
import 'package:uuid/uuid.dart';
import 'package:test/test.dart';

import 'harness.dart';

Future main() async {
  final harness = SarSysHarness()
    ..withEventStoreMock()
    ..install(restartForEachTest: true);

  test("POST /api/division/{uuid}/department adds department to aggregate list", () async {
    await _install(harness);
    final divisionUuid = Uuid().v4();
    final division = createDivision(divisionUuid);
    expectResponse(await harness.agent.post("/api/divisions", body: division), 201, body: null);
    final departmentUuid = Uuid().v4();
    final department = _createData(departmentUuid);
    expectResponse(
      await harness.agent.post("/api/divisions/$divisionUuid/departments", body: department),
      201,
      body: null,
    );
    await expectAggregateReference(
      harness,
      uri: '/api/departments',
      childUuid: departmentUuid,
      child: department,
      parentField: 'division',
      parentUuid: divisionUuid,
    );
    await expectAggregateInList(
      harness,
      uri: '/api/divisions',
      uuid: divisionUuid,
      data: division,
      listField: 'departments',
      uuids: [
        'string',
        departmentUuid,
      ],
    );
  });

  test("GET /api/division/{uuid}/departments returns status code 200 with offset=1 and limit=2", () async {
    await _install(harness);
    final uuid = Uuid().v4();
    final division = createDivision(uuid);
    expectResponse(await harness.agent.post("/api/divisions", body: division), 201, body: null);
    await harness.agent.post("/api/divisions/$uuid/departments", body: _createData(Uuid().v4()));
    await harness.agent.post("/api/divisions/$uuid/departments", body: _createData(Uuid().v4()));
    await harness.agent.post("/api/divisions/$uuid/departments", body: _createData(Uuid().v4()));
    await harness.agent.post("/api/divisions/$uuid/departments", body: _createData(Uuid().v4()));
    final response = expectResponse(await harness.agent.get("/api/departments?offset=1&limit=2"), 200);
    final actual = await response.body.decode();
    expect(actual['total'], equals(4));
    expect(actual['offset'], equals(1));
    expect(actual['limit'], equals(2));
    expect(actual['entries'].length, equals(2));
  });

  test("DELETE /api/departments/{uuid} should remove {uuid} from departments list in division", () async {
    await _install(harness);
    final divisionUuid = Uuid().v4();
    final division = createDivision(divisionUuid);
    expectResponse(await harness.agent.post("/api/divisions", body: division), 201, body: null);
    final departmentUuid = Uuid().v4();
    final body = _createData(departmentUuid);
    expectResponse(await harness.agent.post("/api/divisions/$divisionUuid/departments", body: body), 201, body: null);
    expectResponse(await harness.agent.delete("/api/departments/$departmentUuid"), 204);
    final response = expectResponse(await harness.agent.get("/api/divisions/$divisionUuid"), 200);
    final actual = await response.body.decode();
    expect(actual['data'], equals(division));
  });
}

Future _install(SarSysHarness harness) async {
  harness.eventStoreMockServer
    ..withStream(typeOf<Division>().toColonCase())
    ..withStream(typeOf<Department>().toColonCase());
  await harness.channel.manager.get<DivisionRepository>().readyAsync();
  await harness.channel.manager.get<DepartmentRepository>().readyAsync();
}

Map<String, Object> _createData(String uuid) => createDepartment(uuid);
