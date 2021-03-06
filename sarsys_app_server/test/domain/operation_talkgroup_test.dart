import 'package:uuid/uuid.dart';
import 'package:test/test.dart';

import 'package:sarsys_app_server_test/sarsys_app_server_test.dart';

Future main() async {
  final harness = SarSysAppHarness()
    ..withEventStoreMock()
    ..install(restartForEachTest: true);

  test("POST /api/operations/{uuid}/talkgroups returns status code 201 with empty body", () async {
    final ouuid = await _prepare(harness);
    final talkgroup = createTalkGroup('1');
    expectResponse(await harness.agent.post("/api/operations/$ouuid/talkgroups", body: talkgroup), 201, body: null);
  });

  test("GET /api/operations/{ouuid}/talkgroups returns status code 200", () async {
    final ouuid = await _prepare(harness);
    final talkgroup1 = createTalkGroup('1');
    expectResponse(await harness.agent.post("/api/operations/$ouuid/talkgroups", body: talkgroup1), 201, body: null);
    final talkgroup2 = createTalkGroup('2');
    expectResponse(await harness.agent.post("/api/operations/$ouuid/talkgroups", body: talkgroup2), 201, body: null);
    final response = expectResponse(await harness.agent.get("/api/operations/$ouuid/talkgroups"), 200);
    final actual = await response.body.decode();
    expect(actual['total'], equals(2));
    expect(actual['entries'].length, equals(2));
  });

  test("GET /api/operations/{ouuid}/talkgroups/{id} returns status code 200", () async {
    final ouuid = await _prepare(harness);
    final talkgroup1 = createTalkGroup('1');
    expectResponse(await harness.agent.post("/api/operations/$ouuid/talkgroups", body: talkgroup1), 201, body: null);
    final response1 = expectResponse(await harness.agent.get("/api/operations/$ouuid/talkgroups/1"), 200);
    final actual1 = await response1.body.decode();
    expect(actual1['data'], equals(talkgroup1));
    final talkgroup2 = createTalkGroup('2');
    expectResponse(await harness.agent.post("/api/operations/$ouuid/talkgroups", body: talkgroup2), 201, body: null);
    final response2 = expectResponse(await harness.agent.get("/api/operations/$ouuid/talkgroups/2"), 200);
    final actual2 = await response2.body.decode();
    expect(actual2['data'], equals(talkgroup2));
  });

  test("PATCH /api/operations/{ouuid}/talkgroups/{id} is idempotent", () async {
    final ouuid = await _prepare(harness);
    final talkgroup = createTalkGroup('1');
    expectResponse(await harness.agent.post("/api/operations/$ouuid/talkgroups", body: talkgroup), 201, body: null);
    expectResponse(await harness.agent.execute("PATCH", "/api/operations/$ouuid/talkgroups/1", body: talkgroup), 204,
        body: null);
    final response1 = expectResponse(await harness.agent.get("/api/operations/$ouuid"), 200);
    final actual1 = await response1.body.decode();
    expect((actual1['data'] as Map)['talkgroups'], equals([talkgroup]));
    final response2 = expectResponse(await harness.agent.get("/api/operations/$ouuid/talkgroups/1"), 200);
    final actual2 = await response2.body.decode();
    expect(actual2['data'], equals(talkgroup));
  });

  test("PATCH /api/operations/{ouuid} on entity object lists should not be allowed", () async {
    final ouuid = await _prepare(harness);

    expectResponse(
        await harness.agent.execute("PATCH", "/api/operations/$ouuid", body: {
          "talkgroups": [createTalkGroup('1')],
        }),
        400,
        body: null);
  });

  test("DELETE /api/operations/{ouuid}/talkgroups/{id} returns status code 204", () async {
    final ouuid = await _prepare(harness);
    final talkgroup = createTalkGroup('1');
    expectResponse(await harness.agent.post("/api/operations/$ouuid/talkgroups", body: talkgroup), 201, body: null);
    expectResponse(await harness.agent.delete("/api/operations/$ouuid"), 204);
  });
}

Future<String> _prepare(SarSysAppHarness harness) async {
  final iuuid = Uuid().v4();
  expectResponse(await harness.agent.post("/api/incidents", body: createIncident(iuuid)), 201);
  final ouuid = Uuid().v4();
  expectResponse(await harness.agent.post("/api/incidents/$iuuid/operations", body: createOperation(ouuid)), 201);
  return ouuid;
}
