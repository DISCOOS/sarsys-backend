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

  test('GET /ops/api/services/aggregate/:type returns 200 OK', () async {
    // Arrange
    final repo = harness.trackingServer.manager.get<DeviceRepository>();
    await repo.readyAsync();
    final name = harness.instances.first;
    final uuid = await createDevice(repo);

    // Act
    final response = await harness.agent.get(
      '/ops/api/services/aggregate/device?expand=all',
    );

    // Assert
    expect(response.statusCode, 200);
    final body = Map<String, dynamic>.from(
      await response.body.decode(),
    );
    _assertSearchResult(
      'device',
      name,
      uuid,
      body,
    );
  });

  test('GET /ops/api/services/aggregate/:type/:name returns 200 OK', () async {
    // Arrange
    final repo = harness.trackingServer.manager.get<DeviceRepository>();
    await repo.readyAsync();
    final name = harness.instances.first;
    final uuid = await createDevice(repo);

    // Act
    final response = await harness.agent.get(
      '/ops/api/services/aggregate/device/$name?expand=all',
    );

    // Assert
    expect(response.statusCode, 200);
    final body = Map<String, dynamic>.from(
      await response.body.decode(),
    );
    _assertSearchResult(
      'device',
      name,
      uuid,
      body,
    );
  });

  test('GET /ops/api/services/aggregate/:type with query returns 200 OK', () async {
    // Arrange
    final repo = harness.trackingServer.manager.get<DeviceRepository>();
    await repo.readyAsync();
    final name = harness.instances.first;
    final uuid = await createDevice(repo);
    final query = ".data[?(@.uuid=='$uuid')]";

    // Act
    final response = await harness.agent.get(
      '/ops/api/services/aggregate/device?expand=all&query=$query',
    );

    // Assert
    expect(response.statusCode, 200);
    final body = Map<String, dynamic>.from(
      await response.body.decode(),
    );
    _assertSearchResult(
      'device',
      name,
      uuid,
      body,
    );
    final items = body.listAt<Map<String, dynamic>>('items');
    expect(items.length, 1);
    expect(items[0].elementAt('type'), 'device');
    expect(items[0].elementAt('name'), name);
    expect(items[0].elementAt('count'), 1);
    expect(items[0].elementAt('query'), query);
    expect(items[0].elementAt('items/0/uuid'), uuid);
    expect(items[0].elementAt('items/0/path'), r"$['data']");
  });

  test('GET /ops/api/services/aggregate/:type/:name/:uuid returns 200 OK', () async {
    // Arrange
    final repo = harness.trackingServer.manager.get<DeviceRepository>();
    await repo.readyAsync();
    final name = harness.instances.first;
    final uuid = await createDevice(repo);

    // Act
    final response = await harness.agent.get('/ops/api/services/aggregate/device/$name/$uuid?expand=all');

    // Assert
    expect(response.statusCode, 200);
    final meta = Map<String, dynamic>.from(
      await response.body.decode(),
    );
    _assertInstanceMeta(
      name,
      uuid,
      meta,
    );
  });

  test("POST /ops/api/services/aggregate/:type/:name/:uuid with 'replay' returns 200", () async {
    // Arrange
    final repo = harness.trackingServer.manager.get<DeviceRepository>();
    await repo.readyAsync();
    final name = harness.instances.first;
    final uuid = await createDevice(repo);

    // Act
    final response = await harness.agent.post(
      '/ops/api/services/aggregate/device/$name/$uuid?expand=all',
      body: {'action': 'replay'},
    );

    // Assert
    expect(response.statusCode, 200);
    final body = Map<String, dynamic>.from(
      await response.body.decode(),
    );
    _assertInstanceMeta(
      name,
      uuid,
      body.mapAt('meta'),
    );
  });

  test("POST /ops/api/services/aggregate/:type/:name/:uuid with 'catchup' returns 200", () async {
    // Arrange
    final repo = harness.trackingServer.manager.get<DeviceRepository>();
    await repo.readyAsync();
    final name = harness.instances.first;
    final uuid = await createDevice(repo);

    // Act
    final response = await harness.agent.post(
      '/ops/api/services/aggregate/device/$name/$uuid?expand=all',
      body: {'action': 'catchup'},
    );

    // Assert
    expect(response.statusCode, 200);
    final body = Map<String, dynamic>.from(
      await response.body.decode(),
    );
    _assertInstanceMeta(
      name,
      uuid,
      body.mapAt('meta'),
    );
  });

  test("POST /ops/api/services/aggregate/:type/:name/:uuid with 'replace' returns 200", () async {
    // Arrange
    final repo = harness.trackingServer.manager.get<DeviceRepository>();
    await repo.readyAsync();
    final name = harness.instances.first;
    final uuid = await createDevice(repo);
    final data1 = repo.get(uuid).data;
    final data2 = Map.from(data1)
      ..addAll(
        {'property1': "value1"},
      );

    // Act
    final response = await harness.agent.post(
      '/ops/api/services/aggregate/device/$name/$uuid?expand=all',
      body: {
        'action': 'replace',
        'params': {
          'data': data2,
        }
      },
    );

    // Assert
    expect(response.statusCode, 200);
    final body = Map<String, dynamic>.from(
      await response.body.decode(),
    );
    _assertInstanceMeta(
      name,
      uuid,
      body.mapAt('meta'),
    );
    expect(body.mapAt('meta/data'), equals(data2));
    expect(repo.get(uuid).data, equals(data2));
  });
}

void _assertSearchResult(
  String type,
  String name,
  String uuid,
  Map<String, dynamic> result,
) {
  for (var module in result.listAt<Map>('items')) {
    expect(module.elementAt('type'), type);
    expect(module.elementAt('name'), name);
    expect(module.elementAt('items'), isA<List>());
    for (var instance in module.listAt<Map>('items')) {
      expect(instance.elementAt('meta'), isA<Map>());
      _assertInstanceMeta(name, uuid, instance.mapAt('meta'));
    }
  }
}

void _assertInstanceMeta(
  String name,
  String uuid,
  Map<String, dynamic> meta,
) {
  expect(meta.elementAt('name'), name);
  expect(meta.elementAt<String>('uuid'), uuid);
  expect(meta.elementAt<String>('type'), 'Device');
  expect(meta.elementAt('createdBy'), isA<Map>());
  expect(meta.elementAt('changedBy'), isA<Map>());
  expect(meta.elementAt('deletedBy'), isNull);
  expect(meta.elementAt('applied/count'), 1);
  expect(meta.elementAt('applied/items'), isA<List>());
  expect(meta.elementAt('pending/count'), 0);
  expect(meta.elementAt('pending/items'), isNull);
  expect(meta.elementAt('skipped/count'), 0);
  expect(meta.elementAt('skipped/items'), isNull);
  expect(meta.elementAt('data'), isA<Map>());
}
