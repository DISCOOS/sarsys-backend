import 'package:sarsys_domain/sarsys_domain.dart';
import 'package:uuid/uuid.dart';
import 'package:test/test.dart';

import 'harness.dart';

Future main() async {
  final harness = SarSysHttpHarness()
    ..withContext()
    ..withEventStoreMock()
    ..install(restartForEachTest: true);

  test("GET /api/aggregates/device/{uuid} returns status code 416 on pod mismatch", () async {
    // Arrange
    final uuid = Uuid().v4();
    final body = createDevice(uuid);
    expectResponse(await harness.agent.post("/api/devices", body: body), 201, body: null);

    final request = harness.agent.get("/api/aggregates/device/$uuid", headers: {'x-if-match-pod': 'foo'});
    final response = expectResponse(await request, 416);
    final data = Map<String, dynamic>.from(
      await response.body.decode(),
    );

    expect(data, isEmpty);
  });

  test("GET /api/aggregates/device/{uuid}?expand=data,items returns status code 200", () async {
    // Arrange
    final uuid = Uuid().v4();
    final body = createDevice(uuid);
    expectResponse(await harness.agent.post("/api/devices", body: body), 201, body: null);

    final request = harness.agent.get(
      "/api/aggregates/device/$uuid?expand=data,items",
      headers: {'x-if-match-pod': 'bar'},
    );
    final response = expectResponse(await request, 200);
    final data = Map<String, dynamic>.from(
      await response.body.decode(),
    );

    expect(data['data'], isNotNull);
  });

  test("POST /api/aggregates/device/{uuid} returns status code 200 for action 'replay' aggregate", () async {
    // Arrange
    final uuid = Uuid().v4();
    final body = createDevice(uuid);
    expectResponse(await harness.agent.post("/api/devices", body: body), 201, body: null);
    harness.channel.manager.get<DeviceRepository>().save();

    final request = harness.agent.post(
      "/api/aggregates/device/$uuid",
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

  test("POST /api/aggregates/device/{uuid} returns status code 200 for action 'replace' aggregate data", () async {
    // Arrange
    final uuid = Uuid().v4();
    final body = createDevice(uuid);
    expectResponse(await harness.agent.post("/api/devices", body: body), 201, body: null);
    final repo = harness.channel.manager.get<DeviceRepository>();
    repo.store.cordon(repo, uuid, reason: 'test');

    final data1 = {'parameter1': 'value1'};
    final request = harness.agent.post(
      "/api/aggregates/device/$uuid?expand=data",
      body: {
        'action': 'replace',
        'params': {
          'data': data1,
        }
      },
      headers: {'x-if-match-pod': 'bar'},
    );
    final previous = expectResponse(await request, 200);
    final body2 = await previous.body.decode();

    // Assert previous and next data
    expect(body2['data'], equals(data1..addAll({'uuid': uuid})));
    final next = expectResponse(await harness.agent.get("/api/devices/$uuid"), 200);
    final body3 = await next.body.decode();
    expect(body3['data'], equals(data1..addAll({'uuid': uuid})));
  });

  test("POST /api/aggregates/device/{uuid} returns status code 200 for action 'catchup' aggregate", () async {
    // Arrange
    final uuid = Uuid().v4();
    final body = createDevice(uuid);
    expectResponse(await harness.agent.post("/api/devices", body: body), 201, body: null);

    final request = harness.agent.post(
      "/api/aggregates/device/$uuid",
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
