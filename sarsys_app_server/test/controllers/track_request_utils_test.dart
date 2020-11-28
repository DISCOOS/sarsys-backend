import 'dart:async';

import 'package:sarsys_app_server/controllers/domain/track_request_utils.dart';
import 'package:uuid/uuid.dart';
import 'package:test/test.dart';

import 'harness.dart';

Future main() async {
  test("TrackRequestUtils truncates 2:p from tail", () async {
    await _testTruncate('2:p', 0, 2, const Duration(minutes: 2));
  });

  test("TrackRequestUtils truncates 2:m from tail", () async {
    await _testTruncate('2:m', 0, 2, const Duration(minutes: 2));
  });

  test("TrackRequestUtils truncates 2:h from tail", () async {
    await _testTruncate('2:h', 0, 2, const Duration(hours: 2));
  });

  test("TrackRequestUtils truncates -2:p from head", () async {
    await _testTruncate('-2:p', 2, 2, const Duration(minutes: 2));
  });

  test("TrackRequestUtils truncates -2:m from head", () async {
    await _testTruncate('-2:m', 2, 2, const Duration(minutes: 2));
  });

  test("TrackRequestUtils truncates -2:h from head", () async {
    await _testTruncate('-2:h', 2, 2, const Duration(hours: 2));
  });
}

Future _testTruncate(String truncate, int skip, int take, Duration duration) async {
  // Arrange
  final uuid = Uuid().v4();
  var timestamp = DateTime.now();
  final p1 = createPosition(lat: 1.0, timestamp: timestamp);
  final p2 = createPosition(lon: 1.0, timestamp: timestamp = timestamp.add(duration));
  final p3 = createPosition(lat: 2.0, timestamp: timestamp = timestamp.add(duration));
  final p4 = createPosition(lon: 2.0, timestamp: timestamp = timestamp.add(duration));
  final positions = [p1, p2, p3, p4];
  final track = createTrack(
    uuid: uuid,
    id: '0',
    type: 'device',
    positions: positions,
  );

  final actual = TrackRequestUtils.toTrack(
    track,
    'positions',
    ['truncate:$truncate'],
  );
  expect(
    actual['positions'],
    positions.skip(skip).take(take),
  );
}
