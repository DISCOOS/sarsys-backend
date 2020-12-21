import 'package:uuid/uuid.dart';
import 'package:test/test.dart';

import 'harness.dart';

Future main() async {
  final harness = SarSysHttpHarness()
    ..withEventStoreMock()
    ..install(restartForEachTest: true);

  test("POST /api/divisions not allowed", () async {
    await _prepare(harness);
    final uuid = Uuid().v4();
    final body = _createData(uuid);
    expectResponse(
      await harness.agent.post("/api/divisions/$uuid", body: body),
      405,
    );
  });

  test("POST /api/divisions/ returns status code 405 with empty body", () async {
    await _prepare(harness);
    final uuid = Uuid().v4();
    final body = _createData(uuid);
    expectResponse(await harness.agent.post("/api/divisions", body: body), 405, body: null);
  });

  test("POST /api/organisations/{uuid}/divisions/ returns status code 201 with empty body", () async {
    final orguuid = await _prepare(harness);
    final uuid = Uuid().v4();
    final body = _createData(uuid);
    expectResponse(await harness.agent.post("/api/organisations/$orguuid/divisions", body: body), 201, body: null);
  });

  test("POST /api/organisations/{uuid}/divisions/ returns status code 400 when 'organisation/uuid' is given", () async {
    final orguuid = await _prepare(harness);
    final uuid = Uuid().v4();
    final body = _createData(uuid)
      ..addAll({
        'organisation': {'uuid': 'string'}
      });
    expectResponse(
      await harness.agent.post("/api/organisations/$orguuid/divisions", body: body),
      400,
      body: 'Schema Division has 1 errors: [/organisation: is read only]',
    );
  });

  test("GET /api/organisations/{uuid}/divisions/{uuid} returns status code 200", () async {
    final orguuid = await _prepare(harness);
    final uuid = Uuid().v4();
    final body = _createData(uuid);
    expectResponse(await harness.agent.post("/api/organisations/$orguuid/divisions", body: body), 201, body: null);
    final response = expectResponse(await harness.agent.get("/api/divisions/$uuid"), 200);
    final actual = await response.body.decode();
    expect(
      actual['data'],
      equals(body
        ..addAll({
          'organisation': {'uuid': orguuid}
        })),
    );
  });

  test("GET /api/organisations/{uuid}/divisions returns status code 200 with offset=1 and limit=2", () async {
    final orguuid = await _prepare(harness);
    await harness.agent.post("/api/organisations/$orguuid/divisions", body: _createData(Uuid().v4()));
    await harness.agent.post("/api/organisations/$orguuid/divisions", body: _createData(Uuid().v4()));
    await harness.agent.post("/api/organisations/$orguuid/divisions", body: _createData(Uuid().v4()));
    await harness.agent.post("/api/organisations/$orguuid/divisions", body: _createData(Uuid().v4()));
    final response = expectResponse(await harness.agent.get("/api/divisions?offset=1&limit=2"), 200);
    final actual = await response.body.decode();
    expect(actual['total'], equals(4));
    expect(actual['offset'], equals(1));
    expect(actual['limit'], equals(2));
    expect(actual['entries'].length, equals(2));
  });

  test("PATCH /api/organisations/{uuid}/divisions/{uuid} is idempotent", () async {
    final orguuid = await _prepare(harness);
    final uuid = Uuid().v4();
    final body = _createData(uuid);
    expectResponse(await harness.agent.post("/api/organisations/$orguuid/divisions", body: body), 201, body: null);
    expectResponse(await harness.agent.execute("PATCH", "/api/divisions/$uuid", body: body), 204, body: null);
    final response = expectResponse(await harness.agent.get("/api/divisions/$uuid"), 200);
    final actual = await response.body.decode();
    expect(
      actual['data'],
      equals(body
        ..addAll({
          'organisation': {'uuid': orguuid}
        })),
    );
  });

  test("PATCH /api/organisations/{uuid}/divisions/{uuid} does not remove value objects", () async {
    final orguuid = await _prepare(harness);
    final uuid = Uuid().v4();
    final body = _createData(uuid);
    expectResponse(await harness.agent.post("/api/organisations/$orguuid/divisions", body: body), 201, body: null);
    expectResponse(await harness.agent.execute("PATCH", "/api/divisions/$uuid", body: {}), 204, body: null);
    final response = expectResponse(await harness.agent.get("/api/divisions/$uuid"), 200);
    final actual = await response.body.decode();
    expect(
      actual['data'],
      equals(body
        ..addAll({
          'organisation': {'uuid': orguuid}
        })),
    );
  });

  test("DELETE /api/organisations/{uuid}/divisions/{uuid} returns status code 204", () async {
    final orguuid = await _prepare(harness);
    final uuid = Uuid().v4();
    final body = _createData(uuid);
    expectResponse(await harness.agent.post("/api/organisations/$orguuid/divisions", body: body), 201, body: null);
    expectResponse(await harness.agent.delete("/api/divisions/$uuid"), 204);
  });
}

Future<String> _prepare(SarSysHttpHarness harness) async {
  final orguuid = Uuid().v4();
  expectResponse(await harness.agent.post("/api/organisations", body: createOrganisation(orguuid)), 201);
  return orguuid;
}

Map<String, Object> _createData(String uuid) => createDivision(uuid);
