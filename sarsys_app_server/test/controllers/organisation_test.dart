import 'package:uuid/uuid.dart';
import 'package:test/test.dart';

import 'harness.dart';

Future main() async {
  final harness = SarSysHarness()
    ..withEventStoreMock()
    ..install(restartForEachTest: true);

  test("POST /api/organisations/ returns status code 201 with empty body", () async {
    final uuid = Uuid().v4();
    final body = _createData(uuid);
    expectResponse(await harness.agent.post("/api/organisations", body: body), 201, body: null);
  });

  test("GET /api/organisations/{uuid} returns status code 200", () async {
    final uuid = Uuid().v4();
    final body = _createData(uuid);
    expectResponse(await harness.agent.post("/api/organisations", body: body), 201, body: null);
    final response = expectResponse(await harness.agent.get("/api/organisations/$uuid"), 200);
    final actual = await response.body.decode();
    expect(actual['data'], equals(body));
  });

  test("PATCH /api/organisations/{uuid} is idempotent", () async {
    final uuid = Uuid().v4();
    final body = _createData(uuid);
    expectResponse(await harness.agent.post("/api/organisations", body: body), 201, body: null);
    expectResponse(await harness.agent.execute("PATCH", "/api/organisations/$uuid", body: body), 204, body: null);
    final response = expectResponse(await harness.agent.get("/api/organisations/$uuid"), 200);
    final actual = await response.body.decode();
    expect(actual['data'], equals(body));
  });

  test("PATCH /api/organisations/{uuid} does not remove value objects", () async {
    final uuid = Uuid().v4();
    final body = _createData(uuid);
    expectResponse(await harness.agent.post("/api/organisations", body: body), 201, body: null);
    expectResponse(await harness.agent.execute("PATCH", "/api/organisations/$uuid", body: {}), 204, body: null);
    final response = expectResponse(await harness.agent.get("/api/organisations/$uuid"), 200);
    final actual = await response.body.decode();
    expect(actual['data'], equals(body));
  });

  test("DELETE /api/organisations/{uuid} returns status code 204", () async {
    final uuid = Uuid().v4();
    final body = _createData(uuid);
    expectResponse(await harness.agent.post("/api/organisations", body: body), 201, body: null);
    expectResponse(await harness.agent.delete("/api/organisations/$uuid"), 204);
  });

  test("GET /api/organisations returns status code 200 with offset=1 and limit=2", () async {
    await harness.agent.post("/api/organisations", body: _createData(Uuid().v4()));
    await harness.agent.post("/api/organisations", body: _createData(Uuid().v4()));
    await harness.agent.post("/api/organisations", body: _createData(Uuid().v4()));
    await harness.agent.post("/api/organisations", body: _createData(Uuid().v4()));
    final response = expectResponse(await harness.agent.get("/api/organisations?offset=1&limit=2"), 200);
    final actual = await response.body.decode();
    expect(actual['total'], equals(4));
    expect(actual['offset'], equals(1));
    expect(actual['limit'], equals(2));
    expect(actual['entries'].length, equals(2));
  });
}

Map<String, Object> _createData(String uuid) => createOrganisation(uuid);
