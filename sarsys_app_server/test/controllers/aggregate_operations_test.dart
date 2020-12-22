import 'package:sarsys_domain/sarsys_domain.dart';
import 'package:uuid/uuid.dart';
import 'package:test/test.dart';

import 'harness.dart';

Future main() async {
  final harness = SarSysHttpHarness()
    ..withEventStoreMock()
    ..install(restartForEachTest: true);

  test("GET /api/aggregates/device/{uuid}?expand=data,items returns status code 200", () async {
    // Arrange
    final uuid = Uuid().v4();
    final body = createDevice(uuid);
    expectResponse(await harness.agent.post("/api/devices", body: body), 201, body: null);

    final response = await harness.agent.get("/api/aggregates/device/$uuid?expand=data,items");
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

    final request = harness.agent.post("/api/aggregates/device/$uuid", body: {
      'action': 'replay',
      'params': {
        'uuids': [
          uuid,
        ],
      }
    });
    final response = expectResponse(await request, 200);
    final data = await response.body.decode();

    expect(data, isNotNull);
  });

  test("POST /api/aggregates/device/{uuid} returns status code 200 for action 'replace' aggregate data", () async {
    // Arrange
    final uuid = Uuid().v4();
    final body = createDevice(uuid);
    expectResponse(await harness.agent.post("/api/devices", body: body), 201, body: null);

    final request = harness.agent.post("/api/aggregates/device/$uuid?expand=data", body: {
      'action': 'replace',
      'params': {
        'data': {'parameter1': 'value1'}
      }
    });
    final previous = expectResponse(await request, 200);
    final data1 = await previous.body.decode();

    // Assert previous and next data
    expect(data1['data'], equals(body));
    final next = expectResponse(await harness.agent.get("/api/devices/$uuid"), 200);
    final data2 = await next.body.decode();
    expect(data2['data'], equals({'uuid': uuid, 'parameter1': 'value1'}));
  });

  test("POST /api/aggregates/device/{uuid} returns status code 200 for action 'catchup' aggregate", () async {
    // Arrange
    final uuid = Uuid().v4();
    final body = createDevice(uuid);
    expectResponse(await harness.agent.post("/api/devices", body: body), 201, body: null);

    final request = harness.agent.post("/api/aggregates/device/$uuid", body: {
      'action': 'catchup',
      'params': {
        'uuids': [
          uuid,
        ],
      }
    });
    final response = expectResponse(await request, 200);
    final data = await response.body.decode();

    expect(data, isNotNull);
  });
}
