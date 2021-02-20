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

  test('GET /ops/api/services/repository/:type returns 200 OK', () async {
    // Arrange
    final repo = harness.trackingServer.manager.get<DeviceRepository>();
    await repo.readyAsync();
    final name = harness.instances.first;
    await createDevice(repo);

    // Act
    final response = await harness.agent.get('/ops/api/services/repository/device?expand=all');

    // Assert
    expect(response.statusCode, 200);
    final body = Map<String, dynamic>.from(
      await response.body.decode(),
    );
    _assertItemsMeta(
      name,
      body,
    );
  });

  test('GET /ops/api/services/repository/:type/:name returns 200 OK', () async {
    // Arrange
    final repo = harness.trackingServer.manager.get<DeviceRepository>();
    await repo.readyAsync();
    final name = harness.instances.first;
    await createDevice(repo);

    // Act
    final response = await harness.agent.get('/ops/api/services/repository/device/$name?expand=all');

    // Assert
    expect(response.statusCode, 200);
    final meta = Map<String, dynamic>.from(
      await response.body.decode(),
    );
    _assertInstanceMeta(
      name,
      meta,
    );
  });

  test("POST /ops/api/services/repository/:type with 'replay_all' returns 200", () async {
    // Arrange
    final repo = harness.trackingServer.manager.get<DeviceRepository>();
    await repo.readyAsync();
    final name = harness.instances.first;
    await createDevice(repo);

    // Act
    final response = await harness.agent.post(
      '/ops/api/services/repository/device?expand=all',
      body: {'action': 'replay_all'},
    );

    // Assert
    expect(response.statusCode, 200);
    final body = Map<String, dynamic>.from(
      await response.body.decode(),
    );
    _assertItemsMeta(name, body, 'meta');
  });

  test("POST /ops/api/services/repository/:type/:name with 'replay' returns 200", () async {
    // Arrange
    final repo = harness.trackingServer.manager.get<DeviceRepository>();
    await repo.readyAsync();
    final name = harness.instances.first;
    await createDevice(repo);

    // Act
    final response = await harness.agent.post(
      '/ops/api/services/repository/device/$name?expand=all',
      body: {'action': 'replay'},
    );

    // Assert
    expect(response.statusCode, 200);
    final body = Map<String, dynamic>.from(
      await response.body.decode(),
    );
    _assertInstanceMeta(
      name,
      body.mapAt('meta'),
    );
  });

  test("POST /ops/api/services/repository/:type with 'catchup_all' returns 200", () async {
    // Arrange
    final repo = harness.trackingServer.manager.get<DeviceRepository>();
    await repo.readyAsync();
    final name = harness.instances.first;
    await createDevice(repo);

    // Act
    final response = await harness.agent.post(
      '/ops/api/services/repository/device?expand=all',
      body: {'action': 'catchup_all'},
    );

    // Assert
    expect(response.statusCode, 200);
    final body = Map<String, dynamic>.from(
      await response.body.decode(),
    );
    _assertItemsMeta(name, body, 'meta');
  });

  test("POST /ops/api/services/repository/:type/:name with 'catchup' returns 200", () async {
    // Arrange
    final repo = harness.trackingServer.manager.get<DeviceRepository>();
    await repo.readyAsync();
    final name = harness.instances.first;
    await createDevice(repo);

    // Act
    final response = await harness.agent.post(
      '/ops/api/services/repository/device/$name?expand=all',
      body: {'action': 'catchup'},
    );

    // Assert
    expect(response.statusCode, 200);
    final body = Map<String, dynamic>.from(
      await response.body.decode(),
    );
    _assertInstanceMeta(name, body.mapAt('meta'));
  });

  test("POST /ops/api/services/repository/:type with 'rebuild_all' returns 200", () async {
    // Arrange
    final repo = harness.trackingServer.manager.get<DeviceRepository>();
    await repo.readyAsync();
    final name = harness.instances.first;
    await createDevice(repo);

    // Act
    final response = await harness.agent.post(
      '/ops/api/services/repository/device?expand=all',
      body: {'action': 'rebuild_all'},
    );

    // Assert
    expect(response.statusCode, 200);
    final body = Map<String, dynamic>.from(
      await response.body.decode(),
    );
    _assertItemsMeta(name, body, 'meta');
  });

  test("POST /ops/api/services/repository/:type/:name with 'rebuild' returns 200", () async {
    // Arrange
    final repo = harness.trackingServer.manager.get<DeviceRepository>();
    await repo.readyAsync();
    final name = harness.instances.first;
    await createDevice(repo);

    // Act
    final response = await harness.agent.post(
      '/ops/api/services/repository/device/$name?expand=all',
      body: {'action': 'rebuild'},
    );

    // Assert
    expect(response.statusCode, 200);
    final body = Map<String, dynamic>.from(
      await response.body.decode(),
    );
    _assertInstanceMeta(name, body.mapAt('meta'));
  });

  test("POST /ops/api/services/repository/:type with 'repair_all' returns 200", () async {
    // Arrange
    final repo = harness.trackingServer.manager.get<DeviceRepository>();
    await repo.readyAsync();
    final name = harness.instances.first;
    await createDevice(repo);

    // Act
    final response = await harness.agent.post(
      '/ops/api/services/repository/device?expand=all',
      body: {'action': 'repair_all'},
    );

    // Assert
    expect(response.statusCode, 200);
    final body = Map<String, dynamic>.from(
      await response.body.decode(),
    );
    _assertItemsMeta(name, body, 'meta');
    expect(body.elementAt('items/0/after'), isA<Map>());
    expect(body.elementAt('items/0/before'), isA<Map>());
  });

  test("POST /ops/api/services/repository/:type/:name with 'repair' returns 200", () async {
    // Arrange
    final repo = harness.trackingServer.manager.get<DeviceRepository>();
    await repo.readyAsync();
    final name = harness.instances.first;
    await createDevice(repo);

    // Act
    final response = await harness.agent.post(
      '/ops/api/services/repository/device/$name?expand=all',
      body: {'action': 'repair'},
    );

    // Assert
    expect(response.statusCode, 200);
    final body = Map<String, dynamic>.from(
      await response.body.decode(),
    );
    _assertInstanceMeta(name, body.mapAt('meta'));
    expect(body.elementAt('after'), isA<Map>());
    expect(body.elementAt('before'), isA<Map>());
  });
}

