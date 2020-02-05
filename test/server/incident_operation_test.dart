import 'package:sarsys_app_server/domain/incident/incident.dart';
import 'package:sarsys_app_server/domain/operation/operation.dart' as sar;
import 'package:sarsys_app_server/eventsource/eventsource.dart';
import 'package:uuid/uuid.dart';
import 'package:test/test.dart';

import 'harness.dart';

Future main() async {
  final harness = SarSysHarness()
    ..withEventStoreMock()
    ..install(restartForEachTest: true);

  test("POST /api/incident/{uuid}/operation adds operation to aggregate list", () async {
    await _install(harness);
    final incidentUuid = Uuid().v4();
    final incident = createIncident(incidentUuid);
    expectResponse(await harness.agent.post("/api/incidents", body: incident), 201, body: null);
    final operationUuid = Uuid().v4();
    final operation = _createData(operationUuid);
    expectResponse(
      await harness.agent.post("/api/incidents/$incidentUuid/operations", body: operation),
      201,
      body: null,
    );
    await expectAggregateReference(
      harness,
      uri: '/api/operations',
      childUuid: operationUuid,
      child: operation,
      parentField: 'incident',
      parentUuid: incidentUuid,
    );
    await expectAggregateInList(
      harness,
      uri: '/api/incidents',
      uuid: incidentUuid,
      data: incident,
      listField: 'operations',
      uuids: [
        'string',
        operationUuid,
      ],
    );
  });

  test("GET /api/incident/{uuid}/operations returns status code 200 with offset=1 and limit=2", () async {
    await _install(harness);
    final uuid = Uuid().v4();
    final incident = createIncident(uuid);
    expectResponse(await harness.agent.post("/api/incidents", body: incident), 201, body: null);
    await harness.agent.post("/api/incidents/$uuid/operations", body: _createData(Uuid().v4()));
    await harness.agent.post("/api/incidents/$uuid/operations", body: _createData(Uuid().v4()));
    await harness.agent.post("/api/incidents/$uuid/operations", body: _createData(Uuid().v4()));
    await harness.agent.post("/api/incidents/$uuid/operations", body: _createData(Uuid().v4()));
    final response = expectResponse(await harness.agent.get("/api/operations?offset=1&limit=2"), 200);
    final actual = await response.body.decode();
    expect(actual['total'], equals(4));
    expect(actual['offset'], equals(1));
    expect(actual['limit'], equals(2));
    expect(actual['entries'].length, equals(2));
  });

  test("DELETE /api/operations/{uuid} should remove {uuid} from operations list in incident", () async {
    await _install(harness);
    final incidentUuid = Uuid().v4();
    final incident = createIncident(incidentUuid);
    expectResponse(await harness.agent.post("/api/incidents", body: incident), 201, body: null);
    final operationUuid = Uuid().v4();
    final body = _createData(operationUuid);
    expectResponse(await harness.agent.post("/api/incidents/$incidentUuid/operations", body: body), 201, body: null);
    expectResponse(await harness.agent.delete("/api/operations/$operationUuid"), 204);
    final response = expectResponse(await harness.agent.get("/api/incidents/$incidentUuid"), 200);
    final actual = await response.body.decode();
    expect(actual['data'], equals(incident));
  });
}

Future _install(SarSysHarness harness) async {
  harness.eventStoreMockServer
    ..withStream(typeOf<Incident>().toColonCase())
    ..withStream(typeOf<sar.Operation>().toColonCase());
  await harness.channel.manager.get<IncidentRepository>().readyAsync();
  await harness.channel.manager.get<sar.OperationRepository>().readyAsync();
}

Map<String, Object> _createData(String uuid) => createOperation(uuid);
