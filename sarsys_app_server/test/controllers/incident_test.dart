import 'package:sarsys_domain/sarsys_domain.dart' hide Operation;
import 'package:uuid/uuid.dart';
import 'package:test/test.dart';

import 'harness.dart';

Future main() async {
  final harness = SarSysHarness()
    ..withEventStoreMock()
    ..install(restartForEachTest: true);

  test("POST /api/incidents/ returns status code 201 with empty body", () async {
    final uuid = Uuid().v4();
    final body = _createData(uuid);
    expectResponse(await harness.agent.post("/api/incidents", body: body), 201, body: null);
  });

  test("GET /api/incidents/{uuid} returns status code 200", () async {
    final uuid = Uuid().v4();
    final body = _createData(uuid);
    expectResponse(await harness.agent.post("/api/incidents", body: body), 201, body: null);
    final response = expectResponse(await harness.agent.get("/api/incidents/$uuid"), 200);
    final actual = await response.body.decode();
    expect(actual['data'], equals(body));
  });

  test("PATCH /api/incidents/{uuid} is idempotent", () async {
    final uuid = Uuid().v4();
    final body = _createData(uuid);
    expectResponse(await harness.agent.post("/api/incidents", body: body), 201, body: null);
    expectResponse(await harness.agent.execute("PATCH", "/api/incidents/$uuid", body: body), 204, body: null);
    final response = expectResponse(await harness.agent.get("/api/incidents/$uuid"), 200);
    final actual = await response.body.decode();
    expect(actual['data'], equals(body));
  });

  test("PATCH /api/incidents/{uuid} does not remove value objects", () async {
    final uuid = Uuid().v4();
    final body = _createData(uuid);
    expectResponse(await harness.agent.post("/api/incidents", body: body), 201, body: null);
    expectResponse(await harness.agent.execute("PATCH", "/api/incidents/$uuid", body: {}), 204, body: null);
    final response = expectResponse(await harness.agent.get("/api/incidents/$uuid"), 200);
    final actual = await response.body.decode();
    expect(actual['data'], equals(body));
  });

  test("PATCH /api/incidents/{uuid} on value object lists supports add, remove and replace", () async {
    final uuid = Uuid().v4();
    final body = _createData(uuid);
    expectResponse(await harness.agent.post("/api/incidents", body: body), 201, body: null);

    // Test that value objects are added to lists
    var lists = {
      "subjects": ["string1"],
      "operations": ["string1"]
    };
    expectResponse(await harness.agent.execute("PATCH", "/api/incidents/$uuid", body: lists), 200);
    var response = expectResponse(await harness.agent.get("/api/incidents/$uuid"), 200);
    var actual = await response.body.decode();
    body.addAll(lists);
    expect(actual['data'], equals(body), reason: "List was not appended");

    // Test that value objects are removed from lists
    lists = {
      "subjects": ["string2"],
      "operations": ["string2"]
    };
    expectResponse(await harness.agent.execute("PATCH", "/api/incidents/$uuid", body: lists), 200);
    response = expectResponse(await harness.agent.get("/api/incidents/$uuid"), 200);
    actual = await response.body.decode();
    body.addAll(lists);
    expect(actual['data'], equals(body), reason: "List was not replaced");

    // Test that subjects are removed
    lists = {"subjects": [], "operations": []};
    expectResponse(await harness.agent.execute("PATCH", "/api/incidents/$uuid", body: lists), 200);
    response = expectResponse(await harness.agent.get("/api/incidents/$uuid"), 200);
    actual = await response.body.decode();
    body.addAll(lists);
    expect(actual['data'], equals(body), reason: "List was not cleared");
  });

  test("DELETE /api/incidents/{uuid} returns status code 204", () async {
    final uuid = Uuid().v4();
    final body = _createData(uuid);
    expectResponse(await harness.agent.post("/api/incidents", body: body), 201, body: null);
    expectResponse(await harness.agent.delete("/api/incidents/$uuid"), 204);
  });

  test("GET /api/incidents returns status code 200 with offset=1 and limit=2", () async {
    await harness.agent.post("/api/incidents", body: _createData(Uuid().v4()));
    await harness.agent.post("/api/incidents", body: _createData(Uuid().v4()));
    await harness.agent.post("/api/incidents", body: _createData(Uuid().v4()));
    await harness.agent.post("/api/incidents", body: _createData(Uuid().v4()));
    final response = expectResponse(await harness.agent.get("/api/incidents?offset=1&limit=2"), 200);
    final actual = await response.body.decode();
    expect(actual['total'], equals(4));
    expect(actual['offset'], equals(1));
    expect(actual['limit'], equals(2));
    expect(actual['entries'].length, equals(2));
  });
}

Map<String, Object> _createData(String uuid) => createIncident(uuid);