void _assertItemsMeta(
  String name,
  Map<String, dynamic> body, [
  String field,
]) {
  final items = body.listAt<Map<String, dynamic>>('items');
  for (var item in items) {
    _assertInstanceMeta(
      name,
      field == null ? item : item.mapAt(field),
    );
  }
}

void _assertInstanceMeta(
  String name,
  Map<String, dynamic> meta,
) {
  // Assert root meta
  expect(meta.elementAt('name'), name);
  expect(meta.elementAt<String>('type'), 'Device');

  // Assert last event meta
  expect(meta.elementAt<int>('lastEvent/number'), 0);
  expect(meta.elementAt<int>('lastEvent/position'), 0);
  expect(meta.elementAt<String>('lastEvent/type'), 'DeviceCreated');

  // Assert queue meta
  expect(meta.elementAt('queue'), isA<Map>());
  expect(meta.elementAt('queue/status'), isA<Map>());
  expect(meta.elementAt('queue/pressure'), isA<Map>());

  // Assert metrics meta
  expect(meta.elementAt('metrics'), isA<Map>());
  expect(meta.elementAt<int>('metrics/events'), 1);
  expect(meta.elementAt('metrics/aggregates'), isA<Map>());
  expect(meta.elementAt('metrics/push'), isA<Map>());

  // Assert connection meta
  expect(meta.elementAt('connection'), isA<Map>());
  expect(meta.elementAt('connection/read'), isA<Map>());
  expect(meta.elementAt('connection/write'), isA<Map>());
}
