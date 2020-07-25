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
        'status': 'available',
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

    // Expect Device with same uuid was co-deleted
    expectResponse(await harness.agent.get("/api/devices/$uuid"), 404);
    final response = expectResponse(await harness.agent.get("/api/devices"), 200);
    final actual = Map.from(await response.body.decode());
    expect(actual.elementAt('total'), 0, reason: 'Expected Device was co-deleted');
  });

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

  test("Multiple POST /api/app-configs/ with same udid does not create multiple devices", () async {
    harness.eventStoreMockServer.withStream(typeOf<Device>().toColonCase());
    harness.eventStoreMockServer.withStream(typeOf<AppConfig>().toColonCase());
    await harness.channel.manager.get<AppConfigRepository>().readyAsync();
    await harness.channel.manager.get<DeviceRepository>().readyAsync();
    final udid = Uuid().v4();
    final uuid1 = Uuid().v4();
    final uuid2 = Uuid().v4();
    final body1 = _createData(uuid1, udid: udid);
    final body2 = _createData(uuid2, udid: udid);
    expectResponse(await harness.agent.post("/api/app-configs", body: body1), 201, body: null);
    expectResponse(await harness.agent.post("/api/app-configs", body: body2), 201, body: null);

    // Expect Device with given udid was co-created
    final response = expectResponse(await harness.agent.get("/api/devices"), 200);
    final actual = Map.from(await response.body.decode());
    expect(actual.elementAt('total'), 1, reason: 'Expected only one Device was co-created');
    expect(
      actual.elementAt('entries/0/data'),
      {
        'uuid': udid,
        'type': 'app',
        'network': 'sarsys',
        'status': 'available',
      },
      reason: 'Expected Device with given uuid was co-created',
    );
  });

  test("Multiple DELETE /api/app-configs/ with same udid does not delete device until last", () async {
    harness.eventStoreMockServer.withStream(typeOf<Device>().toColonCase());
    harness.eventStoreMockServer.withStream(typeOf<AppConfig>().toColonCase());
    await harness.channel.manager.get<AppConfigRepository>().readyAsync();
    await harness.channel.manager.get<DeviceRepository>().readyAsync();
    final udid = Uuid().v4();
    final uuid1 = Uuid().v4();
    final uuid2 = Uuid().v4();
    final body1 = _createData(uuid1, udid: udid);
    final body2 = _createData(uuid2, udid: udid);
    expectResponse(await harness.agent.post("/api/app-configs", body: body1), 201, body: null);
    expectResponse(await harness.agent.post("/api/app-configs", body: body2), 201, body: null);

    // Delete first app-config
    expectResponse(await harness.agent.delete("/api/app-configs/$uuid1"), 204, body: null);

    // Expect device to still exist
    final response1 = expectResponse(await harness.agent.get("/api/devices"), 200);
    final actual1 = Map.from(await response1.body.decode());
    expect(actual1.elementAt('total'), 1, reason: 'Expected only one Device was co-created');
    expect(
      actual1.elementAt('entries/0/data'),
      {
        'uuid': udid,
        'type': 'app',
        'network': 'sarsys',
        'status': 'available',
      },
      reason: 'Expected Device with given uuid was co-created',
    );

    // Delete last app-config
    expectResponse(await harness.agent.delete("/api/app-configs/$uuid2"), 204, body: null);

    // Expect device to be deleted
    final response2 = expectResponse(await harness.agent.get("/api/devices"), 200);
    final actual2 = Map.from(await response2.body.decode());
    expect(actual2.elementAt('total'), 0, reason: 'Expected only Device was co-deleted');
  });
}

Map<String, Object> _createData(String uuid, {String udid}) => {
      "uuid": "$uuid",
      "udid": "${udid ?? uuid}",
      "demo": true,
      "demoRole": "commander",
      "onboarded": true,
      "firstSetup": true,
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
      "sentryDns": "https://sentry",
      "securityType": "pin",
      "securityMode": "personal",
      "securityLockAfter": 2700,
    };
