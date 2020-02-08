import 'package:sarsys_app_server/domain/mission/mission.dart';
import 'package:sarsys_app_server/eventsource/eventsource.dart';
import 'package:uuid/uuid.dart';
import 'package:test/test.dart';

import 'harness.dart';

Future main() async {
  final harness = SarSysHarness()
    ..withEventStoreMock()
    ..install(restartForEachTest: true);

  test("POST /api/missions/ returns status code 201 with empty body", () async {
    harness.eventStoreMockServer.withStream(typeOf<Mission>().toColonCase());
    await harness.channel.manager.get<MissionRepository>().readyAsync();
    final uuid = Uuid().v4();
    final body = _createData(uuid);
    expectResponse(await harness.agent.post("/api/missions", body: body), 201, body: null);
  });

  test("POST /api/missions/ returns status code 400 when 'incident/uuid' is given", () async {
    harness.eventStoreMockServer.withStream(typeOf<Mission>().toColonCase());
    await harness.channel.manager.get<MissionRepository>().readyAsync();
    final uuid = Uuid().v4();
    final body = _createData(uuid)
      ..addAll({
        'operation': {'uuid': 'string'}
      });
    expectResponse(
      await harness.agent.post("/api/missions", body: body),
      400,
      body: 'Schema Mission has 1 errors: [/operation: is read only]',
    );
  });

  test("GET /api/missions/{uuid} returns status code 200", () async {
    harness.eventStoreMockServer.withStream(typeOf<Mission>().toColonCase());
    await harness.channel.manager.get<MissionRepository>().readyAsync();
    final uuid = Uuid().v4();
    final body = _createData(uuid);
    expectResponse(await harness.agent.post("/api/missions", body: body), 201, body: null);
    final response = expectResponse(await harness.agent.get("/api/missions/$uuid"), 200);
    final actual = await response.body.decode();
    expect(actual['data'], equals(body));
  });

  test("PATCH /api/missions/{uuid} is idempotent", () async {
    harness.eventStoreMockServer.withStream(typeOf<Mission>().toColonCase());
    await harness.channel.manager.get<MissionRepository>().readyAsync();
    final uuid = Uuid().v4();
    final body = _createData(uuid);
    expectResponse(await harness.agent.post("/api/missions", body: body), 201, body: null);
    expectResponse(await harness.agent.execute("PATCH", "/api/missions/$uuid", body: body), 204, body: null);
    final response = expectResponse(await harness.agent.get("/api/missions/$uuid"), 200);
    final actual = await response.body.decode();
    expect(actual['data'], equals(body));
  });

  test("PATCH /api/missions/{uuid} does not remove value objects", () async {
    harness.eventStoreMockServer.withStream(typeOf<Mission>().toColonCase());
    await harness.channel.manager.get<MissionRepository>().readyAsync();
    final uuid = Uuid().v4();
    final body = _createData(uuid);
    expectResponse(await harness.agent.post("/api/missions", body: body), 201, body: null);
    expectResponse(await harness.agent.execute("PATCH", "/api/missions/$uuid", body: {}), 204, body: null);
    final response = expectResponse(await harness.agent.get("/api/missions/$uuid"), 200);
    final actual = await response.body.decode();
    expect(actual['data'], equals(body));
  });

  test("DELETE /api/missions/{uuid} returns status code 204", () async {
    harness.eventStoreMockServer.withStream(typeOf<Mission>().toColonCase());
    await harness.channel.manager.get<MissionRepository>().readyAsync();
    final uuid = Uuid().v4();
    final body = _createData(uuid);
    expectResponse(await harness.agent.post("/api/missions", body: body), 201, body: null);
    expectResponse(await harness.agent.delete("/api/missions/$uuid"), 204);
  });

  test("GET /api/missions returns status code 200 with offset=1 and limit=2", () async {
    harness.eventStoreMockServer.withStream(typeOf<Mission>().toColonCase());
    await harness.channel.manager.get<MissionRepository>().readyAsync();
    await harness.agent.post("/api/missions", body: _createData(Uuid().v4()));
    await harness.agent.post("/api/missions", body: _createData(Uuid().v4()));
    await harness.agent.post("/api/missions", body: _createData(Uuid().v4()));
    await harness.agent.post("/api/missions", body: _createData(Uuid().v4()));
    final response = expectResponse(await harness.agent.get("/api/missions?offset=1&limit=2"), 200);
    final actual = await response.body.decode();
    expect(actual['total'], equals(4));
    expect(actual['offset'], equals(1));
    expect(actual['limit'], equals(2));
    expect(actual['entries'].length, equals(2));
  });
}

Map<String, Object> _createData(String uuid) => createMission(uuid);
