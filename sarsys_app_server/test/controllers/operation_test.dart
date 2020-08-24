import 'package:sarsys_domain/sarsys_domain.dart' hide Operation;

import 'package:uuid/uuid.dart';
import 'package:test/test.dart';

import 'harness.dart';

Future main() async {
  final harness = SarSysHarness()
    ..withEventStoreMock()
    ..install(restartForEachTest: true);

  test("POST /api/operations not allowed", () async {
    await _prepare(harness);
    final uuid = Uuid().v4();
    final body = _createData(uuid);
    expectResponse(
      await harness.agent.post("/api/operations/$uuid", body: body),
      405,
    );
  });

  test("POST /api/incidents/{uuid}/operations/ returns status code 201 with empty body", () async {
    final iuuid = await _prepare(harness);
    final uuid = Uuid().v4();
    final body = _createData(uuid);
    expectResponse(await harness.agent.post("/api/incidents/$iuuid/operations", body: body), 201, body: null);
  });

  test("POST /api/incidents/{uuid}/operations/ returns status code 400 when read only fields is given", () async {
    final iuuid = await _prepare(harness);
    final uuid = Uuid().v4();
    final body = _createData(uuid)
      ..addAll({
        'incident': {'uuid': 'string'},
      });
    expectResponse(
      await harness.agent.post("/api/incidents/$iuuid/operations", body: body),
      400,
      body: 'Schema Operation has 1 errors: [/incident: is read only]',
    );
  });

  test("GET /api/operations/{uuid} returns status code 200", () async {
    final iuuid = await _prepare(harness);
    final uuid = Uuid().v4();
    final body = _createData(uuid);
    expectResponse(await harness.agent.post("/api/incidents/$iuuid/operations", body: body), 201, body: null);
    final response = expectResponse(await harness.agent.get("/api/operations/$uuid"), 200);
    final actual = await response.body.decode();
    expect(
      actual['data'],
      equals(body
        ..addAll({
          'incident': {'uuid': iuuid}
        })),
    );
  });

  test("GET /api/operations returns status code 200 with offset=1 and limit=2", () async {
    final iuuid = await _prepare(harness);
    await harness.agent.post("/api/incidents/$iuuid/operations", body: _createData(Uuid().v4()));
    await harness.agent.post("/api/incidents/$iuuid/operations", body: _createData(Uuid().v4()));
    await harness.agent.post("/api/incidents/$iuuid/operations", body: _createData(Uuid().v4()));
    await harness.agent.post("/api/incidents/$iuuid/operations", body: _createData(Uuid().v4()));
    final response = expectResponse(await harness.agent.get("/api/operations?offset=1&limit=2"), 200);
    final actual = await response.body.decode();
    expect(actual['total'], equals(4));
    expect(actual['offset'], equals(1));
    expect(actual['limit'], equals(2));
    expect(actual['entries'].length, equals(2));
  });

  test("PATCH /api/operations/{uuid} is idempotent", () async {
    final iuuid = await _prepare(harness);
    final uuid = Uuid().v4();
    final body = _createData(uuid);
    expectResponse(await harness.agent.post("/api/incidents/$iuuid/operations", body: body), 201, body: null);
    expectResponse(await harness.agent.execute("PATCH", "/api/operations/$uuid", body: body), 204, body: null);
    final response = expectResponse(await harness.agent.get("/api/operations/$uuid"), 200);
    final actual = await response.body.decode();
    expect(
      actual['data'],
      equals(body
        ..addAll({
          'incident': {'uuid': iuuid}
        })),
    );
  });

  test("PATCH /api/operations/{uuid} does not remove value objects", () async {
    final iuuid = await _prepare(harness);
    final uuid = Uuid().v4();
    final body = _createData(uuid);
    expectResponse(await harness.agent.post("/api/incidents/$iuuid/operations", body: body), 201, body: null);
    expectResponse(await harness.agent.execute("PATCH", "/api/operations/$uuid", body: {}), 204, body: null);
    final response = expectResponse(await harness.agent.get("/api/operations/$uuid"), 200);
    final actual = await response.body.decode();
    expect(
      actual['data'],
      equals(body
        ..addAll({
          'incident': {'uuid': iuuid}
        })),
    );
  });

  test("PATCH /api/operations/{uuid} on aggregate lists are not allowed", () async {
    final iuuid = await _prepare(harness);
    final uuid = Uuid().v4();
    final body = _createData(uuid);
    expectResponse(await harness.agent.post("/api/incidents/$iuuid/operations", body: body), 201, body: null);

    // Test that value objects are added to lists
    final lists = {
      "units": ["string1"],
      "missions": ["string1"],
      "personnels": ["string1"],
    };
    expectResponse(await harness.agent.execute("PATCH", "/api/operations/$uuid", body: lists), 400);
  });

  test("DELETE /api/operations/{uuid} returns status code 204", () async {
    final iuuid = await _prepare(harness);
    final uuid = Uuid().v4();
    final body = _createData(uuid);
    expectResponse(await harness.agent.post("/api/incidents/$iuuid/operations", body: body), 201, body: null);
    expectResponse(await harness.agent.delete("/api/operations/$uuid"), 204);
  });
}

Future<String> _prepare(SarSysHarness harness) async {
  final iuuid = Uuid().v4();
  expectResponse(await harness.agent.post("/api/incidents", body: createIncident(iuuid)), 201);
  return iuuid;
}

Map<String, Object> _createData(String uuid) => createOperation(uuid);
