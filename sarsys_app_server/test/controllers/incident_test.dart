import 'package:sarsys_domain/sarsys_domain.dart' hide Operation;
import 'package:sarsys_domain/src/operation/operation.dart' as sar;
import 'package:event_source/event_source.dart';
import 'package:uuid/uuid.dart';
import 'package:test/test.dart';

import 'harness.dart';

Future main() async {
  final harness = SarSysHarness()
    ..withEventStoreMock()
    ..install(restartForEachTest: true);

  test("POST /api/incidents/ returns status code 201 with empty body", () async {
    harness.eventStoreMockServer.withStream(typeOf<Incident>().toColonCase());
    await harness.channel.manager.get<IncidentRepository>().readyAsync();
    final uuid = Uuid().v4();
    final body = _createData(uuid);
    expectResponse(await harness.agent.post("/api/incidents", body: body), 201, body: null);
  });

  test("GET /api/incidents/{uuid} returns status code 200", () async {
    harness.eventStoreMockServer.withStream(typeOf<Incident>().toColonCase());
    await harness.channel.manager.get<IncidentRepository>().readyAsync();
    final uuid = Uuid().v4();
    final body = _createData(uuid);
    expectResponse(await harness.agent.post("/api/incidents", body: body), 201, body: null);
    final response = expectResponse(await harness.agent.get("/api/incidents/$uuid"), 200);
    final actual = await response.body.decode();
    expect(actual['data'], equals(body));
  });

  test("PATCH /api/incidents/{uuid} is idempotent", () async {
    harness.eventStoreMockServer.withStream(typeOf<Incident>().toColonCase());
    await harness.channel.manager.get<IncidentRepository>().readyAsync();
    final uuid = Uuid().v4();
    final body = _createData(uuid);
    expectResponse(await harness.agent.post("/api/incidents", body: body), 201, body: null);
    expectResponse(await harness.agent.execute("PATCH", "/api/incidents/$uuid", body: body), 204, body: null);
    final response = expectResponse(await harness.agent.get("/api/incidents/$uuid"), 200);
    final actual = await response.body.decode();
    expect(actual['data'], equals(body));
  });

  test("PATCH /api/incidents/{uuid} does not remove value objects", () async {
    harness.eventStoreMockServer.withStream(typeOf<Incident>().toColonCase());
    await harness.channel.manager.get<IncidentRepository>().readyAsync();
    final uuid = Uuid().v4();
    final body = _createData(uuid);
    expectResponse(await harness.agent.post("/api/incidents", body: body), 201, body: null);
    expectResponse(await harness.agent.execute("PATCH", "/api/incidents/$uuid", body: {}), 204, body: null);
    final response = expectResponse(await harness.agent.get("/api/incidents/$uuid"), 200);
    final actual = await response.body.decode();
    expect(actual['data'], equals(body));
  });

  test("PATCH /api/incidents/{uuid} on value object lists supports add, remove and replace", () async {
    harness.eventStoreMockServer.withStream(typeOf<Incident>().toColonCase());
    await harness.channel.manager.get<IncidentRepository>().readyAsync();
    final uuid = Uuid().v4();
    final body = _createData(uuid);
    expectResponse(await harness.agent.post("/api/incidents", body: body), 201, body: null);

    // Test that value objects are added to lists
    var lists = {
      "subjects": ["string1"],
      "operations": ["string1"]
    };
    expectResponse(await harness.agent.execute("PATCH", "/api/incidents/$uuid", body: lists), 204, body: null);
    var response = expectResponse(await harness.agent.get("/api/incidents/$uuid"), 200);
    var actual = await response.body.decode();
    body.addAll(lists);
    expect(actual['data'], equals(body), reason: "List was not appended");

    // Test that value objects are removed from lists
    lists = {
      "subjects": ["string2"],
      "operations": ["string2"]
    };
    expectResponse(await harness.agent.execute("PATCH", "/api/incidents/$uuid", body: lists), 204, body: null);
    response = expectResponse(await harness.agent.get("/api/incidents/$uuid"), 200);
    actual = await response.body.decode();
    body.addAll(lists);
    expect(actual['data'], equals(body), reason: "List was not replaced");

    // Test that subjects are removed
    lists = {"subjects": [], "operations": []};
    expectResponse(await harness.agent.execute("PATCH", "/api/incidents/$uuid", body: lists), 204, body: null);
    response = expectResponse(await harness.agent.get("/api/incidents/$uuid"), 200);
    actual = await response.body.decode();
    body.addAll(lists);
    expect(actual['data'], equals(body), reason: "List was not cleared");
  });

//  test("Uuids SHOULD BE removed from aggregate lists when foreign aggregates are deleted", () async {
//    harness.eventStoreMockServer.withStream(typeOf<Incident>().toColonCase());
//    harness.eventStoreMockServer.withStream(typeOf<sar.Operation>().toColonCase());
//    harness.eventStoreMockServer.withStream(typeOf<Subject>().toColonCase());
//    await harness.channel.manager.get<IncidentRepository>().readyAsync();
//    await harness.channel.manager.get<SubjectRepository>().readyAsync();
//    await harness.channel.manager.get<OperationRepository>().readyAsync();
//    final uuid = Uuid().v4();
//    final lists = {
//      "subjects": ["s1"],
//      "operations": ["o1"]
//    };
//    final body = _createData(uuid)..addAll(lists);
//
//    // Act
//    expectResponse(await harness.agent.post("/api/subjects", body: createSubject('s1')), 201, body: null);
//    expectResponse(await harness.agent.post("/api/operations", body: createOperation('o1')), 201, body: null);
//    expectResponse(await harness.agent.post("/api/incidents", body: body), 201, body: null);
//    final response1 = expectResponse(await harness.agent.get("/api/incidents/$uuid"), 200, body: null);
//    final actual1 = Map.from(await response1.body.decode());
//    expect(
//      {'subjects': actual1.elementAt('data/subjects'), 'operations': actual1.elementAt('data/operations')},
//      lists,
//    );
//
//    // Test that foreign uuids are removed
//    expectResponse(await harness.agent.delete("/api/subjects/s1"), 204, body: null);
//    expectResponse(await harness.agent.delete("/api/operations/o1"), 204, body: null);
//    final response2 = expectResponse(await harness.agent.get("/api/incidents/$uuid"), 200, body: null);
//    final actual2 = Map.from(await response2.body.decode());
//    expect(
//      {'subjects': actual2.elementAt('data/subjects'), 'operations': actual2.elementAt('data/operations')},
//      {'subjects': [], 'operations': []},
//    );
//  });
//
  test("DELETE /api/incidents/{uuid} returns status code 204", () async {
    harness.eventStoreMockServer.withStream(typeOf<Incident>().toColonCase());
    await harness.channel.manager.get<IncidentRepository>().readyAsync();
    final uuid = Uuid().v4();
    final body = _createData(uuid);
    expectResponse(await harness.agent.post("/api/incidents", body: body), 201, body: null);
    expectResponse(await harness.agent.delete("/api/incidents/$uuid"), 204);
  });

  test("GET /api/incidents returns status code 200 with offset=1 and limit=2", () async {
    harness.eventStoreMockServer.withStream(typeOf<Incident>().toColonCase());
    await harness.channel.manager.get<IncidentRepository>().readyAsync();
    await harness.agent.post("/api/incidents", body: _createData(Uuid().v4()));
    await harness.agent.post("/api/incidents", body: _createData(Uuid().v4()));
    await harness.agent.post("/api/incidents", body: _createData(Uuid().v4()));
    await harness.agent.post("/api/incidents", body: _createData(Uuid().v4()));
    final response = expectResponse(await harness.agent.get("/api/incidents?offset=1&limit=2"), 200);
    final actual = await response.body.decode();
    expect(actual['total'], equals(4));
    expect(actual['offset'], equals(1));
    expect(actual['limit'], equals(2));
    expect(actual['entries'].length, equals(2));
  });
}

Map<String, Object> _createData(String uuid) => createIncident(uuid);
