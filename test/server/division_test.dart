import 'package:sarsys_app_server/domain/division/division.dart';
import 'package:sarsys_app_server/eventsource/eventsource.dart';
import 'package:uuid/uuid.dart';
import 'package:test/test.dart';

import 'harness.dart';

Future main() async {
  final harness = SarSysHarness()
    ..withEventStoreMock()
    ..install(restartForEachTest: true);

  test("POST /api/divisions/ returns status code 201 with empty body", () async {
    harness.eventStoreMockServer.withStream(typeOf<Division>().toColonCase());
    await harness.channel.manager.get<DivisionRepository>().readyAsync();
    final uuid = Uuid().v4();
    final body = _createData(uuid);
    expectResponse(await harness.agent.post("/api/divisions", body: body), 201, body: null);
  });

  test("POST /api/divisions/ returns status code 400 when 'organisation/uuid' is given", () async {
    harness.eventStoreMockServer.withStream(typeOf<Division>().toColonCase());
    await harness.channel.manager.get<DivisionRepository>().readyAsync();
    final uuid = Uuid().v4();
    final body = _createData(uuid)
      ..addAll({
        'organisation': {'uuid': 'string'}
      });
    expectResponse(
      await harness.agent.post("/api/divisions", body: body),
      400,
      body: 'Schema Division has 1 errors: /organisation/uuid: is read only',
    );
  });

  test("GET /api/divisions/{uuid} returns status code 200", () async {
    harness.eventStoreMockServer.withStream(typeOf<Division>().toColonCase());
    await harness.channel.manager.get<DivisionRepository>().readyAsync();
    final uuid = Uuid().v4();
    final body = _createData(uuid);
    expectResponse(await harness.agent.post("/api/divisions", body: body), 201, body: null);
    final response = expectResponse(await harness.agent.get("/api/divisions/$uuid"), 200);
    final actual = await response.body.decode();
    expect(actual['data'], equals(body));
  });

  test("PATCH /api/divisions/{uuid} is idempotent", () async {
    harness.eventStoreMockServer.withStream(typeOf<Division>().toColonCase());
    await harness.channel.manager.get<DivisionRepository>().readyAsync();
    final uuid = Uuid().v4();
    final body = _createData(uuid);
    expectResponse(await harness.agent.post("/api/divisions", body: body), 201, body: null);
    expectResponse(await harness.agent.execute("PATCH", "/api/divisions/$uuid", body: body), 204, body: null);
    final response = expectResponse(await harness.agent.get("/api/divisions/$uuid"), 200);
    final actual = await response.body.decode();
    expect(actual['data'], equals(body));
  });

  test("PATCH /api/divisions/{uuid} does not remove value objects", () async {
    harness.eventStoreMockServer.withStream(typeOf<Division>().toColonCase());
    await harness.channel.manager.get<DivisionRepository>().readyAsync();
    final uuid = Uuid().v4();
    final body = _createData(uuid);
    expectResponse(await harness.agent.post("/api/divisions", body: body), 201, body: null);
    expectResponse(await harness.agent.execute("PATCH", "/api/divisions/$uuid", body: {}), 204, body: null);
    final response = expectResponse(await harness.agent.get("/api/divisions/$uuid"), 200);
    final actual = await response.body.decode();
    expect(actual['data'], equals(body));
  });

  test("DELETE /api/divisions/{uuid} returns status code 204", () async {
    harness.eventStoreMockServer.withStream(typeOf<Division>().toColonCase());
    await harness.channel.manager.get<DivisionRepository>().readyAsync();
    final uuid = Uuid().v4();
    final body = _createData(uuid);
    expectResponse(await harness.agent.post("/api/divisions", body: body), 201, body: null);
    expectResponse(await harness.agent.delete("/api/divisions/$uuid"), 204);
  });

  test("GET /api/divisions returns status code 200 with offset=1 and limit=2", () async {
    harness.eventStoreMockServer.withStream(typeOf<Division>().toColonCase());
    await harness.channel.manager.get<DivisionRepository>().readyAsync();
    await harness.agent.post("/api/divisions", body: _createData(Uuid().v4()));
    await harness.agent.post("/api/divisions", body: _createData(Uuid().v4()));
    await harness.agent.post("/api/divisions", body: _createData(Uuid().v4()));
    await harness.agent.post("/api/divisions", body: _createData(Uuid().v4()));
    final response = expectResponse(await harness.agent.get("/api/divisions?offset=1&limit=2"), 200);
    final actual = await response.body.decode();
    expect(actual['total'], equals(4));
    expect(actual['offset'], equals(1));
    expect(actual['limit'], equals(2));
    expect(actual['entries'].length, equals(2));
  });
}

Map<String, Object> _createData(String uuid) => createDivision(uuid);
