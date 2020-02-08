import 'package:sarsys_app_server/domain/tracking/tracking.dart';
import 'package:sarsys_app_server/eventsource/eventsource.dart';
import 'package:uuid/uuid.dart';
import 'package:test/test.dart';

import 'harness.dart';

Future main() async {
  final harness = SarSysHarness()
    ..withEventStoreMock()
    ..install(restartForEachTest: true);

  test("POST /api/trackings/ returns status code 201 with empty body", () async {
    harness.eventStoreMockServer.withStream(typeOf<Tracking>().toColonCase());
    await harness.channel.manager.get<TrackingRepository>().readyAsync();
    final uuid = Uuid().v4();
    final body = _createData(uuid);
    expectResponse(await harness.agent.post("/api/trackings", body: body), 201, body: null);
  });

  test("POST /api/trackings/ returns status code 400 when 'position/properties/type/device' is given", () async {
    harness.eventStoreMockServer.withStream(typeOf<Tracking>().toColonCase());
    await harness.channel.manager.get<TrackingRepository>().readyAsync();
    final uuid = Uuid().v4();
    final body = _createData(uuid)
      ..addAll({
        'position': {
          'properties': {'type': 'device'},
        }
      });
    expectResponse(
      await harness.agent.post("/api/trackings", body: body),
      400,
      body: 'Schema Tracking has 1 errors: [/position/properties/type: illegal value: device, accepts: [manual]]',
    );
  });

  test("GET /api/trackings/{uuid} returns status code 200", () async {
    harness.eventStoreMockServer.withStream(typeOf<Tracking>().toColonCase());
    await harness.channel.manager.get<TrackingRepository>().readyAsync();
    final uuid = Uuid().v4();
    final body = _createData(uuid);
    expectResponse(await harness.agent.post("/api/trackings", body: body), 201, body: null);
    final response = expectResponse(await harness.agent.get("/api/trackings/$uuid"), 200);
    final actual = await response.body.decode();
    expect(actual['data'], equals(body));
  });

  test("PATCH /api/trackings/{uuid} is idempotent", () async {
    harness.eventStoreMockServer.withStream(typeOf<Tracking>().toColonCase());
    await harness.channel.manager.get<TrackingRepository>().readyAsync();
    final uuid = Uuid().v4();
    final body = _createData(uuid);
    expectResponse(await harness.agent.post("/api/trackings", body: body), 201, body: null);
    expectResponse(await harness.agent.execute("PATCH", "/api/trackings/$uuid", body: body), 204, body: null);
    final response = expectResponse(await harness.agent.get("/api/trackings/$uuid"), 200);
    final actual = await response.body.decode();
    expect(actual['data'], equals(body));
  });

  test("PATCH /api/trackings/{uuid} does not remove value objects", () async {
    harness.eventStoreMockServer.withStream(typeOf<Tracking>().toColonCase());
    await harness.channel.manager.get<TrackingRepository>().readyAsync();
    final uuid = Uuid().v4();
    final body = _createData(uuid);
    expectResponse(await harness.agent.post("/api/trackings", body: body), 201, body: null);
    expectResponse(await harness.agent.execute("PATCH", "/api/trackings/$uuid", body: {}), 204, body: null);
    final response = expectResponse(await harness.agent.get("/api/trackings/$uuid"), 200);
    final actual = await response.body.decode();
    expect(actual['data'], equals(body));
  });

  test("DELETE /api/trackings/{uuid} returns status code 204", () async {
    harness.eventStoreMockServer.withStream(typeOf<Tracking>().toColonCase());
    await harness.channel.manager.get<TrackingRepository>().readyAsync();
    final uuid = Uuid().v4();
    final body = _createData(uuid);
    expectResponse(await harness.agent.post("/api/trackings", body: body), 201, body: null);
    expectResponse(await harness.agent.delete("/api/trackings/$uuid"), 204);
  });

  test("GET /api/trackings returns status code 200 with offset=1 and limit=2", () async {
    harness.eventStoreMockServer.withStream(typeOf<Tracking>().toColonCase());
    await harness.channel.manager.get<TrackingRepository>().readyAsync();
    await harness.agent.post("/api/trackings", body: _createData(Uuid().v4()));
    await harness.agent.post("/api/trackings", body: _createData(Uuid().v4()));
    await harness.agent.post("/api/trackings", body: _createData(Uuid().v4()));
    await harness.agent.post("/api/trackings", body: _createData(Uuid().v4()));
    final response = expectResponse(await harness.agent.get("/api/trackings?offset=1&limit=2"), 200);
    final actual = await response.body.decode();
    expect(actual['total'], equals(4));
    expect(actual['offset'], equals(1));
    expect(actual['limit'], equals(2));
    expect(actual['entries'].length, equals(2));
  });
}

Map<String, Object> _createData(String uuid) => createTracking(uuid);
