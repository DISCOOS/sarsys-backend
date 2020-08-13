import 'package:sarsys_domain/sarsys_domain.dart';
import 'package:uuid/uuid.dart';
import 'package:test/test.dart';

import 'harness.dart';

Future main() async {
  final harness = SarSysHarness()
    ..withEventStoreMock()
    ..install(restartForEachTest: true);

  test("GET /api/devices/{uuid}/position returns status code 404 if not set", () async {
    final uuid = Uuid().v4();
    final device = _createData(uuid);
    expectResponse(await harness.agent.post("/api/devices", body: device), 201, body: null);
    final response = expectResponse(await harness.agent.get("/api/devices/$uuid/position"), 404);
    await response.body.decode();
  });

  test("PATCH /api/devices/{uuid}/position returns status code 204 if set", () async {
    await harness.channel.manager.get<DeviceRepository>().readyAsync();
    final uuid = Uuid().v4();
    final device = _createData(uuid);
    expectResponse(await harness.agent.post("/api/devices", body: device), 201, body: null);
    final position = createPosition(activity: 'still', confidence: 80);
    expectResponse(
      await harness.agent.execute("PATCH", "/api/devices/$uuid/position", body: position),
      204,
      body: null,
    );
    final response = expectResponse(await harness.agent.get("/api/devices/$uuid/position"), 200);
    final actual = await response.body.decode();
    expect(actual['data'], equals(position));
  });

  test("PATCH /api/devices/{uuid}/position returns status code 400 if position type is illegal", () async {
    await harness.channel.manager.get<DeviceRepository>().readyAsync();
    final uuid = Uuid().v4();
    final device = _createData(uuid);
    expectResponse(await harness.agent.post("/api/devices", body: device), 201, body: null);
    final position = createPosition(type: 'automatic');
    expectResponse(
      await harness.agent.execute("PATCH", "/api/devices/$uuid/position", body: position),
      400,
      body: null,
    );
  });
}

Map<String, Object> _createData(String uuid) => createDevice(uuid);
