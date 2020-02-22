import 'package:sarsys_domain/sarsys_domain.dart';
import 'package:event_source/event_source.dart';
import 'package:uuid/uuid.dart';
import 'package:test/test.dart';

import 'harness.dart';

Future main() async {
  final harness = SarSysHarness()
    ..withEventStoreMock()
    ..install(restartForEachTest: true);

  test("POST /api/incidents/{uuid}/messages returns status code 201 with empty body", () async {
    harness.eventStoreMockServer.withStream(typeOf<Incident>().toColonCase());
    await harness.channel.manager.get<IncidentRepository>().readyAsync();
    final uuid = Uuid().v4();
    final incident = _createData(uuid);
    expectResponse(await harness.agent.post("/api/incidents", body: incident), 201, body: null);
    final clue = createMessage(1);
    expectResponse(await harness.agent.post("/api/incidents/$uuid/messages", body: clue), 201, body: null);
  });

  test("GET /api/incidents/{uuid}/messages returns status code 200", () async {
    harness.eventStoreMockServer.withStream(typeOf<Incident>().toColonCase());
    await harness.channel.manager.get<IncidentRepository>().readyAsync();
    final uuid = Uuid().v4();
    final incident = _createData(uuid);
    expectResponse(await harness.agent.post("/api/incidents", body: incident), 201, body: null);
    final clue1 = createMessage(1);
    expectResponse(await harness.agent.post("/api/incidents/$uuid/messages", body: clue1), 201, body: null);
    final clue2 = createMessage(2);
    expectResponse(await harness.agent.post("/api/incidents/$uuid/messages", body: clue2), 201, body: null);
    final response = expectResponse(await harness.agent.get("/api/incidents/$uuid/messages"), 200);
    final actual = await response.body.decode();
    expect(actual['total'], equals(2));
    expect(actual['entries'].length, equals(2));
  });

  test("GET /api/incidents/{uuid}/messages/{id} returns status code 200", () async {
    harness.eventStoreMockServer.withStream(typeOf<Incident>().toColonCase());
    await harness.channel.manager.get<IncidentRepository>().readyAsync();
    final uuid = Uuid().v4();
    final incident = _createData(uuid);
    expectResponse(await harness.agent.post("/api/incidents", body: incident), 201, body: null);
    final clue1 = createMessage(1);
    expectResponse(await harness.agent.post("/api/incidents/$uuid/messages", body: clue1), 201, body: null);
    final response1 = expectResponse(await harness.agent.get("/api/incidents/$uuid/messages/1"), 200);
    final actual1 = await response1.body.decode();
    expect(actual1['data'], equals(clue1));
    final clue2 = createMessage(2);
    expectResponse(await harness.agent.post("/api/incidents/$uuid/messages", body: clue2), 201, body: null);
    final response2 = expectResponse(await harness.agent.get("/api/incidents/$uuid/messages/2"), 200);
    final actual2 = await response2.body.decode();
    expect(actual2['data'], equals(clue2));
  });

  test("PATCH /api/incidents/{uuid}/messages/{id} is idempotent", () async {
    harness.eventStoreMockServer.withStream(typeOf<Incident>().toColonCase());
    await harness.channel.manager.get<IncidentRepository>().readyAsync();
    final uuid = Uuid().v4();
    final incident = _createData(uuid);
    expectResponse(await harness.agent.post("/api/incidents", body: incident), 201, body: null);
    final clue = createMessage(0);
    expectResponse(await harness.agent.post("/api/incidents/$uuid/messages", body: clue), 201, body: null);
    expectResponse(await harness.agent.execute("PATCH", "/api/incidents/$uuid/messages/0", body: clue), 204,
        body: null);
    final response1 = expectResponse(await harness.agent.get("/api/incidents/$uuid"), 200);
    final actual1 = await response1.body.decode();
    expect((actual1['data'] as Map)['messages'], equals([clue]));
    final response2 = expectResponse(await harness.agent.get("/api/incidents/$uuid/messages/0"), 200);
    final actual2 = await response2.body.decode();
    expect(actual2['data'], equals(clue));
  });

  test("PATCH /api/incidents/{uuid} on entity object lists should not be allowed", () async {
    harness.eventStoreMockServer.withStream(typeOf<Incident>().toColonCase());
    await harness.channel.manager.get<IncidentRepository>().readyAsync();
    final uuid = Uuid().v4();
    final incident = _createData(uuid);
    expectResponse(await harness.agent.post("/api/incidents", body: incident), 201, body: null);

    expectResponse(
        await harness.agent.execute("PATCH", "/api/incidents/$uuid", body: {
          "messages": [createMessage(1)],
        }),
        400,
        body: null);
  });

  test("DELETE /api/incidents/{uuid}/messages/{id} returns status code 204", () async {
    harness.eventStoreMockServer.withStream(typeOf<Incident>().toColonCase());
    await harness.channel.manager.get<IncidentRepository>().readyAsync();
    final uuid = Uuid().v4();
    final incident = _createData(uuid);
    expectResponse(await harness.agent.post("/api/incidents", body: incident), 201, body: null);
    final clue = createMessage(0);
    expectResponse(await harness.agent.post("/api/incidents/$uuid/messages", body: clue), 201, body: null);
    expectResponse(await harness.agent.delete("/api/incidents/$uuid"), 204);
  });
}

Map<String, Object> _createData(String uuid) => createIncident(uuid);
