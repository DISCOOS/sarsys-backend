import 'package:uuid/uuid.dart';
import 'package:test/test.dart';

import 'harness.dart';

Future main() async {
  final harness = SarSysHarness()
    ..withEventStoreMock()
    ..install(restartForEachTest: true);

  test("POST /api/devices/{uuid}/messages returns status code 201 with empty body", () async {
    final uuid = Uuid().v4();
    final device = _createData(uuid);
    expectResponse(await harness.agent.post("/api/devices", body: device), 201, body: null);
    final message = createMessage('1');
    expectResponse(await harness.agent.post("/api/devices/$uuid/messages", body: message), 201, body: null);
  });

  test("GET /api/devices/{uuid}/messages returns status code 200", () async {
    final uuid = Uuid().v4();
    final device = _createData(uuid);
    expectResponse(await harness.agent.post("/api/devices", body: device), 201, body: null);
    final message1 = createMessage('1');
    expectResponse(await harness.agent.post("/api/devices/$uuid/messages", body: message1), 201, body: null);
    final message2 = createMessage('2');
    expectResponse(await harness.agent.post("/api/devices/$uuid/messages", body: message2), 201, body: null);
    final response = expectResponse(await harness.agent.get("/api/devices/$uuid/messages"), 200);
    final actual = await response.body.decode();
    expect(actual['total'], equals(2));
    expect(actual['entries'].length, equals(2));
  });

  test("GET /api/devices/{uuid}/messages/{id} returns status code 200", () async {
    final uuid = Uuid().v4();
    final device = _createData(uuid);
    expectResponse(await harness.agent.post("/api/devices", body: device), 201, body: null);
    final message1 = createMessage('1');
    expectResponse(await harness.agent.post("/api/devices/$uuid/messages", body: message1), 201, body: null);
    final response1 = expectResponse(await harness.agent.get("/api/devices/$uuid/messages/1"), 200);
    final actual1 = await response1.body.decode();
    expect(actual1['data'], equals(message1));
    final message2 = createMessage('2');
    expectResponse(await harness.agent.post("/api/devices/$uuid/messages", body: message2), 201, body: null);
    final response2 = expectResponse(await harness.agent.get("/api/devices/$uuid/messages/2"), 200);
    final actual2 = await response2.body.decode();
    expect(actual2['data'], equals(message2));
  });

  test("PATCH /api/devices/{uuid}/messages/{id} is idempotent", () async {
    final uuid = Uuid().v4();
    final device = _createData(uuid);
    expectResponse(await harness.agent.post("/api/devices", body: device), 201, body: null);
    final message = createMessage('1');
    expectResponse(await harness.agent.post("/api/devices/$uuid/messages", body: message), 201, body: null);
    expectResponse(await harness.agent.execute("PATCH", "/api/devices/$uuid/messages/1", body: message), 204,
        body: null);
    final response1 = expectResponse(await harness.agent.get("/api/devices/$uuid"), 200);
    final actual1 = await response1.body.decode();
    expect((actual1['data'] as Map)['messages'], equals([message]));
    final response2 = expectResponse(await harness.agent.get("/api/devices/$uuid/messages/1"), 200);
    final actual2 = await response2.body.decode();
    expect(actual2['data'], equals(message));
  });

  test("PATCH /api/devices/{uuid} on entity object lists should not be allowed", () async {
    final uuid = Uuid().v4();
    final device = _createData(uuid);
    expectResponse(await harness.agent.post("/api/devices", body: device), 201, body: null);

    expectResponse(
        await harness.agent.execute("PATCH", "/api/devices/$uuid", body: {
          "messages": [createMessage('1')],
        }),
        400,
        body: null);
  });

  test("DELETE /api/devices/{uuid}/messages/{id} returns status code 204", () async {
    final uuid = Uuid().v4();
    final device = _createData(uuid);
    expectResponse(await harness.agent.post("/api/devices", body: device), 201, body: null);
    final message = createMessage('1');
    expectResponse(await harness.agent.post("/api/devices/$uuid/messages", body: message), 201, body: null);
    expectResponse(await harness.agent.delete("/api/devices/$uuid/messages/1"), 204);
  });
}

Map<String, Object> _createData(String uuid) => createDevice(uuid);
