import 'package:sarsys_domain/sarsys_domain.dart';
import 'package:event_source/event_source.dart';
import 'package:uuid/uuid.dart';
import 'package:test/test.dart';

import 'harness.dart';

Future main() async {
  final harness = SarSysHarness()
    ..withEventStoreMock()
    ..install(restartForEachTest: true);

  test("POST /api/persons/ returns status code 201 with empty body", () async {
    await _prepare(harness);
    final uuid = Uuid().v4();
    final body = _createData(uuid);
    expectResponse(await harness.agent.post("/api/persons", body: body), 201, body: null);
  });

  test("POST /api/persons/ returns status code 409 on duplicate userId", () async {
    await _prepare(harness);
    final uuid = Uuid().v4();
    final body = _createData(uuid, userId: '1234');
    expectResponse(await harness.agent.post("/api/persons", body: body), 201, body: null);
    final response = expectResponse(
      await harness.agent.post("/api/persons", body: Map.from(body)..addAll({'uuid': Uuid().v4()})),
      409,
    );
    final conflict = await response.body.decode() as Map<String, dynamic>;
    expect(conflict.elementAt('type'), 'exists');
    expect(conflict.elementAt('base'), equals(body));
  });

  test("GET /api/persons/{uuid} returns status code 200", () async {
    await _prepare(harness);
    final uuid = Uuid().v4();
    final body = _createData(uuid);
    expectResponse(await harness.agent.post("/api/persons", body: body), 201, body: null);
    final response = expectResponse(await harness.agent.get("/api/persons/$uuid"), 200);
    final actual = await response.body.decode();
    expect(actual['data'], equals(body));
  });

  test("PATCH /api/persons/{uuid} is idempotent", () async {
    await _prepare(harness);
    final uuid = Uuid().v4();
    final body = _createData(uuid);
    expectResponse(await harness.agent.post("/api/persons", body: body), 201, body: null);
    expectResponse(await harness.agent.execute("PATCH", "/api/persons/$uuid", body: body), 204, body: null);
    final response = expectResponse(await harness.agent.get("/api/persons/$uuid"), 200);
    final actual = await response.body.decode();
    expect(actual['data'], equals(body));
  });

  test("PATCH /api/persons/{uuid} does not remove value objects", () async {
    await _prepare(harness);
    final uuid = Uuid().v4();
    final body = _createData(uuid);
    expectResponse(await harness.agent.post("/api/persons", body: body), 201, body: null);
    expectResponse(await harness.agent.execute("PATCH", "/api/persons/$uuid", body: {}), 204, body: null);
    final response = expectResponse(await harness.agent.get("/api/persons/$uuid"), 200);
    final actual = await response.body.decode();
    expect(actual['data'], equals(body));
  });

  test("DELETE /api/persons/{uuid} returns status code 204", () async {
    await _prepare(harness);
    final uuid = Uuid().v4();
    final body = _createData(uuid);
    expectResponse(await harness.agent.post("/api/persons", body: body), 201, body: null);
    expectResponse(await harness.agent.delete("/api/persons/$uuid"), 204);
  });

  test("GET /api/persons returns status code 200 with offset=1 and limit=2", () async {
    await _prepare(harness);
    await harness.agent.post("/api/persons", body: _createData(Uuid().v4()));
    await harness.agent.post("/api/persons", body: _createData(Uuid().v4()));
    await harness.agent.post("/api/persons", body: _createData(Uuid().v4()));
    await harness.agent.post("/api/persons", body: _createData(Uuid().v4()));
    final response = expectResponse(await harness.agent.get("/api/persons?offset=1&limit=2"), 200);
    final actual = await response.body.decode();
    expect(actual['total'], equals(4));
    expect(actual['offset'], equals(1));
    expect(actual['limit'], equals(2));
    expect(actual['entries'].length, equals(2));
  });
}

Future _prepare(SarSysHarness harness) async {
  await harness.channel.manager.get<PersonRepository>().readyAsync();
}

Map<String, Object> _createData(String uuid, {String userId}) => createPerson(uuid, userId: userId);
