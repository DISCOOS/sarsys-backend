import 'package:uuid/uuid.dart';
import 'package:test/test.dart';

import 'harness.dart';

Future main() async {
  final harness = SarSysHttpHarness()
    ..withEventStoreMock()
    ..install(restartForEachTest: true);

  test("POST /api/devices/ returns status code 201 with empty body", () async {
    final uuid = Uuid().v4();
    final body = _createData(uuid);
    expectResponse(await harness.agent.post("/api/devices", body: body), 201, body: null);
  });

  test("GET /api/devices/{uuid} returns status code 200", () async {
    final uuid = Uuid().v4();
    final body = _createData(uuid);
    expectResponse(await harness.agent.post("/api/devices", body: body), 201, body: null);
    final response = expectResponse(await harness.agent.get("/api/devices/$uuid"), 200);
    final actual = await response.body.decode();
    expect(actual['data'], equals(body));
  });

  test("PATCH /api/devices/{uuid} is idempotent", () async {
    final uuid = Uuid().v4();
    final body = _createData(uuid);
    expectResponse(await harness.agent.post("/api/devices", body: body), 201, body: null);
    expectResponse(await harness.agent.execute("PATCH", "/api/devices/$uuid", body: body), 204, body: null);
    final response = expectResponse(await harness.agent.get("/api/devices/$uuid"), 200);
    final actual = await response.body.decode();
    expect(actual['data'], equals(body));
  });

  test("PATCH /api/devices/{uuid} does not remove value objects", () async {
    final uuid = Uuid().v4();
    final body = _createData(uuid);
    expectResponse(await harness.agent.post("/api/devices", body: body), 201, body: null);
    expectResponse(await harness.agent.execute("PATCH", "/api/devices/$uuid", body: {}), 204, body: null);
    final response = expectResponse(await harness.agent.get("/api/devices/$uuid"), 200);
    final actual = await response.body.decode();
    expect(actual['data'], equals(body));
  });

  test("DELETE /api/devices/{uuid} returns status code 204", () async {
    final uuid = Uuid().v4();
    final body = _createData(uuid);
    expectResponse(await harness.agent.post("/api/devices", body: body), 201, body: null);
    expectResponse(await harness.agent.delete("/api/devices/$uuid"), 204);
  });

  test("GET /api/devices returns status code 200 with offset=1 and limit=2", () async {
    await harness.agent.post("/api/devices", body: _createData(Uuid().v4()));
    await harness.agent.post("/api/devices", body: _createData(Uuid().v4()));
    await harness.agent.post("/api/devices", body: _createData(Uuid().v4()));
    await harness.agent.post("/api/devices", body: _createData(Uuid().v4()));
    final response = expectResponse(await harness.agent.get("/api/devices?offset=1&limit=2"), 200);
    final actual = await response.body.decode();
    expect(actual['total'], equals(4));
    expect(actual['offset'], equals(1));
    expect(actual['limit'], equals(2));
    expect(actual['entries'].length, equals(2));
  });
}

Map<String, Object> _createData(String uuid) => createDevice(uuid);
