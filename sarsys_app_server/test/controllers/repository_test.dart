import 'package:sarsys_domain/sarsys_domain.dart';
import 'package:uuid/uuid.dart';
import 'package:test/test.dart';

import 'harness.dart';

Future main() async {
  final harness = SarSysHarness()
    ..withEventStoreMock()
    ..install(restartForEachTest: true);

  test("GET /api/devices/{type} returns status code 200", () async {
    // Arrange
    final uuid = Uuid().v4();
    final body = createDevice(uuid);
    expectResponse(await harness.agent.post("/api/devices", body: body), 201, body: null);

    final response = await harness.agent.get("/api/repositories/device");
    final data = await response.body.decode();

    expect(data, isNotNull);
    expect(data['queue'], isNull);
    expect(data['snapshot'], isNull);
  });

  test("GET /api/devices/{type}?expand=queue returns status code 200", () async {
    // Arrange
    final uuid = Uuid().v4();
    final body = createDevice(uuid);
    harness.channel.manager.get<DeviceRepository>().save();
    expectResponse(await harness.agent.post("/api/devices", body: body), 201, body: null);

    final response = await harness.agent.get("/api/repositories/device?expand=queue");
    final data = await response.body.decode();

    expect(data['queue'], isNotNull);
  });

  test("GET /api/devices/{type}/{uuid} returns status code 200", () async {
    // Arrange
    final uuid = Uuid().v4();
    final body = createDevice(uuid);
    expectResponse(await harness.agent.post("/api/devices", body: body), 201, body: null);

    final response = await harness.agent.get("/api/repositories/device/$uuid");
    final data = Map<String, dynamic>.from(
      await response.body.decode(),
    );

    expect(data, isNotNull);
    expect(data.hasPath('aggregate/data'), isFalse);
  });

  test("GET /api/devices/{type}/{uuid}?expand=queue,data returns status code 200", () async {
    // Arrange
    final uuid = Uuid().v4();
    final body = createDevice(uuid);
    expectResponse(await harness.agent.post("/api/devices", body: body), 201, body: null);

    final response = await harness.agent.get("/api/repositories/device/$uuid?expand=queue,data");
    final data = Map<String, dynamic>.from(
      await response.body.decode(),
    );

    expect(data['queue'], isNotNull);
    expect(data.hasPath('aggregate/data'), isTrue);
  });

  test("POST /api/devices/{type} returns status code 200 for action 'rebuild'", () async {
    // Arrange
    final uuid = Uuid().v4();
    final body = createDevice(uuid);
    expectResponse(await harness.agent.post("/api/devices", body: body), 201, body: null);

    final response = await harness.agent.post("/api/repositories/device", body: {
      'action': 'rebuild',
    });
    final data = await response.body.decode();

    expect(data, isNotNull);
  });
}
