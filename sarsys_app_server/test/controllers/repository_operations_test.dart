import 'package:sarsys_domain/sarsys_domain.dart';
import 'package:uuid/uuid.dart';
import 'package:test/test.dart';

import 'harness.dart';

Future main() async {
  final harness = SarSysHttpHarness()
    ..withEventStoreMock()
    ..install(restartForEachTest: true);

  test("GET /api/repositories/device returns status code 200", () async {
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

  test("GET /api/repositories/device?expand=queue returns status code 200", () async {
    // Arrange
    final uuid = Uuid().v4();
    final body = createDevice(uuid);
    expectResponse(await harness.agent.post("/api/devices", body: body), 201, body: null);
    harness.channel.manager.get<DeviceRepository>().save();

    final response = await harness.agent.get("/api/repositories/device?expand=queue");
    final data = await response.body.decode();

    expect(data['queue'], isNotNull);
  });

  test("POST /api/repositories/device returns status code 200 for action 'rebuild'", () async {
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

  test("POST /api/repositories/device returns status code 200 for action 'replay' repository", () async {
    // Arrange
    final uuid = Uuid().v4();
    final body = createDevice(uuid);
    expectResponse(await harness.agent.post("/api/devices", body: body), 201, body: null);

    final response = await harness.agent.post("/api/repositories/device", body: {
      'action': 'replay',
      'params': {
        'uuids': [
          uuid,
        ],
      }
    });
    final data = await response.body.decode();

    expect(data, isNotNull);
  });

  test("POST /api/repositories/device returns status code 200 for action 'catchup' aggregate", () async {
    // Arrange
    final uuid = Uuid().v4();
    final body = createDevice(uuid);
    expectResponse(await harness.agent.post("/api/devices", body: body), 201, body: null);

    final response = await harness.agent.post("/api/repositories/device", body: {
      'action': 'catchup',
      'params': {
        'uuids': [
          uuid,
        ],
      }
    });
    final data = await response.body.decode();

    expect(data, isNotNull);
  });
}
