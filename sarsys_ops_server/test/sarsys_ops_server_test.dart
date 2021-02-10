import 'dart:async';

import 'package:event_source/event_source.dart';
import 'package:sarsys_app_server/sarsys_app_server.dart';
import 'package:sarsys_domain/sarsys_domain.dart';
import 'package:sarsys_ops_server_test/sarsys_ops_server_test.dart';
import 'package:test/test.dart';

Future main() async {
  final harness = SarSysOpsHarness()
    ..withContext()
    ..withModules()
    ..withLogger(debug: false)
    ..install();

  test('GET /ops/api/healthz/alive returns 200 OK', () async {
    final response = await harness.agent.get('/ops/api/healthz/alive');
    expect(response.statusCode, 200);
  });

  test('GET /ops/api/healthz/ready returns 200 OK', () async {
    final response = await harness.agent.get('/ops/api/healthz/ready');
    expect(response.statusCode, 200);
  });

  test('GET /ops/api/system/status returns 200 OK', () async {
    final response = await harness.agent.get('/ops/api/system/status');
    expect(response.statusCode, 200);
    final body = List.from(
      await response.body.decode(),
    );
    final statuses = Map.fromEntries(
      body.map((status) => Map<String, dynamic>.from(status)).map((status) {
        return MapEntry<String, dynamic>(status['name'], status);
      }),
    );
    expect(statuses.length, 2);
    expect(statuses.elementAt('sarsys-app-server'), isNotEmpty);
    expect(statuses.elementAt('sarsys-app-server/instances'), isEmpty);
    expect(statuses.elementAt('sarsys-tracking-server'), isNotEmpty);
    expect(statuses.elementAt('sarsys-tracking-server/instances'), isNotEmpty);
  });

  test('GET /ops/api/services/tracking returns 200 OK', () async {
    final response = await harness.agent.get('/ops/api/services/tracking');
    expect(response.statusCode, 200);
    final metas = List<Map<String, dynamic>>.from(
      await response.body.decode(),
    );
    expect(metas.length, 1);
    final meta = metas.last;
    expect(meta.elementAt<String>('status'), 'READY');
    expect(meta.listAt('managerOf'), isEmpty);
    expect(meta.elementAt<int>('metrics/trackings/total'), 0);
    expect(meta.elementAt<double>('metrics/trackings/fractionManaged'), 0.0);
    final positions = meta.mapAt<String, dynamic>('metrics/positions');
    expect(positions.elementAt<int>('total'), 0);
    expect(positions.elementAt<double>('eventsPerMinute'), 0.0);
    expect(positions.elementAt<int>('averageProcessingTimeMillis'), 0.0);
    final lastEvent = positions.mapAt<String, dynamic>('lastEvent');
    expect(lastEvent.elementAt<String>('type'), isEmpty);
    expect(lastEvent.elementAt<String>('uuid'), isEmpty);
    expect(lastEvent.elementAt<bool>('remote'), isFalse);
    expect(lastEvent.elementAt<int>('number'), -1);
    expect(lastEvent.elementAt<int>('position'), -1);
  });

  test("POST with 'start' returns 200", () async {
    await _testStartService(harness);
  });

  test("POST with 'start_all' returns 200", () async {
    await _testStartAllService(harness);
  });

  test("POST with 'stop' returns 200", () async {
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

  test("POST with 'stop_all' returns 200", () async {
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
    expect(meta.elementAt<int>('metrics/trackings/total'), 2);
    expect(meta.elementAt<double>('metrics/trackings/fractionManaged'), 0.5);
    final positions = meta.mapAt<String, dynamic>('metrics/positions');
    expect(positions.elementAt<int>('total'), 0);
    expect(positions.elementAt<double>('eventsPerMinute'), 0.0);
    expect(positions.elementAt<int>('averageProcessingTimeMillis'), 0.0);
    final lastEvent = positions.mapAt<String, dynamic>('lastEvent');
    expect(lastEvent.elementAt<String>('type'), isEmpty);
    expect(lastEvent.elementAt<String>('uuid'), isEmpty);
    expect(lastEvent.elementAt<bool>('remote'), isFalse);
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
  final stream = harness.esServer.getStream(sub);
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
  expect(meta.elementAt<int>('metrics/trackings/total'), 2);
  expect(meta.elementAt<double>('metrics/trackings/fractionManaged'), 1.0);
  final positions = meta.mapAt<String, dynamic>('metrics/positions');
  expect(positions.elementAt<int>('total'), 0);
  expect(positions.elementAt<double>('eventsPerMinute'), 0.0);
  expect(positions.elementAt<int>('averageProcessingTimeMillis'), 0.0);
  final lastEvent = positions.mapAt<String, dynamic>('lastEvent');
  expect(lastEvent.elementAt<String>('type'), isEmpty);
  expect(lastEvent.elementAt<String>('uuid'), isEmpty);
  expect(lastEvent.elementAt<bool>('remote'), isFalse);
  expect(lastEvent.elementAt<int>('number'), -1);
  expect(lastEvent.elementAt<int>('position'), -1);

  return managerOf
      .map<String>(
        (t) => (t as Map).elementAt<String>('uuid'),
      )
      .toList();
}
