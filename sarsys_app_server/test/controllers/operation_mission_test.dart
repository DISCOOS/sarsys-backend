import 'package:uuid/uuid.dart';
import 'package:test/test.dart';

import 'package:sarsys_app_server_test/sarsys_app_server_test.dart';

Future main() async {
  final harness = SarSysAppHarness()
    ..withEventStoreMock()
    ..install(restartForEachTest: true);

  test("POST /api/operation/{uuid}/mission adds mission to aggregate list", () async {
    final ouuid = await _prepare(harness);
    final muuid = Uuid().v4();
    final mission = _createData(muuid);
    expectResponse(
      await harness.agent.post("/api/operations/$ouuid/missions", body: mission),
      201,
      body: null,
    );
    await expectAggregateReference(
      harness,
      uri: '/api/missions',
      childUuid: muuid,
      child: mission,
      parentField: 'operation',
      parentUuid: ouuid,
    );
    await expectAggregateInList(
      harness,
      uri: '/api/operations',
      uuid: ouuid,
      listField: 'missions',
      uuids: [
        muuid,
      ],
    );
  });

  test("GET /api/operation/{uuid}/missions returns status code 200 with offset=1 and limit=2", () async {
    final ouuid = await _prepare(harness);
    await harness.agent.post("/api/operations/$ouuid/missions", body: _createData(Uuid().v4()));
    await harness.agent.post("/api/operations/$ouuid/missions", body: _createData(Uuid().v4()));
    await harness.agent.post("/api/operations/$ouuid/missions", body: _createData(Uuid().v4()));
    await harness.agent.post("/api/operations/$ouuid/missions", body: _createData(Uuid().v4()));
    final response = expectResponse(await harness.agent.get("/api/operations/$ouuid/missions?offset=1&limit=2"), 200);
    final actual = await response.body.decode();
    expect(actual['total'], equals(4));
    expect(actual['offset'], equals(1));
    expect(actual['limit'], equals(2));
    expect(actual['entries'].length, equals(2));
  });

  test("DELETE /api/missions/{uuid} should remove {uuid} from missions list in operation", () async {
    final ouuid = await _prepare(harness);
    final muuid = Uuid().v4();
    final mission = _createData(muuid);
    expectResponse(await harness.agent.post("/api/operations/$ouuid/missions", body: mission), 201, body: null);
    expectResponse(await harness.agent.delete("/api/missions/$muuid"), 204);
    await expectAggregateInList(
      harness,
      uri: '/api/operations',
      uuid: ouuid,
      listField: 'missions',
      uuids: [],
    );
  });
}

Future<String> _prepare(SarSysAppHarness harness) async {
  final iuuid = Uuid().v4();
  expectResponse(await harness.agent.post("/api/incidents", body: createIncident(iuuid)), 201);
  final ouuid = Uuid().v4();
  expectResponse(await harness.agent.post("/api/incidents/$iuuid/operations", body: createOperation(ouuid)), 201);
  return ouuid;
}

Map<String, Object> _createData(String uuid) => createMission(uuid);
