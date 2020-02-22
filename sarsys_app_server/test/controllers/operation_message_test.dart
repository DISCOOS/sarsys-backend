import 'package:sarsys_domain/sarsys_domain.dart' hide Operation;
import 'package:sarsys_domain/sarsys_domain.dart' as sar show Operation;
import 'package:event_source/event_source.dart';
import 'package:uuid/uuid.dart';
import 'package:test/test.dart';

import 'harness.dart';

Future main() async {
  final harness = SarSysHarness()
    ..withEventStoreMock()
    ..install(restartForEachTest: true);

  test("POST /api/operations/{uuid}/messages returns status code 201 with empty body", () async {
    harness.eventStoreMockServer.withStream(typeOf<sar.Operation>().toColonCase());
    await harness.channel.manager.get<OperationRepository>().readyAsync();
    final uuid = Uuid().v4();
    final operation = _createData(uuid);
    expectResponse(await harness.agent.post("/api/operations", body: operation), 201, body: null);
    final message = createMessage(1);
    expectResponse(await harness.agent.post("/api/operations/$uuid/messages", body: message), 201, body: null);
  });

  test("GET /api/operations/{uuid}/messages returns status code 200", () async {
    harness.eventStoreMockServer.withStream(typeOf<sar.Operation>().toColonCase());
    await harness.channel.manager.get<OperationRepository>().readyAsync();
    final uuid = Uuid().v4();
    final operation = _createData(uuid);
    expectResponse(await harness.agent.post("/api/operations", body: operation), 201, body: null);
    final message1 = createMessage(1);
    expectResponse(await harness.agent.post("/api/operations/$uuid/messages", body: message1), 201, body: null);
    final message2 = createMessage(2);
    expectResponse(await harness.agent.post("/api/operations/$uuid/messages", body: message2), 201, body: null);
    final response = expectResponse(await harness.agent.get("/api/operations/$uuid/messages"), 200);
    final actual = await response.body.decode();
    expect(actual['total'], equals(2));
    expect(actual['entries'].length, equals(2));
  });

  test("GET /api/operations/{uuid}/messages/{id} returns status code 200", () async {
    harness.eventStoreMockServer.withStream(typeOf<sar.Operation>().toColonCase());
    await harness.channel.manager.get<OperationRepository>().readyAsync();
    final uuid = Uuid().v4();
    final operation = _createData(uuid);
    expectResponse(await harness.agent.post("/api/operations", body: operation), 201, body: null);
    final message1 = createMessage(1);
    expectResponse(await harness.agent.post("/api/operations/$uuid/messages", body: message1), 201, body: null);
    final response1 = expectResponse(await harness.agent.get("/api/operations/$uuid/messages/1"), 200);
    final actual1 = await response1.body.decode();
    expect(actual1['data'], equals(message1));
    final message2 = createMessage(2);
    expectResponse(await harness.agent.post("/api/operations/$uuid/messages", body: message2), 201, body: null);
    final response2 = expectResponse(await harness.agent.get("/api/operations/$uuid/messages/2"), 200);
    final actual2 = await response2.body.decode();
    expect(actual2['data'], equals(message2));
  });

  test("PATCH /api/operations/{uuid}/messages/{id} is idempotent", () async {
    harness.eventStoreMockServer.withStream(typeOf<sar.Operation>().toColonCase());
    await harness.channel.manager.get<OperationRepository>().readyAsync();
    final uuid = Uuid().v4();
    final operation = _createData(uuid);
    expectResponse(await harness.agent.post("/api/operations", body: operation), 201, body: null);
    final message = createMessage(0);
    expectResponse(await harness.agent.post("/api/operations/$uuid/messages", body: message), 201, body: null);
    expectResponse(await harness.agent.execute("PATCH", "/api/operations/$uuid/messages/0", body: message), 204,
        body: null);
    final response1 = expectResponse(await harness.agent.get("/api/operations/$uuid"), 200);
    final actual1 = await response1.body.decode();
    expect((actual1['data'] as Map)['messages'], equals([message]));
    final response2 = expectResponse(await harness.agent.get("/api/operations/$uuid/messages/0"), 200);
    final actual2 = await response2.body.decode();
    expect(actual2['data'], equals(message));
  });

  test("PATCH /api/operations/{uuid} on entity object lists should not be allowed", () async {
    harness.eventStoreMockServer.withStream(typeOf<sar.Operation>().toColonCase());
    await harness.channel.manager.get<OperationRepository>().readyAsync();
    final uuid = Uuid().v4();
    final operation = _createData(uuid);
    expectResponse(await harness.agent.post("/api/operations", body: operation), 201, body: null);

    expectResponse(
        await harness.agent.execute("PATCH", "/api/operations/$uuid", body: {
          "messages": [createMessage(1)],
        }),
        400,
        body: null);
  });

  test("DELETE /api/operations/{uuid}/messages/{id} returns status code 204", () async {
    harness.eventStoreMockServer.withStream(typeOf<sar.Operation>().toColonCase());
    await harness.channel.manager.get<OperationRepository>().readyAsync();
    final uuid = Uuid().v4();
    final operation = _createData(uuid);
    expectResponse(await harness.agent.post("/api/operations", body: operation), 201, body: null);
    final message = createMessage(0);
    expectResponse(await harness.agent.post("/api/operations/$uuid/messages", body: message), 201, body: null);
    expectResponse(await harness.agent.delete("/api/operations/$uuid"), 204);
  });
}

Map<String, Object> _createData(String uuid) => createOperation(uuid);
