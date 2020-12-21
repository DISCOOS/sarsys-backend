import 'package:uuid/uuid.dart';
import 'package:test/test.dart';

import 'harness.dart';

Future main() async {
  final harness = SarSysHttpHarness()
    ..withEventStoreMock()
    ..install(restartForEachTest: true);

  test("POST /api/operations/{uuid}/objectives returns status code 201 with empty body", () async {
    final ouuid = await _prepare(harness);
    final objective = createObjective('1');
    expectResponse(await harness.agent.post("/api/operations/$ouuid/objectives", body: objective), 201, body: null);
  });

  test("GET /api/operations/{uuid}/objectives returns status code 200", () async {
    final ouuid = await _prepare(harness);
    final objective1 = createObjective('1');
    expectResponse(await harness.agent.post("/api/operations/$ouuid/objectives", body: objective1), 201, body: null);
    final objective2 = createObjective('2');
    expectResponse(await harness.agent.post("/api/operations/$ouuid/objectives", body: objective2), 201, body: null);
    final response = expectResponse(await harness.agent.get("/api/operations/$ouuid/objectives"), 200);
    final actual = await response.body.decode();
    expect(actual['total'], equals(2));
    expect(actual['entries'].length, equals(2));
  });

  test("GET /api/operations/{uuid}/objectives/{id} returns status code 200", () async {
    final ouuid = await _prepare(harness);
    final objective1 = createObjective('1');
    expectResponse(await harness.agent.post("/api/operations/$ouuid/objectives", body: objective1), 201, body: null);
    final response1 = expectResponse(await harness.agent.get("/api/operations/$ouuid/objectives/1"), 200);
    final actual1 = await response1.body.decode();
    expect(actual1['data'], equals(objective1));
    final objective2 = createObjective('2');
    expectResponse(await harness.agent.post("/api/operations/$ouuid/objectives", body: objective2), 201, body: null);
    final response2 = expectResponse(await harness.agent.get("/api/operations/$ouuid/objectives/2"), 200);
    final actual2 = await response2.body.decode();
    expect(actual2['data'], equals(objective2));
  });

  test("PATCH /api/operations/{uuid}/objectives/{id} is idempotent", () async {
    final ouuid = await _prepare(harness);
    final objective = createObjective('1');
    expectResponse(await harness.agent.post("/api/operations/$ouuid/objectives", body: objective), 201, body: null);
    expectResponse(
      await harness.agent.execute("PATCH", "/api/operations/$ouuid/objectives/1", body: objective),
      204,
      body: null,
    );
    final response1 = expectResponse(await harness.agent.get("/api/operations/$ouuid"), 200);
    final actual1 = await response1.body.decode();
    expect((actual1['data'] as Map)['objectives'], equals([objective]));
    final response2 = expectResponse(await harness.agent.get("/api/operations/$ouuid/objectives/1"), 200);
    final actual2 = await response2.body.decode();
    expect(actual2['data'], equals(objective));
  });

  test("PATCH /api/operations/{uuid} on entity object lists should not be allowed", () async {
    final ouuid = await _prepare(harness);

    expectResponse(
        await harness.agent.execute("PATCH", "/api/operations/$ouuid", body: {
          "objectives": [createObjective('1')],
        }),
        400,
        body: null);
  });

  test("DELETE /api/operations/{uuid}/objectives/{id} returns status code 204", () async {
    final ouuid = await _prepare(harness);
    final objective = createObjective('1');
    expectResponse(await harness.agent.post("/api/operations/$ouuid/objectives", body: objective), 201, body: null);
    expectResponse(await harness.agent.delete("/api/operations/$ouuid/objectives/1"), 204);
  });
}

Future<String> _prepare(SarSysHttpHarness harness) async {
  final iuuid = Uuid().v4();
  expectResponse(await harness.agent.post("/api/incidents", body: createIncident(iuuid)), 201);
  final ouuid = Uuid().v4();
  expectResponse(await harness.agent.post("/api/incidents/$iuuid/operations", body: createOperation(ouuid)), 201);
  return ouuid;
}
