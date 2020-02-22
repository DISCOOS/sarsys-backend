import 'package:sarsys_domain/sarsys_domain.dart' hide Operation;
import 'package:event_source/event_source.dart';
import 'package:uuid/uuid.dart';
import 'package:test/test.dart';

import 'harness.dart';

Future main() async {
  final harness = SarSysHarness()
    ..withEventStoreMock()
    ..install(restartForEachTest: true);

  test("POST /api/operation/{uuid}/mission adds mission to aggregate list", () async {
    await _install(harness);
    final operationUuid = Uuid().v4();
    final operation = createOperation(operationUuid);
    expectResponse(await harness.agent.post("/api/operations", body: operation), 201, body: null);
    final missionUuid = Uuid().v4();
    final mission = _createData(missionUuid);
    expectResponse(
      await harness.agent.post("/api/operations/$operationUuid/missions", body: mission),
      201,
      body: null,
    );
    await expectAggregateReference(
      harness,
      uri: '/api/missions',
      childUuid: missionUuid,
      child: mission,
      parentField: 'operation',
      parentUuid: operationUuid,
    );
    await expectAggregateInList(
      harness,
      uri: '/api/operations',
      uuid: operationUuid,
      data: operation,
      listField: 'missions',
      uuids: [
        'string',
        missionUuid,
      ],
    );
  });

  test("GET /api/operation/{uuid}/missions returns status code 200 with offset=1 and limit=2", () async {
    await _install(harness);
    final uuid = Uuid().v4();
    final operation = createOperation(uuid);
    expectResponse(await harness.agent.post("/api/operations", body: operation), 201, body: null);
    await harness.agent.post("/api/operations/$uuid/missions", body: _createData(Uuid().v4()));
    await harness.agent.post("/api/operations/$uuid/missions", body: _createData(Uuid().v4()));
    await harness.agent.post("/api/operations/$uuid/missions", body: _createData(Uuid().v4()));
    await harness.agent.post("/api/operations/$uuid/missions", body: _createData(Uuid().v4()));
    final response = expectResponse(await harness.agent.get("/api/missions?offset=1&limit=2"), 200);
    final actual = await response.body.decode();
    expect(actual['total'], equals(4));
    expect(actual['offset'], equals(1));
    expect(actual['limit'], equals(2));
    expect(actual['entries'].length, equals(2));
  });

  test("DELETE /api/missions/{uuid} should remove {uuid} from missions list in operation", () async {
    await _install(harness);
    final operationUuid = Uuid().v4();
    final operation = createOperation(operationUuid);
    expectResponse(await harness.agent.post("/api/operations", body: operation), 201, body: null);
    final missionUuid = Uuid().v4();
    final body = _createData(missionUuid);
    expectResponse(await harness.agent.post("/api/operations/$operationUuid/missions", body: body), 201, body: null);
    expectResponse(await harness.agent.delete("/api/missions/$missionUuid"), 204);
    final response = expectResponse(await harness.agent.get("/api/operations/$operationUuid"), 200);
    final actual = await response.body.decode();
    expect(actual['data'], equals(operation));
  });
}

Future _install(SarSysHarness harness) async {
  harness.eventStoreMockServer
    ..withStream(typeOf<Operation>().toColonCase())
    ..withStream(typeOf<Mission>().toColonCase());
  await harness.channel.manager.get<OperationRepository>().readyAsync();
  await harness.channel.manager.get<MissionRepository>().readyAsync();
}

Map<String, Object> _createData(String uuid) => createMission(uuid);
