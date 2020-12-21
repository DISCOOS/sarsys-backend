import 'package:uuid/uuid.dart';
import 'package:test/test.dart';

import 'harness.dart';

Future main() async {
  final harness = SarSysHttpHarness()
    ..withEventStoreMock()
    ..install(restartForEachTest: true);

  test("POST /api/missions/{uuid}/messages returns status code 201 with empty body", () async {
    final ouuid = await _prepare(harness);
    final uuid = Uuid().v4();
    final mission = _createData(uuid);
    expectResponse(await harness.agent.post("/api/operations/$ouuid/missions", body: mission), 201, body: null);
    final clue = createMessage('1');
    expectResponse(await harness.agent.post("/api/missions/$uuid/messages", body: clue), 201, body: null);
  });

  test("GET /api/missions/{uuid}/messages returns status code 200", () async {
    final ouuid = await _prepare(harness);
    final uuid = Uuid().v4();
    final mission = _createData(uuid);
    expectResponse(await harness.agent.post("/api/operations/$ouuid/missions", body: mission), 201, body: null);
    final clue1 = createMessage('1');
    expectResponse(await harness.agent.post("/api/missions/$uuid/messages", body: clue1), 201, body: null);
    final clue2 = createMessage('2');
    expectResponse(await harness.agent.post("/api/missions/$uuid/messages", body: clue2), 201, body: null);
    final response = expectResponse(await harness.agent.get("/api/missions/$uuid/messages"), 200);
    final actual = await response.body.decode();
    expect(actual['total'], equals(2));
    expect(actual['entries'].length, equals(2));
  });

  test("GET /api/missions/{uuid}/messages/{id} returns status code 200", () async {
    final ouuid = await _prepare(harness);
    final uuid = Uuid().v4();
    final mission = _createData(uuid);
    expectResponse(await harness.agent.post("/api/operations/$ouuid/missions", body: mission), 201, body: null);
    final clue1 = createMessage('1');
    expectResponse(await harness.agent.post("/api/missions/$uuid/messages", body: clue1), 201, body: null);
    final response1 = expectResponse(await harness.agent.get("/api/missions/$uuid/messages/1"), 200);
    final actual1 = await response1.body.decode();
    expect(actual1['data'], equals(clue1));
    final clue2 = createMessage('2');
    expectResponse(await harness.agent.post("/api/missions/$uuid/messages", body: clue2), 201, body: null);
    final response2 = expectResponse(await harness.agent.get("/api/missions/$uuid/messages/2"), 200);
    final actual2 = await response2.body.decode();
    expect(actual2['data'], equals(clue2));
  });

  test("PATCH /api/missions/{uuid}/messages/{id} is idempotent", () async {
    final ouuid = await _prepare(harness);
    final uuid = Uuid().v4();
    final mission = _createData(uuid);
    expectResponse(await harness.agent.post("/api/operations/$ouuid/missions", body: mission), 201, body: null);
    final clue = createMessage('1');
    expectResponse(await harness.agent.post("/api/missions/$uuid/messages", body: clue), 201, body: null);
    expectResponse(await harness.agent.execute("PATCH", "/api/missions/$uuid/messages/1", body: clue), 204, body: null);
    final response1 = expectResponse(await harness.agent.get("/api/missions/$uuid"), 200);
    final actual1 = await response1.body.decode();
    expect((actual1['data'] as Map)['messages'], equals([clue]));
    final response2 = expectResponse(await harness.agent.get("/api/missions/$uuid/messages/1"), 200);
    final actual2 = await response2.body.decode();
    expect(actual2['data'], equals(clue));
  });

  test("PATCH /api/missions/{uuid} on entity object lists should not be allowed", () async {
    final ouuid = await _prepare(harness);
    final uuid = Uuid().v4();
    final mission = _createData(uuid);
    expectResponse(await harness.agent.post("/api/operations/$ouuid/missions", body: mission), 201, body: null);

    expectResponse(
        await harness.agent.execute("PATCH", "/api/missions/$uuid", body: {
          "messages": [createMessage('1')],
        }),
        400,
        body: null);
  });

  test("DELETE /api/missions/{uuid}/messages/{id} returns status code 204", () async {
    final ouuid = await _prepare(harness);
    final uuid = Uuid().v4();
    final mission = _createData(uuid);
    expectResponse(await harness.agent.post("/api/operations/$ouuid/missions", body: mission), 201, body: null);
    final clue = createMessage('1');
    expectResponse(await harness.agent.post("/api/missions/$uuid/messages", body: clue), 201, body: null);
    expectResponse(await harness.agent.delete("/api/missions/$uuid/messages/1"), 204);
  });
}

Future _prepare(SarSysHttpHarness harness) async {
  final iuuid = Uuid().v4();
  expectResponse(await harness.agent.post("/api/incidents", body: createIncident(iuuid)), 201);
  final ouuid = Uuid().v4();
  expectResponse(await harness.agent.post("/api/incidents/$iuuid/operations", body: createOperation(ouuid)), 201);
  return ouuid;
}

Map<String, Object> _createData(String uuid) => createMission(uuid);
