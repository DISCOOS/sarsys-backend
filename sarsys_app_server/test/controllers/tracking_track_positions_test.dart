import 'dart:async';

import 'package:sarsys_domain/sarsys_domain.dart';
import 'package:uuid/uuid.dart';
import 'package:test/test.dart';

import 'harness.dart';

Future main() async {
  final harness = SarSysHarness()
    ..withEventStoreMock()
    ..install(restartForEachTest: true);

  test("GET /api/trackings/{uuid}/tracks/{id} returns 200", () async {
    // Arrange
    final uuid = Uuid().v4();
    final body = createTracking(uuid);
    expectResponse(
      await harness.agent.post(
        "/api/trackings",
        headers: createAuthn(
          createAuthnAdmin(),
        ),
        body: body,
      ),
      201,
      body: null,
    );

    // Act
    final p1 = createPosition(lat: 1.0);
    final positions = [p1];
    final repo = harness.channel.manager.get<TrackingRepository>();
    await _addTrackingTrack(
      repo,
      uuid,
      createTrack(
        uuid: uuid,
        id: '0',
        type: 'device',
        positions: positions,
      ),
    );

    // Assert
    final response = expectResponse(
      await harness.agent.execute(
        'GET',
        "/api/trackings/$uuid/tracks/0/positions",
      ),
      200,
    );
    final actual = await response.body.decode();
    expect(
      actual['data'],
      positions,
    );
  });
}

FutureOr<Map<String, dynamic>> _addTrackingTrack(
  TrackingRepository repo,
  String uuid,
  Map<String, dynamic> track,
) async {
  await repo.execute(AddTrackToTracking(uuid, track));
  return track;
}
