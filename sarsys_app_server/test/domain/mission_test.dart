import 'package:uuid/uuid.dart';
import 'package:test/test.dart';

import 'package:sarsys_app_server_test/sarsys_app_server_test.dart';

Future main() async {
  final harness = SarSysAppHarness()
    ..withEventStoreMock()
    ..install(restartForEachTest: true);

  test("POST /api/missions not allowed", () async {
    await _prepare(harness);
    final uuid = Uuid().v4();
    final body = _createData(uuid);
    expectResponse(
      await harness.agent.post("/api/missions/$uuid", body: body),
      405,
    );
  });

  test("POST /api/operations/{uuid}/missions/ returns status code 201 with empty body", () async {
    final ouuid = await _prepare(harness);
    final uuid = Uuid().v4();
    final body = _createData(uuid);
    expectResponse(await harness.agent.post("/api/operations/$ouuid/missions", body: body), 201, body: null);
  });

  test("POST /api/operations/{uuid}/missions/ returns status code 400 when 'operation/uuid' is given", () async {
    final ouuid = await _prepare(harness);
    final uuid = Uuid().v4();
    final body = _createData(uuid)
      ..addAll({
        'operation': {'uuid': 'string'}
      });
    expectResponse(
      await harness.agent.post("/api/operations/$ouuid/missions", body: body),
      400,
      body: 'Schema Mission has 1 errors: [/operation: is read only]',
    );
  });

  test("GET /api/missions/{uuid} returns status code 200", () async {
    final ouuid = await _prepare(harness);
    final uuid = Uuid().v4();
    final body = _createData(uuid);
    expectResponse(await harness.agent.post("/api/operations/$ouuid/missions", body: body), 201, body: null);
    final response = expectResponse(await harness.agent.get("/api/missions/$uuid"), 200);
    final actual = await response.body.decode();
    expect(
      actual['data'],
      equals(body
        ..addAll({
          'operation': {'uuid': ouuid}
        })),
    );
  });

  test("GET /api/missions returns status code 200 with offset=1 and limit=2", () async {
    final ouuid = await _prepare(harness);
    await harness.agent.post("/api/operations/$ouuid/missions", body: _createData(Uuid().v4()));
    await harness.agent.post("/api/operations/$ouuid/missions", body: _createData(Uuid().v4()));
    await harness.agent.post("/api/operations/$ouuid/missions", body: _createData(Uuid().v4()));
    await harness.agent.post("/api/operations/$ouuid/missions", body: _createData(Uuid().v4()));
    final response = expectResponse(await harness.agent.get("/api/missions?offset=1&limit=2"), 200);
    final actual = await response.body.decode();
    expect(actual['total'], equals(4));
    expect(actual['offset'], equals(1));
    expect(actual['limit'], equals(2));
    expect(actual['entries'].length, equals(2));
  });

  test("PATCH /api/missions/{uuid} is idempotent", () async {
    final ouuid = await _prepare(harness);
    final uuid = Uuid().v4();
    final body = _createData(uuid);
    expectResponse(await harness.agent.post("/api/operations/$ouuid/missions", body: body), 201, body: null);
    expectResponse(await harness.agent.execute("PATCH", "/api/missions/$uuid", body: body), 204, body: null);
    final response = expectResponse(await harness.agent.get("/api/missions/$uuid"), 200);
    final actual = await response.body.decode();
    expect(
      actual['data'],
      equals(body
        ..addAll({
          'operation': {'uuid': ouuid}
        })),
    );
  });

  test("PATCH /api/missions/{uuid} does not remove value objects", () async {
    final ouuid = await _prepare(harness);
    final uuid = Uuid().v4();
    final body = _createData(uuid);
    expectResponse(await harness.agent.post("/api/operations/$ouuid/missions", body: body), 201, body: null);
    expectResponse(await harness.agent.execute("PATCH", "/api/missions/$uuid", body: {}), 204, body: null);
    final response = expectResponse(await harness.agent.get("/api/missions/$uuid"), 200);
    final actual = await response.body.decode();
    expect(
      actual['data'],
      equals(body
        ..addAll({
          'operation': {'uuid': ouuid}
        })),
    );
  });

  test("DELETE /api/missions/{uuid} returns status code 204", () async {
    final ouuid = await _prepare(harness);
    final uuid = Uuid().v4();
    final body = _createData(uuid);
    expectResponse(await harness.agent.post("/api/operations/$ouuid/missions", body: body), 201, body: null);
    expectResponse(await harness.agent.delete("/api/missions/$uuid"), 204);
  });
}

Future<String> _prepare(SarSysAppHarness harness) async {
  final iuuid = Uuid().v4();
  expectResponse(await harness.agent.post("/api/incidents", body: createIncident(iuuid)), 201);
  final ouuid = Uuid().v4();
  expectResponse(await harness.agent.post("/api/incidents/$iuuid/operations", body: createOperation(ouuid)), 201);
  return ouuid;
}

Map<String, Object> _createData(String uuid) => createMission(uuid);
