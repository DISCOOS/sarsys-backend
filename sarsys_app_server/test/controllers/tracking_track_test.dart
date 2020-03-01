import 'dart:async';

import 'package:sarsys_domain/sarsys_domain.dart';
import 'package:event_source/event_source.dart';
import 'package:uuid/uuid.dart';
import 'package:test/test.dart';

import 'harness.dart';

Future main() async {
  final harness = SarSysHarness()
    ..withEventStoreMock()
    ..install(restartForEachTest: true);

  test("GET /api/trackings/{uuid}/tracks returns status code 200", () async {
    harness.eventStoreMockServer.withStream(typeOf<Tracking>().toColonCase());
    final repo = harness.channel.manager.get<TrackingRepository>();
    await repo.readyAsync();
    final uuid = Uuid().v4();
    final tracking = _createData(uuid);
    expectResponse(
      await harness.agent.post(
        "/api/trackings",
        headers: createAuthn(createAuthnAdmin()),
        body: tracking,
      ),
      201,
      body: null,
    );
    final track1 = createTrack(id: '1');
    await _addTrackingTrack(repo, uuid, track1);
    final track2 = createTrack(id: '2');
    await _addTrackingTrack(repo, uuid, track2);
    final response = expectResponse(await harness.agent.get("/api/trackings/$uuid/tracks"), 200);
    final actual = await response.body.decode();
    expect(actual['total'], equals(2));
    expect(actual['entries'].length, equals(2));
  });

  test("GET /api/trackings/{uuid}/tracks/{id} returns status code 200", () async {
    harness.eventStoreMockServer.withStream(typeOf<Tracking>().toColonCase());
    final repo = harness.channel.manager.get<TrackingRepository>();
    await repo.readyAsync();
    final uuid = Uuid().v4();
    final tracking = _createData(uuid);
    expectResponse(
      await harness.agent.post(
        "/api/trackings",
        headers: createAuthn(createAuthnAdmin()),
        body: tracking,
      ),
      201,
      body: null,
    );
    final track1 = createTrack(id: '1');
    await _addTrackingTrack(repo, uuid, track1);
    final response1 = expectResponse(await harness.agent.get("/api/trackings/$uuid/tracks/1"), 200);
    final actual1 = await response1.body.decode();
    expect(actual1['data'], equals(track1));
    final track2 = createTrack(id: '2');
    await _addTrackingTrack(repo, uuid, track2);
    final response2 = expectResponse(await harness.agent.get("/api/trackings/$uuid/tracks/2"), 200);
    final actual2 = await response2.body.decode();
    expect(actual2['data'], equals(track2));
  });
}

Map<String, Object> _createData(String uuid) => createTracking(uuid);

FutureOr<Map<String, dynamic>> _addTrackingTrack(
  TrackingRepository repo,
  String uuid,
  Map<String, dynamic> track,
) async {
  await repo.execute(AddTrackToTracking(uuid, track));
  return track;
}
