import 'dart:async';

import 'package:sarsys_domain/sarsys_domain.dart';
import 'package:uuid/uuid.dart';
import 'package:test/test.dart';

import 'harness.dart';

Future main() async {
  final harness = SarSysHarness()
    ..withEventStoreMock()
    ..install(restartForEachTest: true);

  test("GET /api/trackings/{uuid}/tracks/{id}/positions returns 200", () async {
    // Arrange
    final uuid = Uuid().v4();
    final p1 = createPosition(lat: 1.0);
    final p2 = createPosition(lon: 1.0);
    final positions = [p1, p2];
    await _prepareGet(harness, uuid, positions);

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

  test("GET /api/trackings/{uuid}/tracks/{id}/positions?offset=1&limit=1 returns 200", () async {
    // Arrange
    final uuid = Uuid().v4();
    final p1 = createPosition(lat: 1.0);
    final p2 = createPosition(lon: 1.0);
    final p3 = createPosition(lat: 2.0);
    final p4 = createPosition(lon: 2.0);
    final positions = [p1, p2, p3, p4];
    await _prepareGet(harness, uuid, positions);

    // Assert
    final response = expectResponse(
      await harness.agent.execute(
        'GET',
        "/api/trackings/$uuid/tracks/0/positions?offset=1&limit=1",
      ),
      200,
    );
    final actual = await response.body.decode();
    expect(
      actual['data'],
      positions.skip(1).take(1),
    );
  });

  test("GET /api/trackings/{uuid}/tracks/{id}/positions?offset=1&option=truncate:2:p returns 200", () async {
    // Arrange
    await _testTruncate(harness, '2:p', 1, 1);
  });

  test("GET /api/trackings/{uuid}/tracks/{id}/positions?offset=1&option=truncate:2:m returns 200", () async {
    // Arrange
    await _testTruncate(harness, '2:m', 1, 3);
  });

  test("GET /api/trackings/{uuid}/tracks/{id}/positions?offset=1&option=truncate:2:h returns 200", () async {
    // Arrange
    await _testTruncate(harness, '2:h', 1, 3);
  });
}

Future _testTruncate(SarSysHarness harness, String truncate, int skip, int take) async {
  // Arrange
  final uuid = Uuid().v4();
  final p1 = createPosition(lat: 1.0);
  final p2 = createPosition(lon: 1.0);
  final p3 = createPosition(lat: 2.0);
  final p4 = createPosition(lon: 2.0);
  final positions = [p1, p2, p3, p4];
  await _prepareGet(harness, uuid, positions);

  // Assert
  final response = expectResponse(
    await harness.agent.execute(
      'GET',
      "/api/trackings/$uuid/tracks/0/positions?offset=1&option=truncate:$truncate",
    ),
    200,
  );
  final actual = await response.body.decode();
  expect(
    actual['data'],
    positions.skip(skip).take(take),
  );
}

Future<Map<String, dynamic>> _prepareGet(
  SarSysHarness harness,
  String uuid,
  List<Map<String, Object>> positions,
) async {
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
  final repo = harness.channel.manager.get<TrackingRepository>();
  final track = await _addTrackingTrack(
    repo,
    uuid,
    createTrack(
      uuid: uuid,
      id: '0',
      type: 'device',
      positions: positions,
    ),
  );
  return track;
}

FutureOr<Map<String, dynamic>> _addTrackingTrack(
  TrackingRepository repo,
  String uuid,
  Map<String, dynamic> track,
) async {
  await repo.execute(AddTrackToTracking(uuid, track));
  return track;
}
