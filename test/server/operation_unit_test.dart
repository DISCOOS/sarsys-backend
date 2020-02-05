import 'package:sarsys_app_server/domain/operation/operation.dart' as sar;
import 'package:sarsys_app_server/domain/unit/unit.dart';
import 'package:sarsys_app_server/eventsource/eventsource.dart';
import 'package:uuid/uuid.dart';
import 'package:test/test.dart';

import 'harness.dart';

Future main() async {
  final harness = SarSysHarness()
    ..withEventStoreMock()
    ..install(restartForEachTest: true);

  test("POST /api/operation/{uuid}/unit adds unit to aggregate list", () async {
    await _install(harness);
    final operationUuid = Uuid().v4();
    final operation = createOperation(operationUuid);
    expectResponse(await harness.agent.post("/api/operations", body: operation), 201, body: null);
    final unitUuid = Uuid().v4();
    final unit = _createData(unitUuid);
    expectResponse(
      await harness.agent.post("/api/operations/$operationUuid/units", body: unit),
      201,
      body: null,
    );
    await expectAggregateReference(
      harness,
      uri: '/api/units',
      childUuid: unitUuid,
      child: unit,
      parentField: 'operation',
      parentUuid: operationUuid,
    );
    await expectAggregateInList(
      harness,
      uri: '/api/operations',
      uuid: operationUuid,
      data: operation,
      listField: 'units',
      uuids: [
        'string',
        unitUuid,
      ],
    );
  });

  test("GET /api/operation/{uuid}/units returns status code 200 with offset=1 and limit=2", () async {
    await _install(harness);
    final uuid = Uuid().v4();
    final operation = createOperation(uuid);
    expectResponse(await harness.agent.post("/api/operations", body: operation), 201, body: null);
    await harness.agent.post("/api/operations/$uuid/units", body: _createData(Uuid().v4()));
    await harness.agent.post("/api/operations/$uuid/units", body: _createData(Uuid().v4()));
    await harness.agent.post("/api/operations/$uuid/units", body: _createData(Uuid().v4()));
    await harness.agent.post("/api/operations/$uuid/units", body: _createData(Uuid().v4()));
    final response = expectResponse(await harness.agent.get("/api/units?offset=1&limit=2"), 200);
    final actual = await response.body.decode();
    expect(actual['total'], equals(4));
    expect(actual['offset'], equals(1));
    expect(actual['limit'], equals(2));
    expect(actual['entries'].length, equals(2));
  });

  test("DELETE /api/units/{uuid} should remove {uuid} from units list in operation", () async {
    await _install(harness);
    final operationUuid = Uuid().v4();
    final operation = createOperation(operationUuid);
    expectResponse(await harness.agent.post("/api/operations", body: operation), 201, body: null);
    final unitUuid = Uuid().v4();
    final body = _createData(unitUuid);
    expectResponse(await harness.agent.post("/api/operations/$operationUuid/units", body: body), 201, body: null);
    expectResponse(await harness.agent.delete("/api/units/$unitUuid"), 204);
    final response = expectResponse(await harness.agent.get("/api/operations/$operationUuid"), 200);
    final actual = await response.body.decode();
    expect(actual['data'], equals(operation));
  });
}

Future _install(SarSysHarness harness) async {
  harness.eventStoreMockServer..withStream(typeOf<Operation>().toColonCase())..withStream(typeOf<Unit>().toColonCase());
  await harness.channel.manager.get<sar.OperationRepository>().readyAsync();
  await harness.channel.manager.get<UnitRepository>().readyAsync();
}

Map<String, Object> _createData(String uuid) => createUnit(uuid);
