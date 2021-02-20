import 'package:uuid/uuid.dart';
import 'package:test/test.dart';

import 'package:sarsys_app_server_test/sarsys_app_server_test.dart';

Future main() async {
  final harness = SarSysAppHarness()
    ..withEventStoreMock()
    ..install(restartForEachTest: true);

  test("POST /api/personnels/{uuid}/messages returns status code 201 with empty body", () async {
    final puuid = Uuid().v4();
    final auuid = Uuid().v4();
    final ouuid = await _prepare(harness, auuid);
    final personnel = createPersonnel(puuid, auuid: auuid);
    expectResponse(
      await harness.agent.post("/api/operations/$ouuid/personnels", body: personnel),
      201,
      body: null,
    );
    final msg = createMessage('1');
    expectResponse(await harness.agent.post("/api/personnels/$puuid/messages", body: msg), 201, body: null);
  });

  test("GET /api/personnels/{uuid}/messages returns status code 200", () async {
    final puuid = Uuid().v4();
    final auuid = Uuid().v4();
    final ouuid = await _prepare(harness, auuid);
    final personnel = createPersonnel(puuid, auuid: auuid);
    expectResponse(
      await harness.agent.post("/api/operations/$ouuid/personnels", body: personnel),
      201,
      body: null,
    );
    final message1 = createMessage('1');
    expectResponse(await harness.agent.post("/api/personnels/$puuid/messages", body: message1), 201, body: null);
    final msg2 = createMessage('2');
    expectResponse(await harness.agent.post("/api/personnels/$puuid/messages", body: msg2), 201, body: null);
    final response = expectResponse(await harness.agent.get("/api/personnels/$puuid/messages"), 200);
    final actual = await response.body.decode();
    expect(actual['total'], equals(2));
    expect(actual['entries'].length, equals(2));
  });

  test("GET /api/personnels/{uuid}/messages/{id} returns status code 200", () async {
    final puuid = Uuid().v4();
    final auuid = Uuid().v4();
    final ouuid = await _prepare(harness, auuid);
    final personnel = createPersonnel(puuid, auuid: auuid);
    expectResponse(
      await harness.agent.post("/api/operations/$ouuid/personnels", body: personnel),
      201,
      body: null,
    );
    final message1 = createMessage('1');
    expectResponse(await harness.agent.post("/api/personnels/$puuid/messages", body: message1), 201, body: null);
    final response1 = expectResponse(await harness.agent.get("/api/personnels/$puuid/messages/1"), 200);
    final actual1 = await response1.body.decode();
    expect(actual1['data'], equals(message1));
    final msg2 = createMessage('2');
    expectResponse(await harness.agent.post("/api/personnels/$puuid/messages", body: msg2), 201, body: null);
    final response2 = expectResponse(await harness.agent.get("/api/personnels/$puuid/messages/2"), 200);
    final actual2 = await response2.body.decode();
    expect(actual2['data'], equals(msg2));
  });

  test("PATCH /api/personnels/{uuid}/messages/{id} is idempotent", () async {
    final puuid = Uuid().v4();
    final auuid = Uuid().v4();
    final ouuid = await _prepare(harness, auuid);
    final personnel = createPersonnel(puuid, auuid: auuid);
    expectResponse(
      await harness.agent.post("/api/operations/$ouuid/personnels", body: personnel),
      201,
      body: null,
    );
    final msg = createMessage('1');
    expectResponse(await harness.agent.post("/api/personnels/$puuid/messages", body: msg), 201, body: null);
    expectResponse(await harness.agent.execute("PATCH", "/api/personnels/$puuid/messages/1", body: msg), 204,
        body: null);
    final response1 = expectResponse(await harness.agent.get("/api/personnels/$puuid"), 200);
    final actual1 = await response1.body.decode();
    expect((actual1['data'] as Map)['messages'], equals([msg]));
    final response2 = expectResponse(await harness.agent.get("/api/personnels/$puuid/messages/1"), 200);
    final actual2 = await response2.body.decode();
    expect(actual2['data'], equals(msg));
  });

  test("PATCH /api/personnels/{uuid} on entity object lists should not be allowed", () async {
    final puuid = Uuid().v4();
    final auuid = Uuid().v4();
    final ouuid = await _prepare(harness, auuid);
    final personnel = createPersonnel(puuid, auuid: auuid);
    expectResponse(
      await harness.agent.post("/api/operations/$ouuid/personnels", body: personnel),
      201,
      body: null,
    );
    expectResponse(
      await harness.agent.execute("PATCH", "/api/personnels/$puuid", body: {
        "messages": [createMessage('1')],
      }),
      400,
      body: null,
    );
  });

  test("DELETE /api/personnels/{uuid}/messages/{id} returns status code 204", () async {
    final puuid = Uuid().v4();
    final auuid = Uuid().v4();
    final ouuid = await _prepare(harness, auuid);
    final personnel = createPersonnel(puuid, auuid: auuid);
    expectResponse(
      await harness.agent.post("/api/operations/$ouuid/personnels", body: personnel),
      201,
      body: null,
    );
    final msg = createMessage('1');
    expectResponse(await harness.agent.post("/api/personnels/$puuid/messages", body: msg), 201, body: null);
    expectResponse(await harness.agent.delete("/api/personnels/$puuid/messages/1"), 204);
  });
}

Future<String> _prepare(SarSysAppHarness harness, String auuid) async {
  await _createAffiliation(harness, auuid);
  final iuuid = Uuid().v4();
  expectResponse(await harness.agent.post("/api/incidents", body: createIncident(iuuid)), 201);
  final ouuid = Uuid().v4();
  expectResponse(await harness.agent.post("/api/incidents/$iuuid/operations", body: createOperation(ouuid)), 201);
  return ouuid;
}

Future<String> _createAffiliation(SarSysAppHarness harness, String auuid) async {
  final puuid = Uuid().v4();
  expectResponse(await harness.agent.post("/api/persons", body: createPerson(puuid)), 201);
  final orguuid = Uuid().v4();
  expectResponse(await harness.agent.post("/api/organisations", body: createOrganisation(orguuid)), 201);
  expectResponse(
      await harness.agent.post("/api/affiliations",
          body: createAffiliation(
            auuid,
            puuid: puuid,
            orguuid: orguuid,
          )),
      201);
  return auuid;
}
