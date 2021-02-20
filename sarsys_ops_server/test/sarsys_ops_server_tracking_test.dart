import 'dart:async';

import 'package:event_source/event_source.dart';
import 'package:sarsys_app_server/sarsys_app_server.dart';
import 'package:sarsys_domain/sarsys_domain.dart';
import 'package:sarsys_ops_server_test/sarsys_ops_server_test.dart';
import 'package:test/test.dart';

Future main() async {
  final harness = SarSysOpsHarness()
    ..withContext()
    ..withTrackingServer()
    ..withLogger(debug: false)
    ..install();

  test('GET /ops/api/services/tracking returns 200 OK', () async {
    final response = await harness.agent.get('/ops/api/services/tracking?expand=all');
    expect(response.statusCode, 200);
    final metas = List<Map<String, dynamic>>.from(
      await response.body.decode(),
    );
    expect(metas.length, 1);
    final meta = metas.last;
    expect(meta.elementAt<String>('status'), 'READY');
    expect(meta.listAt('managerOf'), isNull);
    expect(meta.elementAt<int>('trackings/total'), 0);
    expect(meta.elementAt<double>('trackings/fractionManaged'), 0.0);
    final positions = meta.mapAt<String, dynamic>('positions');
    expect(positions.elementAt<int>('total'), 0);
    expect(positions.elementAt<double>('eventsPerMinute'), 0.0);
    expect(positions.elementAt<int>('averageProcessingTimeMillis'), 0.0);
    final lastEvent = positions.mapAt<String, dynamic>('lastEvent');
    expect(lastEvent.elementAt<String>('type'), isNull);
    expect(lastEvent.elementAt<String>('uuid'), isNull);
    expect(lastEvent.elementAt<bool>('remote'), isNull);
    expect(lastEvent.elementAt<int>('number'), -1);
    expect(lastEvent.elementAt<int>('position'), -1);
  });

  test("POST /ops/api/services/tracking with 'start_all' returns 200", () async {
    await _testStartAllService(harness);
  });

  test("POST /ops/api/services/tracking/{name}  with 'start' returns 200", () async {
    await _testStartService(harness);
  });

  test("POST /ops/api/services/tracking with 'stop_all' returns 200", () async {
    // Arrange
    await _testStartAllService(harness);

    // Act
    final response = await harness.agent.post('/ops/api/services/tracking', body: {
      'action': 'stop_all',
    });

    // Assert
    final body = await response.body.decode();
    expect(response.statusCode, 200, reason: '$body');
    final metas = List<Map<String, dynamic>>.from(body);
    expect(metas.length, 1);
    final meta = Map<String, dynamic>.from(metas.last['meta']);
    expect(meta.elementAt<String>('status'), 'STOPPED');
  });

  test("POST /ops/api/services/tracking/{name} with 'stop' returns 200", () async {
    // Arrange
    await _testStartService(harness);

    // Act
    final response =
        await harness.agent.post('/ops/api/services/tracking/${SarSysOpsHarness.trackingInstance0}', body: {
      'action': 'stop',
    });

    // Assert
    final body = await response.body.decode();
    expect(response.statusCode, 200, reason: '$body');
    final meta = Map<String, dynamic>.from(body['meta']);
    expect(meta, isNotEmpty);
    expect(meta.elementAt<String>('status'), 'STOPPED');
  });

  test("POST /ops/api/services/tracking with 'add_trackings' returns 400 on empty uuids", () async {
    final response = await harness.agent.post(
      '/ops/api/services/tracking/${SarSysOpsHarness.trackingInstance0}',
      body: {
        'action': 'add_trackings',
        'uuids': [],
      },
    );
    expect(response.statusCode, 400);
  });

  test("POST /ops/api/services/tracking with 'remove_trackings' returns 400 on empty uuids", () async {
    final response = await harness.agent.post(
      '/ops/api/services/tracking/${SarSysOpsHarness.trackingInstance0}',
      body: {
        'action': 'remove_trackings',
        'uuids': [],
      },
    );
    expect(response.statusCode, 400);
  });

  test("POST with 'add_trackings' returns 200 for uuids that exists", () async {
    // Arrange
    await _testAddTrackings(harness);
  });

  test("POST with 'remove_trackings' returns 200 for uuids that is managed", () async {
    // Arrange
    final uuids = await _testAddTrackings(harness);

    // Act
    final tuuid1 = uuids.first;
    final response =
        await harness.agent.post('/ops/api/services/tracking/${SarSysOpsHarness.trackingInstance0}', body: {
      'action': 'remove_trackings',
      'uuids': [tuuid1],
    });

    // Assert
    final body = await response.body.decode();
    expect(response.statusCode, 200, reason: '$body');
    final meta = (body as Map).mapAt<String, dynamic>('meta');
    expect(meta.elementAt<String>('status'), 'READY');
    final managerOf = meta.listAt('managerOf');
    expect(managerOf, hasLength(1));
    expect(meta.elementAt<int>('trackings/total'), 2);
    expect(meta.elementAt<double>('trackings/fractionManaged'), 0.5);
    final positions = meta.mapAt<String, dynamic>('positions');
    expect(positions.elementAt<int>('total'), 0);
    expect(positions.elementAt<double>('eventsPerMinute'), 0.0);
    expect(positions.elementAt<int>('averageProcessingTimeMillis'), 0.0);
    final lastEvent = positions.mapAt<String, dynamic>('lastEvent');
    expect(lastEvent.elementAt<String>('type'), isNull);
    expect(lastEvent.elementAt<String>('uuid'), isNull);
    expect(lastEvent.elementAt<bool>('remote'), isNull);
    expect(lastEvent.elementAt<int>('number'), -1);
    expect(lastEvent.elementAt<int>('position'), -1);
  });
}

