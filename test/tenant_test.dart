import 'package:sarsys_app_server/domain/tenant/app_config.dart';
import 'package:sarsys_app_server/eventsource/eventsource.dart';
import 'package:uuid/uuid.dart';
import 'package:test/test.dart';

import 'harness/app.dart';

Future main() async {
  final harness = Harness()
    ..withEventStoreMock()
    ..install(restartForEachTest: true);

  test("GET /api/app-configs returns status code 200 with empty body", () async {
    harness.eventStoreMockServer.withStream(typeOf<AppConfig>().toColonCase());
    await harness.channel.manager.get<AppConfigRepository>().readyAsync();
    expectResponse(
      await harness.agent.get("/api/app-configs"),
      200,
      body: {'total': 0, 'offset': 0, 'limit': 20, 'entries': []},
    );
  });

  test("POST /api/app-configs/ returns status code 201 with empty body", () async {
    harness.eventStoreMockServer.withStream(typeOf<AppConfig>().toColonCase());
    await harness.channel.manager.get<AppConfigRepository>().readyAsync();
    final uuid = Uuid().v4();
    final body = _appConfig(uuid);
    expectResponse(await harness.agent.post("/api/app-configs", body: body), 201, body: null);
  });

  test("GET /api/app-configs/{uuid} returns status code 200", () async {
    harness.eventStoreMockServer.withStream(typeOf<AppConfig>().toColonCase());
    await harness.channel.manager.get<AppConfigRepository>().readyAsync();
    final uuid = Uuid().v4();
    final body = _appConfig(uuid);
    expectResponse(await harness.agent.post("/api/app-configs", body: body), 201, body: null);
    final response = expectResponse(await harness.agent.get("/api/app-configs/$uuid"), 200);
    final actual = await response.body.decode();
    expect(actual['data'], equals(body));
  });

  test("DELETE /api/app-configs/{uuid} returns status code 204", () async {
    harness.eventStoreMockServer.withStream(typeOf<AppConfig>().toColonCase());
    await harness.channel.manager.get<AppConfigRepository>().readyAsync();
    final uuid = Uuid().v4();
    final body = _appConfig(uuid);
    expectResponse(await harness.agent.post("/api/app-configs", body: body), 201, body: null);
    expectResponse(await harness.agent.delete("/api/app-configs/$uuid"), 204);
  });

  test("GET /api/app-configs returns status code 200 with 0 app-config in entries", () async {
    harness.eventStoreMockServer.withStream(typeOf<AppConfig>().toColonCase());
    await harness.channel.manager.get<AppConfigRepository>().readyAsync();
    expectResponse(
      await harness.agent.get("/api/app-configs"),
      200,
      body: {'total': 0, 'offset': 0, 'limit': 20, 'entries': []},
    );
  });
}

Map<String, Object> _appConfig(String uuid) => {
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
