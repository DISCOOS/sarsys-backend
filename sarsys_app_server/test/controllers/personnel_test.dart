import 'package:sarsys_domain/sarsys_domain.dart';
import 'package:event_source/event_source.dart';
import 'package:uuid/uuid.dart';
import 'package:test/test.dart';

import 'harness.dart';

Future main() async {
  final harness = SarSysHarness()
    ..withEventStoreMock()
    ..install(restartForEachTest: true);

  test("POST /api/personnels/ returns status code 201 with empty body", () async {
    harness.eventStoreMockServer.withStream(typeOf<Personnel>().toColonCase());
    await harness.channel.manager.get<PersonnelRepository>().readyAsync();
    final uuid = Uuid().v4();
    final body = _createData(uuid);
    expectResponse(await harness.agent.post("/api/personnels", body: body), 201, body: null);
  });

  test("POST /api/personnels/ returns status code 400 when 'incident/uuid' is given", () async {
    harness.eventStoreMockServer.withStream(typeOf<Personnel>().toColonCase());
    await harness.channel.manager.get<PersonnelRepository>().readyAsync();
    final uuid = Uuid().v4();
    final body = _createData(uuid)
      ..addAll({
        'operation': {'uuid': 'string'}
      });
    expectResponse(
      await harness.agent.post("/api/personnels", body: body),
      400,
      body: 'Schema Personnel has 1 errors: [/operation: is read only]',
    );
  });

  test("GET /api/personnels/{uuid} returns status code 200", () async {
    harness.eventStoreMockServer.withStream(typeOf<Personnel>().toColonCase());
    await harness.channel.manager.get<PersonnelRepository>().readyAsync();
    final uuid = Uuid().v4();
    final body = _createData(uuid);
    expectResponse(await harness.agent.post("/api/personnels", body: body), 201, body: null);
    final response = expectResponse(await harness.agent.get("/api/personnels/$uuid"), 200);
    final actual = await response.body.decode();
    expect(actual['data'], equals(body));
  });

  test("PATCH /api/personnels/{uuid} is idempotent", () async {
    harness.eventStoreMockServer.withStream(typeOf<Personnel>().toColonCase());
    await harness.channel.manager.get<PersonnelRepository>().readyAsync();
    final uuid = Uuid().v4();
    final body = _createData(uuid);
    expectResponse(await harness.agent.post("/api/personnels", body: body), 201, body: null);
    expectResponse(await harness.agent.execute("PATCH", "/api/personnels/$uuid", body: body), 204, body: null);
    final response = expectResponse(await harness.agent.get("/api/personnels/$uuid"), 200);
    final actual = await response.body.decode();
    expect(actual['data'], equals(body));
  });

  test("PATCH /api/personnels/{uuid} does not remove value objects", () async {
    harness.eventStoreMockServer.withStream(typeOf<Personnel>().toColonCase());
    await harness.channel.manager.get<PersonnelRepository>().readyAsync();
    final uuid = Uuid().v4();
    final body = _createData(uuid);
    expectResponse(await harness.agent.post("/api/personnels", body: body), 201, body: null);
    expectResponse(await harness.agent.execute("PATCH", "/api/personnels/$uuid", body: {}), 204, body: null);
    final response = expectResponse(await harness.agent.get("/api/personnels/$uuid"), 200);
    final actual = await response.body.decode();
    expect(actual['data'], equals(body));
  });

  test("DELETE /api/personnels/{uuid} returns status code 204", () async {
    harness.eventStoreMockServer.withStream(typeOf<Personnel>().toColonCase());
    await harness.channel.manager.get<PersonnelRepository>().readyAsync();
    final uuid = Uuid().v4();
    final body = _createData(uuid);
    expectResponse(await harness.agent.post("/api/personnels", body: body), 201, body: null);
    expectResponse(await harness.agent.delete("/api/personnels/$uuid"), 204);
  });

  test("GET /api/personnels returns status code 200 with offset=1 and limit=2", () async {
    harness.eventStoreMockServer.withStream(typeOf<Personnel>().toColonCase());
    await harness.channel.manager.get<PersonnelRepository>().readyAsync();
    await harness.agent.post("/api/personnels", body: _createData(Uuid().v4()));
    await harness.agent.post("/api/personnels", body: _createData(Uuid().v4()));
    await harness.agent.post("/api/personnels", body: _createData(Uuid().v4()));
    await harness.agent.post("/api/personnels", body: _createData(Uuid().v4()));
    final response = expectResponse(await harness.agent.get("/api/personnels?offset=1&limit=2"), 200);
    final actual = await response.body.decode();
    expect(actual['total'], equals(4));
    expect(actual['offset'], equals(1));
    expect(actual['limit'], equals(2));
    expect(actual['entries'].length, equals(2));
  });
}

Map<String, Object> _createData(String uuid) => createPersonnel(uuid);
