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

  test("POST /api/operations/{uuid}/units/ returns status code 201 with empty body", () async {
    final ouuid = await _prepare(harness);
    final uuid = Uuid().v4();
    final body = _createData(uuid);
    expectResponse(await harness.agent.post("/api/operations/$ouuid/units", body: body), 201, body: null);
  });

  test("POST /api/operations/{uuid}/units/ returns status code 201 with tracking enabled", () async {
    final ouuid = await _prepare(harness);
    final uuid = Uuid().v4();
    final tuuid = Uuid().v4();
    final body = _createData(uuid, tuuid: tuuid);
    expectResponse(await harness.agent.post("/api/operations/$ouuid/units", body: body), 201, body: null);
  });

  test("POST /api/operations/{uuid}units/ returns status code 400 when 'operation/uuid' is given", () async {
    final ouuid = await _prepare(harness);
    final uuid = Uuid().v4();
    final body = _createData(uuid)
      ..addAll({
        'operation': {'uuid': 'string'}
      });
    expectResponse(
      await harness.agent.post("/api/operations/$ouuid/units", body: body),
      400,
      body: 'Schema Unit has 1 errors: [/operation: is read only]',
    );
  });

  test("GET /api/units/{uuid} returns status code 200", () async {
    final ouuid = await _prepare(harness);
    final uuid = Uuid().v4();
    final body = _createData(uuid);
    expectResponse(await harness.agent.post("/api/operations/$ouuid/units", body: body), 201, body: null);
    final response = expectResponse(await harness.agent.get("/api/units/$uuid"), 200);
    final actual = await response.body.decode();
    expect(
      actual['data'],
      equals(body
        ..addAll({
          'operation': {'uuid': ouuid}
        })),
    );
  });

  test("GET /api/units returns status code 200 with offset=1 and limit=2", () async {
    final ouuid = await _prepare(harness);
    await harness.agent.post("/api/operations/$ouuid/units", body: _createData(Uuid().v4()));
    await harness.agent.post("/api/operations/$ouuid/units", body: _createData(Uuid().v4()));
    await harness.agent.post("/api/operations/$ouuid/units", body: _createData(Uuid().v4()));
    await harness.agent.post("/api/operations/$ouuid/units", body: _createData(Uuid().v4()));
    final response = expectResponse(await harness.agent.get("/api/units?offset=1&limit=2"), 200);
    final actual = await response.body.decode();
    expect(actual['total'], equals(4));
    expect(actual['offset'], equals(1));
    expect(actual['limit'], equals(2));
    expect(actual['entries'].length, equals(2));
  });

  test("PATCH /api/units/{uuid} is idempotent", () async {
    final ouuid = await _prepare(harness);
    final uuid = Uuid().v4();
    final body = _createData(uuid);
    expectResponse(await harness.agent.post("/api/operations/$ouuid/units", body: body), 201, body: null);
    expectResponse(await harness.agent.execute("PATCH", "/api/units/$uuid", body: body), 204, body: null);
    final response = expectResponse(await harness.agent.get("/api/units/$uuid"), 200);
    final actual = await response.body.decode();
    expect(
      actual['data'],
      equals(body
        ..addAll({
          'operation': {'uuid': ouuid}
        })),
    );
  });

  test("PATCH /api/units/{uuid} does not remove value objects", () async {
    final ouuid = await _prepare(harness);
    final uuid = Uuid().v4();
    final body = _createData(uuid);
    expectResponse(await harness.agent.post("/api/operations/$ouuid/units", body: body), 201, body: null);
    expectResponse(await harness.agent.execute("PATCH", "/api/units/$uuid", body: {}), 204, body: null);
    final response = expectResponse(await harness.agent.get("/api/units/$uuid"), 200);
    final actual = await response.body.decode();
    expect(
      actual['data'],
      equals(body
        ..addAll({
          'operation': {'uuid': ouuid}
        })),
    );
  });

  test("DELETE /api/units/{uuid} returns status code 204", () async {
    final ouuid = await _prepare(harness);
    final uuid = Uuid().v4();
    final body = _createData(uuid);
    expectResponse(await harness.agent.post("/api/operations/$ouuid/units", body: body), 201, body: null);
    expectResponse(await harness.agent.delete("/api/units/$uuid"), 204);
  });

  test("DELETE /api/units/{uuid} returns status code 204 with tracking enabled", () async {
    final ouuid = await _prepare(harness);
    final uuid = Uuid().v4();
    final tuuid = Uuid().v4();
    final body = _createData(uuid, tuuid: tuuid);
    expectResponse(await harness.agent.post("/api/operations/$ouuid/units", body: body), 201, body: null);
    expectResponse(await harness.agent.delete("/api/units/$uuid"), 204);
  });
}

Future<String> _prepare(SarSysHarness harness) async {
  harness.eventStoreMockServer.withStream(typeOf<Incident>().toColonCase());
  harness.eventStoreMockServer.withStream(typeOf<sar.Operation>().toColonCase());
  harness.eventStoreMockServer.withStream(typeOf<Unit>().toColonCase());
  harness.eventStoreMockServer.withStream(typeOf<Tracking>().toColonCase());
  await harness.channel.manager.get<IncidentRepository>().readyAsync();
  await harness.channel.manager.get<OperationRepository>().readyAsync();
  await harness.channel.manager.get<UnitRepository>().readyAsync();
  await harness.channel.manager.get<TrackingRepository>().readyAsync();
  final iuuid = Uuid().v4();
  expectResponse(await harness.agent.post("/api/incidents", body: createIncident(iuuid)), 201);
  final ouuid = Uuid().v4();
  expectResponse(await harness.agent.post("/api/incidents/$iuuid/operations", body: createOperation(ouuid)), 201);
  return ouuid;
}

Map<String, Object> _createData(String uuid, {String tuuid}) => createUnit(uuid, tuuid: tuuid);
