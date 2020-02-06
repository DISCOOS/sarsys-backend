import 'package:sarsys_app_server/domain/operation/operation.dart' as sar;
import 'package:sarsys_app_server/eventsource/eventsource.dart';
import 'package:uuid/uuid.dart';
import 'package:test/test.dart';

import 'harness.dart';

Future main() async {
  final harness = SarSysHarness()
    ..withEventStoreMock()
    ..install(restartForEachTest: true);

  test("POST /api/operations/{uuid}/talkgroups returns status code 201 with empty body", () async {
    harness.eventStoreMockServer.withStream(typeOf<sar.Operation>().toColonCase());
    await harness.channel.manager.get<sar.OperationRepository>().readyAsync();
    final uuid = Uuid().v4();
    final operation = _createData(uuid);
    expectResponse(await harness.agent.post("/api/operations", body: operation), 201, body: null);
    final talkgroup = createTalkGroup(1);
    expectResponse(await harness.agent.post("/api/operations/$uuid/talkgroups", body: talkgroup), 201, body: null);
  });

  test("GET /api/operations/{uuid}/talkgroups returns status code 200", () async {
    harness.eventStoreMockServer.withStream(typeOf<sar.Operation>().toColonCase());
    await harness.channel.manager.get<sar.OperationRepository>().readyAsync();
    final uuid = Uuid().v4();
    final operation = _createData(uuid);
    expectResponse(await harness.agent.post("/api/operations", body: operation), 201, body: null);
    final talkgroup1 = createTalkGroup(1);
    expectResponse(await harness.agent.post("/api/operations/$uuid/talkgroups", body: talkgroup1), 201, body: null);
    final talkgroup2 = createTalkGroup(2);
    expectResponse(await harness.agent.post("/api/operations/$uuid/talkgroups", body: talkgroup2), 201, body: null);
    final response = expectResponse(await harness.agent.get("/api/operations/$uuid/talkgroups"), 200);
    final actual = await response.body.decode();
    expect(actual['total'], equals(2));
    expect(actual['entries'].length, equals(2));
  });

  test("GET /api/operations/{uuid}/talkgroups/{id} returns status code 200", () async {
    harness.eventStoreMockServer.withStream(typeOf<sar.Operation>().toColonCase());
    await harness.channel.manager.get<sar.OperationRepository>().readyAsync();
    final uuid = Uuid().v4();
    final operation = _createData(uuid);
    expectResponse(await harness.agent.post("/api/operations", body: operation), 201, body: null);
    final talkgroup1 = createTalkGroup(1);
    expectResponse(await harness.agent.post("/api/operations/$uuid/talkgroups", body: talkgroup1), 201, body: null);
    final response1 = expectResponse(await harness.agent.get("/api/operations/$uuid/talkgroups/1"), 200);
    final actual1 = await response1.body.decode();
    expect(actual1['data'], equals(talkgroup1));
    final talkgroup2 = createTalkGroup(2);
    expectResponse(await harness.agent.post("/api/operations/$uuid/talkgroups", body: talkgroup2), 201, body: null);
    final response2 = expectResponse(await harness.agent.get("/api/operations/$uuid/talkgroups/2"), 200);
    final actual2 = await response2.body.decode();
    expect(actual2['data'], equals(talkgroup2));
  });

  test("PATCH /api/operations/{uuid}/talkgroups/{id} is idempotent", () async {
    harness.eventStoreMockServer.withStream(typeOf<sar.Operation>().toColonCase());
    await harness.channel.manager.get<sar.OperationRepository>().readyAsync();
    final uuid = Uuid().v4();
    final operation = _createData(uuid);
    expectResponse(await harness.agent.post("/api/operations", body: operation), 201, body: null);
    final talkgroup = createTalkGroup(0);
    expectResponse(await harness.agent.post("/api/operations/$uuid/talkgroups", body: talkgroup), 201, body: null);
    expectResponse(await harness.agent.execute("PATCH", "/api/operations/$uuid/talkgroups/0", body: talkgroup), 204,
        body: null);
    final response1 = expectResponse(await harness.agent.get("/api/operations/$uuid"), 200);
    final actual1 = await response1.body.decode();
    expect((actual1['data'] as Map)['talkgroups'], equals([talkgroup]));
    final response2 = expectResponse(await harness.agent.get("/api/operations/$uuid/talkgroups/0"), 200);
    final actual2 = await response2.body.decode();
    expect(actual2['data'], equals(talkgroup));
  });

  test("PATCH /api/operations/{uuid} on entity object lists should not be allowed", () async {
    harness.eventStoreMockServer.withStream(typeOf<sar.Operation>().toColonCase());
    await harness.channel.manager.get<sar.OperationRepository>().readyAsync();
    final uuid = Uuid().v4();
    final operation = _createData(uuid);
    expectResponse(await harness.agent.post("/api/operations", body: operation), 201, body: null);

    expectResponse(
        await harness.agent.execute("PATCH", "/api/operations/$uuid", body: {
          "talkgroups": [createTalkGroup(1)],
        }),
        400,
        body: null);
  });

  test("DELETE /api/operations/{uuid}/talkgroups/{id} returns status code 204", () async {
    harness.eventStoreMockServer.withStream(typeOf<sar.Operation>().toColonCase());
    await harness.channel.manager.get<sar.OperationRepository>().readyAsync();
    final uuid = Uuid().v4();
    final operation = _createData(uuid);
    expectResponse(await harness.agent.post("/api/operations", body: operation), 201, body: null);
    final talkgroup = createTalkGroup(0);
    expectResponse(await harness.agent.post("/api/operations/$uuid/talkgroups", body: talkgroup), 201, body: null);
    expectResponse(await harness.agent.delete("/api/operations/$uuid"), 204);
  });
}

Map<String, Object> _createData(String uuid) => createOperation(uuid);
