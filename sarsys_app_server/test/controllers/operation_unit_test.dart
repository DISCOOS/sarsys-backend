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

  test("POST /api/operations/{uuid}/unit adds unit to aggregate list", () async {
    final ouuid = await _prepare(harness);
    final uuuid = Uuid().v4();
    final unit = _createData(uuuid);
    expectResponse(
      await harness.agent.post("/api/operations/$ouuid/units", body: unit),
      201,
      body: null,
    );
    await expectAggregateReference(
      harness,
      uri: '/api/units',
      childUuid: uuuid,
      child: unit,
      parentField: 'operation',
      parentUuid: ouuid,
    );
    await expectAggregateInList(
      harness,
      uri: '/api/operations',
      uuid: ouuid,
      listField: 'units',
      uuids: [
        uuuid,
      ],
    );
  });

  test("GET /api/operations/{uuid}/units returns status code 200 with offset=1 and limit=2", () async {
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

  test("DELETE /api/units/{uuid} should remove {uuid} from units list in operation", () async {
    final ouuid = await _prepare(harness);
    final uuuid = Uuid().v4();
    final body = _createData(uuuid);
    expectResponse(await harness.agent.post("/api/operations/$ouuid/units", body: body), 201, body: null);
    expectResponse(await harness.agent.delete("/api/units/$uuuid"), 204);
    await expectAggregateInList(
      harness,
      uri: '/api/operations',
      uuid: ouuid,
      listField: 'units',
      uuids: [],
    );
  });
}

Future<String> _prepare(SarSysHarness harness) async {
  harness.eventStoreMockServer.withStream(typeOf<Incident>().toColonCase());
  harness.eventStoreMockServer.withStream(typeOf<sar.Operation>().toColonCase());
  harness.eventStoreMockServer.withStream(typeOf<Unit>().toColonCase());
  await harness.channel.manager.get<IncidentRepository>().readyAsync();
  await harness.channel.manager.get<OperationRepository>().readyAsync();
  await harness.channel.manager.get<UnitRepository>().readyAsync();
  final iuuid = Uuid().v4();
  expectResponse(await harness.agent.post("/api/incidents", body: createIncident(iuuid)), 201);
  final ouuid = Uuid().v4();
  expectResponse(await harness.agent.post("/api/incidents/$iuuid/operations", body: createOperation(ouuid)), 201);
  return ouuid;
}

Map<String, Object> _createData(String uuid) => createUnit(uuid);
