import 'package:sarsys_domain/sarsys_domain.dart';
import 'package:event_source/event_source.dart';
import 'package:uuid/uuid.dart';
import 'package:test/test.dart';

import 'harness.dart';

Future main() async {
  final harness = SarSysHarness()
    ..withEventStoreMock()
    ..install(restartForEachTest: true);

  test("POST /api/units/{uuid}/messages returns status code 201 with empty body", () async {
    await _prepare(harness);
    final uuid = Uuid().v4();
    final unit = _createData(uuid);
    expectResponse(await harness.agent.post("/api/units", body: unit), 201, body: null);
    final clue = createMessage('1');
    expectResponse(await harness.agent.post("/api/units/$uuid/messages", body: clue), 201, body: null);
  });

  test("GET /api/units/{uuid}/messages returns status code 200", () async {
    await _prepare(harness);
    final uuid = Uuid().v4();
    final unit = _createData(uuid);
    expectResponse(await harness.agent.post("/api/units", body: unit), 201, body: null);
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
    await _prepare(harness);
    final uuid = Uuid().v4();
    final unit = _createData(uuid);
    expectResponse(await harness.agent.post("/api/units", body: unit), 201, body: null);
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
    await _prepare(harness);
    final uuid = Uuid().v4();
    final unit = _createData(uuid);
    expectResponse(await harness.agent.post("/api/units", body: unit), 201, body: null);
    final clue = createMessage('1');
    expectResponse(await harness.agent.post("/api/units/$uuid/messages", body: clue), 201, body: null);
    expectResponse(await harness.agent.execute("PATCH", "/api/units/$uuid/messages/1", body: clue), 204, body: null);
    final response1 = expectResponse(await harness.agent.get("/api/units/$uuid"), 200);
    final actual1 = await response1.body.decode();
    expect((actual1['data'] as Map)['messages'], equals([clue]));
    final response2 = expectResponse(await harness.agent.get("/api/units/$uuid/messages/1"), 200);
    final actual2 = await response2.body.decode();
    expect(actual2['data'], equals(clue));
  });

  test("PATCH /api/units/{uuid} on entity object lists should not be allowed", () async {
    await _prepare(harness);
    final uuid = Uuid().v4();
    final unit = _createData(uuid);
    expectResponse(await harness.agent.post("/api/units", body: unit), 201, body: null);

    expectResponse(
        await harness.agent.execute("PATCH", "/api/units/$uuid", body: {
          "messages": [createMessage('1')],
        }),
        400,
        body: null);
  });

  test("DELETE /api/units/{uuid}/messages/{id} returns status code 204", () async {
    await _prepare(harness);
    final uuid = Uuid().v4();
    final unit = _createData(uuid);
    expectResponse(await harness.agent.post("/api/units", body: unit), 201, body: null);
    final clue = createMessage('1');
    expectResponse(await harness.agent.post("/api/units/$uuid/messages", body: clue), 201, body: null);
    expectResponse(await harness.agent.delete("/api/units/$uuid"), 204);
  });
}

Future _prepare(SarSysHarness harness) async {
  harness.eventStoreMockServer.withStream(typeOf<Unit>().toColonCase());
  await harness.channel.manager.get<UnitRepository>().readyAsync();
}

Map<String, Object> _createData(String uuid) => createUnit(uuid);
