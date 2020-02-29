import 'package:sarsys_domain/sarsys_domain.dart';
import 'package:event_source/event_source.dart';
import 'package:uuid/uuid.dart';
import 'package:test/test.dart';

import 'harness.dart';

Future main() async {
  final harness = SarSysHarness()
    ..withEventStoreMock()
    ..install(restartForEachTest: true);

  test("POST /api/trackings/{uuid}/tracks returns status code 201 with empty body", () async {
    harness.eventStoreMockServer.withStream(typeOf<Tracking>().toColonCase());
    await harness.channel.manager.get<TrackingRepository>().readyAsync();
    final uuid = Uuid().v4();
    final tracking = _createData(uuid);
    expectResponse(await harness.agent.post("/api/trackings", body: tracking), 201, body: null);
    final track = createTrack(id: '1');
    expectResponse(await harness.agent.post("/api/trackings/$uuid/tracks", body: track), 201, body: null);
  });

  test("GET /api/trackings/{uuid}/tracks returns status code 200", () async {
    harness.eventStoreMockServer.withStream(typeOf<Tracking>().toColonCase());
    await harness.channel.manager.get<TrackingRepository>().readyAsync();
    final uuid = Uuid().v4();
    final tracking = _createData(uuid);
    expectResponse(await harness.agent.post("/api/trackings", body: tracking), 201, body: null);
    final track1 = createTrack(id: '1');
    expectResponse(await harness.agent.post("/api/trackings/$uuid/tracks", body: track1), 201, body: null);
    final track2 = createTrack(id: '2');
    expectResponse(await harness.agent.post("/api/trackings/$uuid/tracks", body: track2), 201, body: null);
    final response = expectResponse(await harness.agent.get("/api/trackings/$uuid/tracks"), 200);
    final actual = await response.body.decode();
    expect(actual['total'], equals(2));
    expect(actual['entries'].length, equals(2));
  });

  test("GET /api/trackings/{uuid}/tracks/{id} returns status code 200", () async {
    harness.eventStoreMockServer.withStream(typeOf<Tracking>().toColonCase());
    await harness.channel.manager.get<TrackingRepository>().readyAsync();
    final uuid = Uuid().v4();
    final tracking = _createData(uuid);
    expectResponse(await harness.agent.post("/api/trackings", body: tracking), 201, body: null);
    final track1 = createTrack(id: '1');
    expectResponse(await harness.agent.post("/api/trackings/$uuid/tracks", body: track1), 201, body: null);
    final response1 = expectResponse(await harness.agent.get("/api/trackings/$uuid/tracks/1"), 200);
    final actual1 = await response1.body.decode();
    expect(actual1['data'], equals(track1));
    final track2 = createTrack(id: '2');
    expectResponse(await harness.agent.post("/api/trackings/$uuid/tracks", body: track2), 201, body: null);
    final response2 = expectResponse(await harness.agent.get("/api/trackings/$uuid/tracks/2"), 200);
    final actual2 = await response2.body.decode();
    expect(actual2['data'], equals(track2));
  });

  test("PATCH /api/trackings/{uuid}/tracks/{id} is idempotent", () async {
    harness.eventStoreMockServer.withStream(typeOf<Tracking>().toColonCase());
    await harness.channel.manager.get<TrackingRepository>().readyAsync();
    final uuid = Uuid().v4();
    final tracking = _createData(uuid);
    expectResponse(await harness.agent.post("/api/trackings", body: tracking), 201, body: null);
    final track = createTrack(id: '1');
    expectResponse(await harness.agent.post("/api/trackings/$uuid/tracks", body: track), 201, body: null);
    expectResponse(await harness.agent.execute("PATCH", "/api/trackings/$uuid/tracks/1", body: track), 204, body: null);
    final response1 = expectResponse(await harness.agent.get("/api/trackings/$uuid"), 200);
    final actual1 = await response1.body.decode();
    expect((actual1['data'] as Map)['tracks'], equals([track]));
    final response2 = expectResponse(await harness.agent.get("/api/trackings/$uuid/tracks/1"), 200);
    final actual2 = await response2.body.decode();
    expect(actual2['data'], equals(track));
  });

  test("PATCH /api/trackings/{uuid} on entity object lists should not be allowed", () async {
    harness.eventStoreMockServer.withStream(typeOf<Tracking>().toColonCase());
    await harness.channel.manager.get<TrackingRepository>().readyAsync();
    final uuid = Uuid().v4();
    final tracking = _createData(uuid);
    expectResponse(await harness.agent.post("/api/trackings", body: tracking), 201, body: null);

    expectResponse(
        await harness.agent.execute("PATCH", "/api/trackings/$uuid", body: {
          "tracks": [createTrack(id: '1')],
        }),
        400,
        body: null);
  });

  test("DELETE /api/trackings/{uuid}/tracks/{id} returns status code 204", () async {
    harness.eventStoreMockServer.withStream(typeOf<Tracking>().toColonCase());
    await harness.channel.manager.get<TrackingRepository>().readyAsync();
    final uuid = Uuid().v4();
    final tracking = _createData(uuid);
    expectResponse(await harness.agent.post("/api/trackings", body: tracking), 201, body: null);
    final track = createTrack(id: '1');
    expectResponse(await harness.agent.post("/api/trackings/$uuid/tracks", body: track), 201, body: null);
    expectResponse(await harness.agent.delete("/api/trackings/$uuid"), 204);
  });
}

Map<String, Object> _createData(String uuid) => createTracking(uuid);
