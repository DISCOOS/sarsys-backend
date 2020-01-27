import 'package:sarsys_app_server/domain/tenant/app_config.dart';
import 'package:sarsys_app_server/eventsource/eventsource.dart';
import 'package:uuid/uuid.dart';
import 'package:test/test.dart';

import 'harness.dart';

Future main() async {
  final harness = Harness()
    ..withEventStoreMock()
    ..install(restartForEachTest: true);

  test("POST /api/app-configs/ returns status code 201 with empty body", () async {
    harness.eventStoreMockServer.withStream(typeOf<AppConfig>().toColonCase());
    await harness.channel.manager.get<AppConfigRepository>().readyAsync();
    final uuid = Uuid().v4();
    final body = _createData(uuid);
    expectResponse(await harness.agent.post("/api/app-configs", body: body), 201, body: null);
  });

  test("GET /api/app-configs/{uuid} returns status code 200", () async {
    harness.eventStoreMockServer.withStream(typeOf<AppConfig>().toColonCase());
    await harness.channel.manager.get<AppConfigRepository>().readyAsync();
    final uuid = Uuid().v4();
    final body = _createData(uuid);
    expectResponse(await harness.agent.post("/api/app-configs", body: body), 201, body: null);
    final response = expectResponse(await harness.agent.get("/api/app-configs/$uuid"), 200);
    final actual = await response.body.decode();
    expect(actual['data'], equals(body));
  });

  test("PATCH /api/app-configs/{uuid} is idempotent", () async {
    harness.eventStoreMockServer.withStream(typeOf<AppConfig>().toColonCase());
    await harness.channel.manager.get<AppConfigRepository>().readyAsync();
    final uuid = Uuid().v4();
    final body = _createData(uuid);
    expectResponse(await harness.agent.post("/api/app-configs", body: body), 201, body: null);
    expectResponse(await harness.agent.execute("PATCH", "/api/app-configs/$uuid", body: body), 204, body: null);
    final response = expectResponse(await harness.agent.get("/api/app-configs/$uuid"), 200);
    final actual = await response.body.decode();
    expect(actual['data'], equals(body));
  });

  test("PATCH /api/app-configs/{uuid} does not remove value objects", () async {
    harness.eventStoreMockServer.withStream(typeOf<AppConfig>().toColonCase());
    await harness.channel.manager.get<AppConfigRepository>().readyAsync();
    final uuid = Uuid().v4();
    final body = _createData(uuid);
    expectResponse(await harness.agent.post("/api/app-configs", body: body), 201, body: null);
    expectResponse(await harness.agent.execute("PATCH", "/api/app-configs/$uuid", body: {}), 204, body: null);
    final response = expectResponse(await harness.agent.get("/api/app-configs/$uuid"), 200);
    final actual = await response.body.decode();
    expect(actual['data'], equals(body));
  });

  test("DELETE /api/app-configs/{uuid} returns status code 204", () async {
    harness.eventStoreMockServer.withStream(typeOf<AppConfig>().toColonCase());
    await harness.channel.manager.get<AppConfigRepository>().readyAsync();
    final uuid = Uuid().v4();
    final body = _createData(uuid);
    expectResponse(await harness.agent.post("/api/app-configs", body: body), 201, body: null);
    expectResponse(await harness.agent.delete("/api/app-configs/$uuid"), 204);
  });

  test("GET /api/app-configs returns status code 200 with offset=1 and limit=2", () async {
    harness.eventStoreMockServer.withStream(typeOf<AppConfig>().toColonCase());
    await harness.channel.manager.get<AppConfigRepository>().readyAsync();
    await harness.agent.post("/api/app-configs", body: _createData(Uuid().v4()));
    await harness.agent.post("/api/app-configs", body: _createData(Uuid().v4()));
    await harness.agent.post("/api/app-configs", body: _createData(Uuid().v4()));
    await harness.agent.post("/api/app-configs", body: _createData(Uuid().v4()));
    final response = expectResponse(await harness.agent.get("/api/app-configs?offset=1&limit=2"), 200);
    final actual = await response.body.decode();
    expect(actual['total'], equals(4));
    expect(actual['offset'], equals(1));
    expect(actual['limit'], equals(2));
    expect(actual['entries'].length, equals(2));
  });
}

Map<String, Object> _createData(String uuid) => {
      "uuid": "$uuid",
      "demo": true,
      "demoRole": "commander",
      "onboarding": true,
      "organization": "string",
      "division": "string",
      "department": "string",
      "talkGroupCatalog": "string",
      "storage": false,
      "locationWhenInUse": false,
      "mapCacheTTL": 0,
      "mapCacheCapacity": 0,
      "locationAccuracy": "high",
      "locationFastestInterval": 0,
      "locationSmallestDisplacement": 0,
      "keepScreenOn": false,
      "callsignReuse": true,
      "sentryDns": "https://sentry"
    };
