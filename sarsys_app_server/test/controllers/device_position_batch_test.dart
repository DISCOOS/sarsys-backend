import 'package:uuid/uuid.dart';
import 'package:test/test.dart';

import 'harness.dart';

Future main() async {
  final harness = SarSysHttpHarness()
    ..withEventStoreMock()
    ..install(restartForEachTest: true);

  test("GET /api/devices/{uuid}/positions returns status code 405", () async {
    final uuid = Uuid().v4();
    final device = _createData(uuid);
    expectResponse(await harness.agent.post("/api/devices", body: device), 201, body: null);
    final response = expectResponse(await harness.agent.get("/api/devices/$uuid/positions"), 405);
    await response.body.decode();
  });

  test("POST /api/devices/{uuid}/positions returns status code 204 if set", () async {
    final uuid = Uuid().v4();
    final device = _createData(uuid);
    expectResponse(
      await harness.agent.post("/api/devices", body: device),
      201,
      body: null,
    );
    final positions = [
      createPosition(lat: 1.0),
      createPosition(lat: 2.0),
      createPosition(lat: 3.0),
      createPosition(lat: 4.0),
    ];
    expectResponse(
      await harness.agent.post("/api/devices/$uuid/positions", body: positions),
      204,
      body: null,
    );
    final response = expectResponse(
      await harness.agent.get("/api/devices/$uuid/position"),
      200,
    );
    final actual = await response.body.decode();
    expect(actual['data'], equals(positions.last));
  });
}

Map<String, Object> _createData(String uuid) => createDevice(uuid);
