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

  test("POST /api/missions/{uuid}/parts returns status code 201 with empty body", () async {
    final ouuid = await _prepare(harness);
    final uuid = Uuid().v4();
    final mission = _createData(uuid);
    expectResponse(await harness.agent.post("/api/operations/$ouuid/missions", body: mission), 201, body: null);
    final part = createMissionPart('1');
    expectResponse(await harness.agent.post("/api/missions/$uuid/parts", body: part), 201, body: null);
  });

  test("GET /api/missions/{uuid}/parts returns status code 200", () async {
    final ouuid = await _prepare(harness);
    final uuid = Uuid().v4();
    final mission = _createData(uuid);
    expectResponse(await harness.agent.post("/api/operations/$ouuid/missions", body: mission), 201, body: null);
    final part1 = createMissionPart('1');
    expectResponse(await harness.agent.post("/api/missions/$uuid/parts", body: part1), 201, body: null);
    final part2 = createMissionPart('2');
    expectResponse(await harness.agent.post("/api/missions/$uuid/parts", body: part2), 201, body: null);
    final response = expectResponse(await harness.agent.get("/api/missions/$uuid/parts"), 200);
    final actual = await response.body.decode();
    expect(actual['total'], equals(2));
    expect(actual['entries'].length, equals(2));
  });

  test("GET /api/missions/{uuid}/parts/{id} returns status code 200", () async {
    final ouuid = await _prepare(harness);
    final uuid = Uuid().v4();
    final mission = _createData(uuid);
    expectResponse(await harness.agent.post("/api/operations/$ouuid/missions", body: mission), 201, body: null);
    final part1 = createMissionPart('1');
    expectResponse(await harness.agent.post("/api/missions/$uuid/parts", body: part1), 201, body: null);
    final response1 = expectResponse(await harness.agent.get("/api/missions/$uuid/parts/1"), 200);
    final actual1 = await response1.body.decode();
    expect(actual1['data'], equals(part1));
    final part2 = createMissionPart('2');
    expectResponse(await harness.agent.post("/api/missions/$uuid/parts", body: part2), 201, body: null);
    final response2 = expectResponse(await harness.agent.get("/api/missions/$uuid/parts/2"), 200);
    final actual2 = await response2.body.decode();
    expect(actual2['data'], equals(part2));
  });

  test("PATCH /api/missions/{uuid}/parts/{id} is idempotent", () async {
    final ouuid = await _prepare(harness);
    final uuid = Uuid().v4();
    final mission = _createData(uuid);
    expectResponse(await harness.agent.post("/api/operations/$ouuid/missions", body: mission), 201, body: null);
    final part = createMissionPart('1');
    expectResponse(await harness.agent.post("/api/missions/$uuid/parts", body: part), 201, body: null);
    expectResponse(await harness.agent.execute("PATCH", "/api/missions/$uuid/parts/1", body: part), 204, body: null);
    final response1 = expectResponse(await harness.agent.get("/api/missions/$uuid"), 200);
    final actual1 = await response1.body.decode();
    expect((actual1['data'] as Map)['parts'], equals([part]));
    final response2 = expectResponse(await harness.agent.get("/api/missions/$uuid/parts/1"), 200);
    final actual2 = await response2.body.decode();
    expect(actual2['data'], equals(part));
  });

  test("PATCH /api/missions/{uuid} on entity object lists should not be allowed", () async {
    final ouuid = await _prepare(harness);
    final uuid = Uuid().v4();
    final mission = _createData(uuid);
    expectResponse(await harness.agent.post("/api/operations/$ouuid/missions", body: mission), 201, body: null);

    expectResponse(
        await harness.agent.execute("PATCH", "/api/missions/$uuid", body: {
          "parts": [createMissionPart('1')],
        }),
        400,
        body: null);
  });

  test("DELETE /api/missions/{uuid}/parts/{id} returns status code 204", () async {
    final ouuid = await _prepare(harness);
    final uuid = Uuid().v4();
    final mission = _createData(uuid);
    expectResponse(await harness.agent.post("/api/operations/$ouuid/missions", body: mission), 201, body: null);
    final part = createMissionPart('1');
    expectResponse(await harness.agent.post("/api/missions/$uuid/parts", body: part), 201, body: null);
    expectResponse(await harness.agent.delete("/api/missions/$uuid"), 204);
  });
}

Future _prepare(SarSysHarness harness) async {
  harness.eventStoreMockServer.withStream(typeOf<Incident>().toColonCase());
  harness.eventStoreMockServer.withStream(typeOf<sar.Operation>().toColonCase());
  harness.eventStoreMockServer.withStream(typeOf<Mission>().toColonCase());
  await harness.channel.manager.get<IncidentRepository>().readyAsync();
  await harness.channel.manager.get<OperationRepository>().readyAsync();
  await harness.channel.manager.get<MissionRepository>().readyAsync();
  harness.eventStoreMockServer.withStream(typeOf<Mission>().toColonCase());
  await harness.channel.manager.get<MissionRepository>().readyAsync();
  final iuuid = Uuid().v4();
  expectResponse(await harness.agent.post("/api/incidents", body: createIncident(iuuid)), 201);
  final ouuid = Uuid().v4();
  expectResponse(await harness.agent.post("/api/incidents/$iuuid/operations", body: createOperation(ouuid)), 201);
  return ouuid;
}

Map<String, Object> _createData(String uuid) => createMission(uuid);
