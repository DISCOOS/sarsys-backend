import 'package:uuid/uuid.dart';
import 'package:test/test.dart';

import 'harness.dart';

Future main() async {
  final harness = SarSysHttpHarness()
    ..withEventStoreMock()
    ..install(restartForEachTest: true);

  test("POST /api/incident/{uuid}/subject adds subject to aggregate list", () async {
    final iuuid = await _prepare(harness);
    final subjectUuid = Uuid().v4();
    final subject = _createData(subjectUuid);
    expectResponse(
      await harness.agent.post("/api/incidents/$iuuid/subjects", body: subject),
      201,
      body: null,
    );
    await expectAggregateReference(
      harness,
      uri: '/api/subjects',
      childUuid: subjectUuid,
      child: subject,
      parentField: 'incident',
      parentUuid: iuuid,
    );
    await expectAggregateInList(
      harness,
      uri: '/api/incidents',
      uuid: iuuid,
      listField: 'subjects',
      uuids: [
        subjectUuid,
      ],
    );
  });

  test("GET /api/incident/{uuid}/subjects returns status code 200 with offset=1 and limit=2", () async {
    final iuuid = Uuid().v4();
    final incident = createIncident(iuuid);
    expectResponse(await harness.agent.post("/api/incidents", body: incident), 201, body: null);
    await harness.agent.post("/api/incidents/$iuuid/subjects", body: _createData(Uuid().v4()));
    await harness.agent.post("/api/incidents/$iuuid/subjects", body: _createData(Uuid().v4()));
    await harness.agent.post("/api/incidents/$iuuid/subjects", body: _createData(Uuid().v4()));
    await harness.agent.post("/api/incidents/$iuuid/subjects", body: _createData(Uuid().v4()));
    final response = expectResponse(await harness.agent.get("/api/incidents/$iuuid/subjects?offset=1&limit=2"), 200);
    final actual = await response.body.decode();
    expect(actual['total'], equals(4));
    expect(actual['offset'], equals(1));
    expect(actual['limit'], equals(2));
    expect(actual['entries'].length, equals(2));
  });

  test("DELETE /api/subjects/{uuid} should remove {uuid} from subjects list in incident", () async {
    final iuuid = Uuid().v4();
    final incident = createIncident(iuuid);
    expectResponse(await harness.agent.post("/api/incidents", body: incident), 201, body: null);
    final suuid = Uuid().v4();
    final subject = _createData(suuid);
    expectResponse(await harness.agent.post("/api/incidents/$iuuid/subjects", body: subject), 201, body: null);
    expectResponse(await harness.agent.delete("/api/subjects/$suuid"), 204);
    final response = expectResponse(await harness.agent.get("/api/incidents/$iuuid"), 200);
    final actual = await response.body.decode();
    expect(
      actual['data'],
      equals(incident..addAll({'subjects': []})),
    );
  });
}

Future<String> _prepare(SarSysHttpHarness harness) async {
  final iuuid = Uuid().v4();
  final incident = createIncident(iuuid);
  expectResponse(await harness.agent.post("/api/incidents", body: incident), 201, body: null);
  return iuuid;
}

Map<String, Object> _createData(String uuid) => createSubject(uuid);
