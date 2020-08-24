import 'package:sarsys_domain/sarsys_domain.dart' hide Operation;
import 'package:uuid/uuid.dart';
import 'package:test/test.dart';

import 'harness.dart';

Future main() async {
  final harness = SarSysHarness()
    ..withEventStoreMock()
    ..install(restartForEachTest: true);

  test("POST /api/incident/{uuid}/operation adds operation to aggregate list", () async {
    final iuuid = await _prepare(harness);
    final ouuid = Uuid().v4();
    final operation = _createData(ouuid);
    expectResponse(
      await harness.agent.post("/api/incidents/$iuuid/operations", body: operation),
      201,
      body: null,
    );
    await expectAggregateReference(
      harness,
      uri: '/api/operations',
      childUuid: ouuid,
      child: operation,
      parentField: 'incident',
      parentUuid: iuuid,
    );
    await expectAggregateInList(
      harness,
      uri: '/api/incidents',
      uuid: iuuid,
      listField: 'operations',
      uuids: [
        ouuid,
      ],
    );
  });

  test("GET /api/incident/{uuid}/operations returns status code 200 with offset=1 and limit=2", () async {
    final uuid = await _prepare(harness);
    await harness.agent.post("/api/incidents/$uuid/operations", body: _createData(Uuid().v4()));
    await harness.agent.post("/api/incidents/$uuid/operations", body: _createData(Uuid().v4()));
    await harness.agent.post("/api/incidents/$uuid/operations", body: _createData(Uuid().v4()));
    await harness.agent.post("/api/incidents/$uuid/operations", body: _createData(Uuid().v4()));
    final response = expectResponse(await harness.agent.get("/api/incidents/$uuid/operations?offset=1&limit=2"), 200);
    final actual = await response.body.decode();
    expect(actual['total'], equals(4));
    expect(actual['offset'], equals(1));
    expect(actual['limit'], equals(2));
    expect(actual['entries'].length, equals(2));
  });

  test("DELETE /api/operations/{uuid} should remove {uuid} from operations list in incident", () async {
    final iuuid = Uuid().v4();
    final incident = createIncident(iuuid);
    expectResponse(await harness.agent.post("/api/incidents", body: incident), 201, body: null);
    final ouuid = Uuid().v4();
    final body = _createData(ouuid);
    expectResponse(await harness.agent.post("/api/incidents/$iuuid/operations", body: body), 201, body: null);
    expectResponse(await harness.agent.delete("/api/operations/$ouuid"), 204);
    final response = expectResponse(await harness.agent.get("/api/incidents/$iuuid"), 200);
    final actual = await response.body.decode();
    expect(
      actual['data'],
      equals(incident..addAll({'operations': []})),
    );
  });
}

Future<String> _prepare(SarSysHarness harness) async {
  final iuuid = Uuid().v4();
  final incident = createIncident(iuuid);
  expectResponse(await harness.agent.post("/api/incidents", body: incident), 201, body: null);
  return iuuid;
}

Map<String, Object> _createData(String uuid) => createOperation(uuid);