Future _testStartService(SarSysOpsHarness harness) async {
  final response = await harness.agent.post('/ops/api/services/tracking/${SarSysOpsHarness.trackingInstance0}', body: {
    'action': 'start',
  });
  final body = await response.body.decode();
  expect(response.statusCode, 200, reason: '$body');
  final meta = Map<String, dynamic>.from(body['meta']);
  expect(meta, isNotEmpty);
  expect(meta.elementAt<String>('status'), 'STARTED');
}

Future _testStartAllService(SarSysOpsHarness harness) async {
  final response = await harness.agent.post('/ops/api/services/tracking', body: {
    'action': 'start_all',
  });
  final body = await response.body.decode();
  expect(response.statusCode, 200, reason: '$body');
  final metas = List<Map<String, dynamic>>.from(body);
  expect(metas.length, 1);
  final meta = Map<String, dynamic>.from(metas.last['meta']);
  expect(meta.elementAt<String>('status'), 'STARTED');
}

Future<List<String>> _testAddTrackings(SarSysOpsHarness harness) async {
  final sub = SarSysOpsHarness.sub;
  final stream = harness.eventStoreServer.getStream(sub);
  final repo = harness.trackingServer.manager.get<TrackingRepository>();
  await repo.readyAsync();
  final tuuid1 = await createTracking(repo, stream, sub);
  final tuuid2 = await createTracking(repo, stream, sub);

  // Act
  final response = await harness.agent.post('/ops/api/services/tracking/${SarSysOpsHarness.trackingInstance0}', body: {
    'action': 'add_trackings',
    'uuids': [
      tuuid1,
      tuuid2,
    ],
  });

  // Assert
  final body = await response.body.decode();
  expect(response.statusCode, 200, reason: '$body');
  final meta = (body as Map).mapAt<String, dynamic>('meta');
  expect(meta.elementAt<String>('status'), 'READY');
  final managerOf = meta.listAt('managerOf');
  expect(managerOf, hasLength(2));
  expect(meta.elementAt<int>('trackings/total'), 2);
  expect(meta.elementAt<double>('trackings/fractionManaged'), 1.0);
  final positions = meta.mapAt<String, dynamic>('positions');
  expect(positions.elementAt<int>('total'), 0);
  expect(positions.elementAt<double>('eventsPerMinute'), 0.0);
  expect(positions.elementAt<int>('averageProcessingTimeMillis'), 0.0);
  final lastEvent = positions.mapAt<String, dynamic>('lastEvent');
  expect(lastEvent.elementAt<String>('type'), isNull);
  expect(lastEvent.elementAt<String>('uuid'), isNull);
  expect(lastEvent.elementAt<bool>('remote'), isNull);
  expect(lastEvent.elementAt<int>('number'), -1);
  expect(lastEvent.elementAt<int>('position'), -1);

  return managerOf
      .map<String>(
        (t) => (t as Map).elementAt<String>('uuid'),
      )
      .toList();
}
