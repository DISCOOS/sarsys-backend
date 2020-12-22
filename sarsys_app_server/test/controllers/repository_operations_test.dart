import 'package:sarsys_domain/sarsys_domain.dart';
import 'package:uuid/uuid.dart';
import 'package:test/test.dart';

import 'harness.dart';

Future main() async {
  final harness = SarSysHttpHarness()
    ..withContext()
    ..withSnapshot()
    ..withEventStoreMock()
    ..install(restartForEachTest: true);

  test("GET /api/repositories/device returns status code 416 on pod mismatch", () async {
    // Arrange
    final uuid = Uuid().v4();
    final body = createDevice(uuid);
    expectResponse(await harness.agent.post("/api/devices", body: body), 201, body: null);

    final request = harness.agent.get("/api/repositories/device", headers: {'x-if-match-pod': 'foo'});
    final response = expectResponse(await request, 416);
    final data = await response.body.decode();

    expect(data, isEmpty);
  });

  test("GET /api/repositories/device returns status code 200", () async {
    // Arrange
    final uuid = Uuid().v4();
    final body = createDevice(uuid);
    expectResponse(await harness.agent.post("/api/devices", body: body), 201, body: null);

    final request = harness.agent.get("/api/repositories/device", headers: {'x-if-match-pod': 'bar'});
    final response = expectResponse(await request, 200);
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

    final request = harness.agent.get("/api/repositories/device?expand=queue", headers: {
      'x-if-match-pod': 'bar',
    });
    final response = expectResponse(await request, 200);
    final data = await response.body.decode();

    expect(data['queue'], isNotNull);
  });

  test("POST /api/repositories/device returns status code 200 for action 'rebuild'", () async {
    // Arrange
    final uuid = Uuid().v4();
    final body = createDevice(uuid);
    expectResponse(await harness.agent.post("/api/devices", body: body), 201, body: null);

    final request = harness.agent.post(
      "/api/repositories/device",
      body: {
        'action': 'rebuild',
      },
      headers: {'x-if-match-pod': 'bar'},
    );
    final response = expectResponse(await request, 200);
    final data = await response.body.decode();

    expect(data, isNotNull);
  });

  test("POST /api/repositories/device returns status code 200 for action 'replay' repository", () async {
    // Arrange
    final uuid = Uuid().v4();
    final body = createDevice(uuid);
    expectResponse(await harness.agent.post("/api/devices", body: body), 201, body: null);

    final request = harness.agent.post(
      "/api/repositories/device",
      body: {
        'action': 'replay',
        'params': {
          'uuids': [
            uuid,
          ],
        }
      },
      headers: {'x-if-match-pod': 'bar'},
    );
    final response = expectResponse(await request, 200);
    final data = await response.body.decode();

    expect(data, isNotNull);
  });

  test("POST /api/repositories/device returns status code 200 for action 'catchup' repository", () async {
    // Arrange
    final uuid = Uuid().v4();
    final body = createDevice(uuid);
    expectResponse(await harness.agent.post("/api/devices", body: body), 201, body: null);

    final request = harness.agent.post(
      "/api/repositories/device",
      body: {
        'action': 'catchup',
        'params': {
          'uuids': [
            uuid,
          ],
        }
      },
      headers: {'x-if-match-pod': 'bar'},
    );
    final response = expectResponse(await request, 200);
    final data = await response.body.decode();

    expect(data, isNotNull);
  });
}
