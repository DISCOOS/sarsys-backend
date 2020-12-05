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
  });

  test("GET /api/devices/{type}/{uuid} returns status code 200", () async {
    // Arrange
    final uuid = Uuid().v4();
    final body = createDevice(uuid);
    expectResponse(await harness.agent.post("/api/devices", body: body), 201, body: null);

    final response = await harness.agent.get("/api/repositories/device/$uuid");
    final data = await response.body.decode();

    expect(data, isNotNull);
  });

  test("POST /api/devices/{type} returns status code 200", () async {
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
