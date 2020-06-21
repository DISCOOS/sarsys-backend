import 'package:sarsys_domain/sarsys_domain.dart';
import 'package:event_source/event_source.dart';
import 'package:uuid/uuid.dart';
import 'package:test/test.dart';

import 'harness.dart';

Future main() async {
  final harness = SarSysHarness()
    ..withEventStoreMock()
    ..install(restartForEachTest: true);

  test("POST /api/departments not allowed", () async {
    await _prepare(harness);
    final uuid = Uuid().v4();
    final department = _createData(uuid);
    expectResponse(
      await harness.agent.post("/api/departments/$uuid", body: department),
      405,
    );
  });

  test("POST /api/divisions/{uuid}/departments/ returns status code 201 with empty body", () async {
    final divuuid = await _prepare(harness);
    final depuuid = Uuid().v4();
    final body = _createData(depuuid);
    expectResponse(await harness.agent.post("/api/divisions/$divuuid/departments", body: body), 201, body: null);
  });

  test("POST /api/divisions/{uuid}/departments/ returns status code 400 when 'division/uuid' is given", () async {
    final divuuid = await _prepare(harness);
    final uuid = Uuid().v4();
    final body = _createData(uuid)
      ..addAll({
        'division': {'uuid': 'string'}
      });
    expectResponse(
      await harness.agent.post("/api/divisions/$divuuid/departments", body: body),
      400,
      body: 'Schema Department has 1 errors: [/division: is read only]',
    );
  });

  test("GET /api/divisions/uuid/departments/{uuid} returns status code 200", () async {
    final divuuid = await _prepare(harness);
    final uuid = Uuid().v4();
    final body = _createData(uuid);
    expectResponse(await harness.agent.post("/api/divisions/$divuuid/departments", body: body), 201, body: null);
    final response = expectResponse(await harness.agent.get("/api/departments/$uuid"), 200);
    final actual = await response.body.decode();

    expect(
        actual['data'],
        equals(body
          ..addAll({
            'division': {'uuid': divuuid}
          })));
  });

  test("GET /api/departments returns status code 200 with offset=1 and limit=2", () async {
    final divuuid = await _prepare(harness);
    await harness.agent.post("/api/divisions/$divuuid/departments", body: _createData(Uuid().v4()));
    await harness.agent.post("/api/divisions/$divuuid/departments", body: _createData(Uuid().v4()));
    await harness.agent.post("/api/divisions/$divuuid/departments", body: _createData(Uuid().v4()));
    await harness.agent.post("/api/divisions/$divuuid/departments", body: _createData(Uuid().v4()));
    final response = expectResponse(await harness.agent.get("/api/departments?offset=1&limit=2"), 200);
    final actual = await response.body.decode();
    expect(actual['total'], equals(4));
    expect(actual['offset'], equals(1));
    expect(actual['limit'], equals(2));
    expect(actual['entries'].length, equals(2));
  });

  test("PATCH /api/departments/{uuid} is idempotent", () async {
    final divuuid = await _prepare(harness);
    final uuid = Uuid().v4();
    final body = _createData(uuid);
    expectResponse(await harness.agent.post("/api/divisions/$divuuid/departments", body: body), 201, body: null);
    expectResponse(await harness.agent.execute("PATCH", "/api/departments/$uuid", body: body), 204, body: null);
    final response = expectResponse(await harness.agent.get("/api/departments/$uuid"), 200);
    final actual = await response.body.decode();
    expect(
        actual['data'],
        equals(body
          ..addAll({
            'division': {'uuid': divuuid}
          })));
  });

  test("PATCH /api/departments/{uuid} does not remove value objects", () async {
    final divuuid = await _prepare(harness);
    final uuid = Uuid().v4();
    final body = _createData(uuid);
    expectResponse(await harness.agent.post("/api/divisions/$divuuid/departments", body: body), 201, body: null);
    expectResponse(await harness.agent.execute("PATCH", "/api/departments/$uuid", body: {}), 204, body: null);
    final response = expectResponse(await harness.agent.get("/api/departments/$uuid"), 200);
    final actual = await response.body.decode();
    expect(
        actual['data'],
        equals(body
          ..addAll({
            'division': {'uuid': divuuid}
          })));
  });

  test("DELETE /api/departments/{uuid} returns status code 204", () async {
    final divuuid = await _prepare(harness);
    final uuid = Uuid().v4();
    final body = _createData(uuid);
    expectResponse(await harness.agent.post("/api/divisions/$divuuid/departments", body: body), 201, body: null);
    expectResponse(await harness.agent.delete("/api/departments/$uuid"), 204);
  });
}

Future<String> _prepare(SarSysHarness harness) async {
  harness.eventStoreMockServer.withStream(typeOf<Organisation>().toColonCase());
  harness.eventStoreMockServer.withStream(typeOf<Division>().toColonCase());
  harness.eventStoreMockServer.withStream(typeOf<Department>().toColonCase());
  await harness.channel.manager.get<OrganisationRepository>().readyAsync();
  await harness.channel.manager.get<DivisionRepository>().readyAsync();
  await harness.channel.manager.get<DepartmentRepository>().readyAsync();
  final orguuid = Uuid().v4();
  final divuuid = Uuid().v4();
  expectResponse(await harness.agent.post("/api/organisations", body: createOrganisation(orguuid)), 201);
  expectResponse(await harness.agent.post("/api/organisations/$orguuid/divisions", body: createDivision(divuuid)), 201);
  return divuuid;
}

Map<String, Object> _createData(String uuid) => createDepartment(uuid);
