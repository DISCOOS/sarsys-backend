import 'package:sarsys_app_server/domain/operation/operation.dart' as sar;
import 'package:sarsys_app_server/eventsource/eventsource.dart';
import 'package:uuid/uuid.dart';
import 'package:test/test.dart';

import 'harness.dart';

Future main() async {
  final harness = SarSysHarness()
    ..withEventStoreMock()
    ..install(restartForEachTest: true);

  test("POST /api/operations/ returns status code 201 with empty body", () async {
    harness.eventStoreMockServer.withStream(typeOf<Operation>().toColonCase());
    await harness.channel.manager.get<sar.OperationRepository>().readyAsync();
    final uuid = Uuid().v4();
    final body = _createData(uuid);
    expectResponse(await harness.agent.post("/api/operations", body: body), 201, body: null);
  });

  test("POST /api/operations/ returns status code 400 when 'incident/uuid' is given", () async {
    harness.eventStoreMockServer.withStream(typeOf<Operation>().toColonCase());
    await harness.channel.manager.get<sar.OperationRepository>().readyAsync();
    final uuid = Uuid().v4();
    final body = _createData(uuid)
      ..addAll({
        'incident': {'uuid': 'string'}
      });
    expectResponse(
      await harness.agent.post("/api/operations", body: body),
      400,
      body: 'Schema Operation has 1 errors: /incident/uuid: is read only',
    );
  });

  test("GET /api/operations/{uuid} returns status code 200", () async {
    harness.eventStoreMockServer.withStream(typeOf<Operation>().toColonCase());
    await harness.channel.manager.get<sar.OperationRepository>().readyAsync();
    final uuid = Uuid().v4();
    final body = _createData(uuid);
    expectResponse(await harness.agent.post("/api/operations", body: body), 201, body: null);
    final response = expectResponse(await harness.agent.get("/api/operations/$uuid"), 200);
    final actual = await response.body.decode();
    expect(actual['data'], equals(body));
  });

  test("PATCH /api/operations/{uuid} is idempotent", () async {
    harness.eventStoreMockServer.withStream(typeOf<sar.Operation>().toColonCase());
    await harness.channel.manager.get<sar.OperationRepository>().readyAsync();
    final uuid = Uuid().v4();
    final body = _createData(uuid);
    expectResponse(await harness.agent.post("/api/operations", body: body), 201, body: null);
    expectResponse(await harness.agent.execute("PATCH", "/api/operations/$uuid", body: body), 204, body: null);
    final response = expectResponse(await harness.agent.get("/api/operations/$uuid"), 200);
    final actual = await response.body.decode();
    expect(actual['data'], equals(body));
  });

  test("PATCH /api/operations/{uuid} does not remove value objects", () async {
    harness.eventStoreMockServer.withStream(typeOf<sar.Operation>().toColonCase());
    await harness.channel.manager.get<sar.OperationRepository>().readyAsync();
    final uuid = Uuid().v4();
    final body = _createData(uuid);
    expectResponse(await harness.agent.post("/api/operations", body: body), 201, body: null);
    expectResponse(await harness.agent.execute("PATCH", "/api/operations/$uuid", body: {}), 204, body: null);
    final response = expectResponse(await harness.agent.get("/api/operations/$uuid"), 200);
    final actual = await response.body.decode();
    expect(actual['data'], equals(body));
  });

  test("PATCH /api/operations/{uuid} on value object lists supports add, remove and replace", () async {
    harness.eventStoreMockServer.withStream(typeOf<sar.Operation>().toColonCase());
    await harness.channel.manager.get<sar.OperationRepository>().readyAsync();
    final uuid = Uuid().v4();
    final body = _createData(uuid);
    expectResponse(await harness.agent.post("/api/operations", body: body), 201, body: null);

    // Test that value objects are added to lists
    var lists = {
      "units": ["string1"],
      "missions": ["string1"],
      "personnels": ["string1"],
    };
    expectResponse(await harness.agent.execute("PATCH", "/api/operations/$uuid", body: lists), 204, body: null);
    var response = expectResponse(await harness.agent.get("/api/operations/$uuid"), 200);
    var actual = await response.body.decode();
    body.addAll(lists);
    expect(actual['data'], equals(body), reason: "List was not appended");

    // Test that value objects are removed from lists
    lists = {
      "units": ["string2"],
      "missions": ["string2"],
      "personnels": ["string2"],
    };
    expectResponse(await harness.agent.execute("PATCH", "/api/operations/$uuid", body: lists), 204, body: null);
    response = expectResponse(await harness.agent.get("/api/operations/$uuid"), 200);
    actual = await response.body.decode();
    body.addAll(lists);
    expect(actual['data'], equals(body), reason: "List was not replaced");

    // Test that subjects are removed
    lists = {"units": [], "missions": [], "personnels": []};
    expectResponse(await harness.agent.execute("PATCH", "/api/operations/$uuid", body: lists), 204, body: null);
    response = expectResponse(await harness.agent.get("/api/operations/$uuid"), 200);
    actual = await response.body.decode();
    body.addAll(lists);
    expect(actual['data'], equals(body), reason: "List was not cleared");
  });

  test("DELETE /api/operations/{uuid} returns status code 204", () async {
    harness.eventStoreMockServer.withStream(typeOf<sar.Operation>().toColonCase());
    await harness.channel.manager.get<sar.OperationRepository>().readyAsync();
    final uuid = Uuid().v4();
    final body = _createData(uuid);
    expectResponse(await harness.agent.post("/api/operations", body: body), 201, body: null);
    expectResponse(await harness.agent.delete("/api/operations/$uuid"), 204);
  });

  test("GET /api/operations returns status code 200 with offset=1 and limit=2", () async {
    harness.eventStoreMockServer.withStream(typeOf<sar.Operation>().toColonCase());
    await harness.channel.manager.get<sar.OperationRepository>().readyAsync();
    await harness.agent.post("/api/operations", body: _createData(Uuid().v4()));
    await harness.agent.post("/api/operations", body: _createData(Uuid().v4()));
    await harness.agent.post("/api/operations", body: _createData(Uuid().v4()));
    await harness.agent.post("/api/operations", body: _createData(Uuid().v4()));
    final response = expectResponse(await harness.agent.get("/api/operations?offset=1&limit=2"), 200);
    final actual = await response.body.decode();
    expect(actual['total'], equals(4));
    expect(actual['offset'], equals(1));
    expect(actual['limit'], equals(2));
    expect(actual['entries'].length, equals(2));
  });
}

Map<String, Object> _createData(String uuid) => createOperation(uuid);
