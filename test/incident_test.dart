import 'package:sarsys_app_server/domain/incident/incident.dart';
import 'package:sarsys_app_server/eventsource/eventsource.dart';
import 'package:uuid/uuid.dart';
import 'package:test/test.dart';

import 'harness/app.dart';

Future main() async {
  final harness = Harness()
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

  test("PATCH /api/incidents/{uuid} on lists supports add, remove and replace", () async {
    harness.eventStoreMockServer.withStream(typeOf<Incident>().toColonCase());
    await harness.channel.manager.get<IncidentRepository>().readyAsync();
    final uuid = Uuid().v4();
    final body = _createData(uuid);
    expectResponse(await harness.agent.post("/api/incidents", body: body), 201, body: null);

    // Test that subjects are added
    var subjects = {
      "subjects": ["string1"],
      "operations": ["string1"]
    };
    expectResponse(await harness.agent.execute("PATCH", "/api/incidents/$uuid", body: subjects), 204, body: null);
    var response = expectResponse(await harness.agent.get("/api/incidents/$uuid"), 200);
    var actual = await response.body.decode();
    body.addAll(subjects);
    expect(actual['data'], equals(body), reason: "List was not appended");

    // Test that subjects are replaced
    subjects = {
      "subjects": ["string2"],
      "operations": ["string2"]
    };
    expectResponse(await harness.agent.execute("PATCH", "/api/incidents/$uuid", body: subjects), 204, body: null);
    response = expectResponse(await harness.agent.get("/api/incidents/$uuid"), 200);
    actual = await response.body.decode();
    body.addAll(subjects);
    expect(actual['data'], equals(body), reason: "List was not replaced");

    // Test that subjects are removed
    subjects = {"subjects": [], "operations": []};
    expectResponse(await harness.agent.execute("PATCH", "/api/incidents/$uuid", body: subjects), 204, body: null);
    response = expectResponse(await harness.agent.get("/api/incidents/$uuid"), 200);
    actual = await response.body.decode();
    body.addAll(subjects);
    expect(actual['data'], equals(body), reason: "List was not cleared");
  });

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

Map<String, Object> _createData(String uuid) => {
      "uuid": "$uuid",
      "name": "string",
      "summary": "string",
      "type": "lost",
      "status": "registered",
      "resolution": "unresolved",
      "occurred": DateTime.now().toIso8601String(),
      "clues": [
        _createClue(0),
      ],
      "subjects": ["string"],
      "operations": ["string"]
    };

Map<String, dynamic> _createClue(int id) => {
      "id": id,
      "name": "string",
      "description": "string",
      "type": "find",
      "quality": "confirmed",
      "location": {
        "position": {
          "type": "Feature",
          "geometry": {
            "type": "Point",
            "coordinates": [0.0, 0.0]
          },
          "properties": {
            "name": "string",
            "description": "string",
            "accuracy": 0,
            "timestamp": DateTime.now().toIso8601String(),
            "type": "manual"
          }
        },
        "address": {"lines": "string", "city": "string", "postalCode": "string", "countryCode": "string"},
        "description": "string"
      }
    };
