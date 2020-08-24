import 'package:sarsys_domain/sarsys_domain.dart' hide Operation;
import 'package:uuid/uuid.dart';
import 'package:test/test.dart';

import 'harness.dart';

Future main() async {
  final harness = SarSysHarness()
    ..withEventStoreMock()
    ..install(restartForEachTest: true);

  test("POST /api/units/{uuid}/messages returns status code 201 with empty body", () async {
    final ouuid = await _prepare(harness);
    final uuid = Uuid().v4();
    final unit = _createData(uuid);
    expectResponse(await harness.agent.post("/api/operations/$ouuid/units", body: unit), 201, body: null);
    final msg = createMessage('1');
    expectResponse(await harness.agent.post("/api/units/$uuid/messages", body: msg), 201, body: null);
  });

  test("GET /api/units/{uuid}/messages returns status code 200", () async {
    final ouuid = await _prepare(harness);
    final uuid = Uuid().v4();
    final unit = _createData(uuid);
    expectResponse(await harness.agent.post("/api/operations/$ouuid/units", body: unit), 201, body: null);
    final clue1 = createMessage('1');
    expectResponse(await harness.agent.post("/api/units/$uuid/messages", body: clue1), 201, body: null);
    final clue2 = createMessage('2');
    expectResponse(await harness.agent.post("/api/units/$uuid/messages", body: clue2), 201, body: null);
    final response = expectResponse(await harness.agent.get("/api/units/$uuid/messages"), 200);
    final actual = await response.body.decode();
    expect(actual['total'], equals(2));
    expect(actual['entries'].length, equals(2));
  });

  test("GET /api/units/{uuid}/messages/{id} returns status code 200", () async {
    final ouuid = await _prepare(harness);
    final uuid = Uuid().v4();
    final unit = _createData(uuid);
    expectResponse(await harness.agent.post("/api/operations/$ouuid/units", body: unit), 201, body: null);
    final clue1 = createMessage('1');
    expectResponse(await harness.agent.post("/api/units/$uuid/messages", body: clue1), 201, body: null);
    final response1 = expectResponse(await harness.agent.get("/api/units/$uuid/messages/1"), 200);
    final actual1 = await response1.body.decode();
    expect(actual1['data'], equals(clue1));
    final clue2 = createMessage('2');
    expectResponse(await harness.agent.post("/api/units/$uuid/messages", body: clue2), 201, body: null);
    final response2 = expectResponse(await harness.agent.get("/api/units/$uuid/messages/2"), 200);
    final actual2 = await response2.body.decode();
    expect(actual2['data'], equals(clue2));
  });

  test("PATCH /api/units/{uuid}/messages/{id} is idempotent", () async {
    final ouuid = await _prepare(harness);
    final uuid = Uuid().v4();
    final unit = _createData(uuid);
    expectResponse(await harness.agent.post("/api/operations/$ouuid/units", body: unit), 201, body: null);
    final msg = createMessage('1');
    expectResponse(await harness.agent.post("/api/units/$uuid/messages", body: msg), 201, body: null);
    expectResponse(await harness.agent.execute("PATCH", "/api/units/$uuid/messages/1", body: msg), 204, body: null);
    final response1 = expectResponse(await harness.agent.get("/api/units/$uuid"), 200);
    final actual1 = await response1.body.decode();
    expect((actual1['data'] as Map)['messages'], equals([msg]));
    final response2 = expectResponse(await harness.agent.get("/api/units/$uuid/messages/1"), 200);
    final actual2 = await response2.body.decode();
    expect(actual2['data'], equals(msg));
  });

  test("PATCH /api/units/{uuid} on entity object lists should not be allowed", () async {
    final ouuid = await _prepare(harness);
    final uuid = Uuid().v4();
    final unit = _createData(uuid);
    expectResponse(await harness.agent.post("/api/operations/$ouuid/units", body: unit), 201, body: null);

    expectResponse(
        await harness.agent.execute("PATCH", "/api/units/$uuid", body: {
          "messages": [createMessage('1')],
        }),
        400,
        body: null);
  });

  test("DELETE /api/units/{uuid}/messages/{id} returns status code 204", () async {
    final ouuid = await _prepare(harness);
    final uuid = Uuid().v4();
    final unit = _createData(uuid);
    expectResponse(await harness.agent.post("/api/operations/$ouuid/units", body: unit), 201, body: null);
    final msg = createMessage('1');
    expectResponse(await harness.agent.post("/api/units/$uuid/messages", body: msg), 201, body: null);
    expectResponse(await harness.agent.delete("/api/units/$uuid/messages/1"), 204);
  });
}

Future<String> _prepare(SarSysHarness harness) async {
  final iuuid = Uuid().v4();
  expectResponse(await harness.agent.post("/api/incidents", body: createIncident(iuuid)), 201);
  final ouuid = Uuid().v4();
  expectResponse(await harness.agent.post("/api/incidents/$iuuid/operations", body: createOperation(ouuid)), 201);
  return ouuid;
}

Map<String, Object> _createData(String uuid) => createUnit(uuid);
