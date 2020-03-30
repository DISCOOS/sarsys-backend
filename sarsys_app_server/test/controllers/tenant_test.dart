import 'package:sarsys_app_server/controllers/tenant/app_config.dart';
import 'package:event_source/event_source.dart';
import 'package:sarsys_domain/sarsys_domain.dart';
import 'package:uuid/uuid.dart';
import 'package:test/test.dart';

import 'harness.dart';

Future main() async {
  final harness = SarSysHarness()
    ..withEventStoreMock()
    ..install(restartForEachTest: true);

  test("POST /api/app-configs/ returns status code 201 with empty body", () async {
    harness.eventStoreMockServer.withStream(typeOf<Device>().toColonCase());
    harness.eventStoreMockServer.withStream(typeOf<AppConfig>().toColonCase());
    await harness.channel.manager.get<AppConfigRepository>().readyAsync();
    await harness.channel.manager.get<DeviceRepository>().readyAsync();
    final uuid = Uuid().v4();
    final body = _createData(uuid);
    expectResponse(await harness.agent.post("/api/app-configs", body: body), 201, body: null);

    // Expect Device with same uuid was co-created
    final response = expectResponse(await harness.agent.get("/api/devices/$uuid"), 200);
    final actual = Map.from(await response.body.decode());
    expect(
      actual.elementAt('data'),
      {
        'uuid': uuid,
        'type': 'app',
        'network': 'sarsys',
        'status': 'unavailable',
      },
      reason: 'Expected Device with same uuid was co-created',
    );
  });

  test("GET /api/app-configs/{uuid} returns status code 200", () async {
    harness.eventStoreMockServer.withStream(typeOf<Device>().toColonCase());
    harness.eventStoreMockServer.withStream(typeOf<AppConfig>().toColonCase());
    await harness.channel.manager.get<AppConfigRepository>().readyAsync();
    await harness.channel.manager.get<DeviceRepository>().readyAsync();
    final uuid = Uuid().v4();
    final body = _createData(uuid);
    expectResponse(await harness.agent.post("/api/app-configs", body: body), 201, body: null);
    final response = expectResponse(await harness.agent.get("/api/app-configs/$uuid"), 200);
    final actual = await response.body.decode();
    expect(actual['data'], equals(body));
  });

  test("PATCH /api/app-configs/{uuid} is idempotent", () async {
    harness.eventStoreMockServer.withStream(typeOf<Device>().toColonCase());
    harness.eventStoreMockServer.withStream(typeOf<AppConfig>().toColonCase());
    await harness.channel.manager.get<AppConfigRepository>().readyAsync();
    await harness.channel.manager.get<DeviceRepository>().readyAsync();
    final uuid = Uuid().v4();
    final body = _createData(uuid);
    expectResponse(await harness.agent.post("/api/app-configs", body: body), 201, body: null);
    expectResponse(await harness.agent.execute("PATCH", "/api/app-configs/$uuid", body: body), 204, body: null);
    final response = expectResponse(await harness.agent.get("/api/app-configs/$uuid"), 200);
    final actual = await response.body.decode();
    expect(actual['data'], equals(body));
  });

  test("PATCH /api/app-configs/{uuid} does not remove value objects", () async {
    harness.eventStoreMockServer.withStream(typeOf<Device>().toColonCase());
    harness.eventStoreMockServer.withStream(typeOf<AppConfig>().toColonCase());
    await harness.channel.manager.get<AppConfigRepository>().readyAsync();
    await harness.channel.manager.get<DeviceRepository>().readyAsync();
    final uuid = Uuid().v4();
    final body = _createData(uuid);
    expectResponse(await harness.agent.post("/api/app-configs", body: body), 201, body: null);
    expectResponse(await harness.agent.execute("PATCH", "/api/app-configs/$uuid", body: {}), 204, body: null);
    final response = expectResponse(await harness.agent.get("/api/app-configs/$uuid"), 200);
    final actual = await response.body.decode();
    expect(actual['data'], equals(body));
  });

  test("DELETE /api/app-configs/{uuid} returns status code 204", () async {
    harness.eventStoreMockServer.withStream(typeOf<Device>().toColonCase());
    harness.eventStoreMockServer.withStream(typeOf<AppConfig>().toColonCase());
    await harness.channel.manager.get<AppConfigRepository>().readyAsync();
    final devices = harness.channel.manager.get<DeviceRepository>();
    await devices.readyAsync();
    final uuid = Uuid().v4();
    final body = _createData(uuid);
    expectResponse(await harness.agent.post("/api/app-configs", body: body), 201, body: null);
    expectResponse(await harness.agent.delete("/api/app-configs/$uuid"), 204);

    // Expect Device with same uuid was co-created
    expectResponse(await harness.agent.get("/api/devices/$uuid"), 404);
  }, timeout: const Timeout.factor(100));

  test("GET /api/app-configs returns status code 200 with offset=1 and limit=2", () async {
    harness.eventStoreMockServer.withStream(typeOf<Device>().toColonCase());
    harness.eventStoreMockServer.withStream(typeOf<AppConfig>().toColonCase());
    await harness.channel.manager.get<AppConfigRepository>().readyAsync();
    await harness.channel.manager.get<DeviceRepository>().readyAsync();
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
