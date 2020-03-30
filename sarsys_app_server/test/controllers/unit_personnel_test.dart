import 'package:sarsys_domain/sarsys_domain.dart';
import 'package:event_source/event_source.dart';
import 'package:uuid/uuid.dart';
import 'package:test/test.dart';

import 'harness.dart';

Future main() async {
  final harness = SarSysHarness()
    ..withEventStoreMock()
    ..install(restartForEachTest: true);

  test("POST /api/unit/{uuid}/personnel adds personnel to aggregate list", () async {
    await _install(harness);
    final unitUuid = Uuid().v4();
    final unit = createUnit(unitUuid);
    expectResponse(await harness.agent.post("/api/units", body: unit), 201, body: null);
    final personnelUuid = Uuid().v4();
    final personnel = _createData(personnelUuid);
    expectResponse(
      await harness.agent.post("/api/units/$unitUuid/personnels", body: personnel),
      201,
      body: null,
    );
    await expectAggregateReference(
      harness,
      uri: '/api/personnels',
      childUuid: personnelUuid,
      child: personnel,
      parentField: 'unit',
      parentUuid: unitUuid,
    );
    await expectAggregateInList(
      harness,
      uri: '/api/units',
      uuid: unitUuid,
      data: unit,
      listField: 'personnels',
      uuids: [
        'string',
        personnelUuid,
      ],
    );
  });

  test("GET /api/unit/{uuid}/personnels returns status code 200 with offset=1 and limit=2", () async {
    await _install(harness);
    final uuid = Uuid().v4();
    final unit = createUnit(uuid);
    expectResponse(await harness.agent.post("/api/units", body: unit), 201, body: null);
    await harness.agent.post("/api/units/$uuid/personnels", body: _createData(Uuid().v4()));
    await harness.agent.post("/api/units/$uuid/personnels", body: _createData(Uuid().v4()));
    await harness.agent.post("/api/units/$uuid/personnels", body: _createData(Uuid().v4()));
    await harness.agent.post("/api/units/$uuid/personnels", body: _createData(Uuid().v4()));
    final response = expectResponse(await harness.agent.get("/api/personnels?offset=1&limit=2"), 200);
    final actual = await response.body.decode();
    expect(actual['total'], equals(4));
    expect(actual['offset'], equals(1));
    expect(actual['limit'], equals(2));
    expect(actual['entries'].length, equals(2));
  });

  test("DELETE /api/personnels/{uuid} should remove {uuid} from personnels list in unit", () async {
    await _install(harness);
    final unitUuid = Uuid().v4();
    final unit = createUnit(unitUuid);
    expectResponse(await harness.agent.post("/api/units", body: unit), 201, body: null);
    final personnelUuid = Uuid().v4();
    final body = _createData(personnelUuid);
    expectResponse(await harness.agent.post("/api/units/$unitUuid/personnels", body: body), 201, body: null);
    expectResponse(await harness.agent.delete("/api/personnels/$personnelUuid"), 204);
    final response = expectResponse(await harness.agent.get("/api/units/$unitUuid"), 200);
    final actual = await response.body.decode();
    expect(actual['data'], equals(unit));
  });
}

Future _install(SarSysHarness harness) async {
  harness.eventStoreMockServer..withStream(typeOf<Unit>().toColonCase())..withStream(typeOf<Personnel>().toColonCase());
  await harness.channel.manager.get<UnitRepository>().readyAsync();
  await harness.channel.manager.get<PersonnelRepository>().readyAsync();
}

Map<String, Object> _createData(String uuid) => createPersonnel(uuid);
