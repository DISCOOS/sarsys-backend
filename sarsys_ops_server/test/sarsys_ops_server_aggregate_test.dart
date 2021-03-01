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

  test('GET /ops/api/services/aggregate/:type/:uuid returns 200 OK', () async {
    // Arrange
    final repo = harness.trackingServer.manager.get<DeviceRepository>();
    await repo.readyAsync();
    final name = harness.instances.first;
    final uuid = await createDevice(repo);

    // Act
    final response = await harness.agent.get('/ops/api/services/aggregate/device/$uuid?expand=all');

    // Assert
    expect(response.statusCode, 200);
    final body = Map<String, dynamic>.from(
      await response.body.decode(),
    );
    _assertItemsMeta(
      name,
      [uuid],
      body,
    );
  });

  test('GET /ops/api/services/aggregate/:type returns 200 OK', () async {
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
    final items = body.listAt<Map<String, dynamic>>('items');
    expect(items.length, 1);
    expect(items[0].elementAt('type'), 'device');
    expect(items[0].elementAt('name'), name);
    expect(items[0].elementAt('count'), 1);
    expect(items[0].elementAt('query'), query);
    expect(items[0].elementAt('items/0/uuid'), uuid);
    expect(items[0].elementAt('items/0/value/uuid'), uuid);
    expect(items[0].elementAt('items/0/path'), r"$['data']");
  });

  test('GET /ops/api/services/aggregate/:type/:uuid/:name returns 200 OK', () async {
    // Arrange
    final repo = harness.trackingServer.manager.get<DeviceRepository>();
    await repo.readyAsync();
    final name = harness.instances.first;
    final uuid = await createDevice(repo);

    // Act
    final response = await harness.agent.get('/ops/api/services/aggregate/device/$uuid/$name?expand=all');

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

  test("POST /ops/api/services/aggregate/:type/:uuid with 'replay_all' returns 200", () async {
    // Arrange
    final repo = harness.trackingServer.manager.get<DeviceRepository>();
    await repo.readyAsync();
    final name = harness.instances.first;
    final uuid = await createDevice(repo);

    // Act
    final response = await harness.agent.post(
      '/ops/api/services/aggregate/device/$uuid?expand=all',
      body: {'action': 'replay_all'},
    );

    // Assert
    expect(response.statusCode, 200);
    final body = Map<String, dynamic>.from(
      await response.body.decode(),
    );
    _assertItemsMeta(name, [uuid], body, 'meta');
  });

  test("POST /ops/api/services/aggregate/:type/:uuid/:name with 'replay' returns 200", () async {
    // Arrange
    final repo = harness.trackingServer.manager.get<DeviceRepository>();
    await repo.readyAsync();
    final name = harness.instances.first;
    final uuid = await createDevice(repo);

    // Act
    final response = await harness.agent.post(
      '/ops/api/services/aggregate/device/$uuid/$name?expand=all',
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

  test("POST /ops/api/services/aggregate/:type/:uuid with 'catchup_all' returns 200", () async {
    // Arrange
    final repo = harness.trackingServer.manager.get<DeviceRepository>();
    await repo.readyAsync();
    final name = harness.instances.first;
    final uuid = await createDevice(repo);

    // Act
    final response = await harness.agent.post(
      '/ops/api/services/aggregate/device/$uuid?expand=all',
      body: {'action': 'catchup_all'},
    );

    // Assert
    expect(response.statusCode, 200);
    final body = Map<String, dynamic>.from(
      await response.body.decode(),
    );
    _assertItemsMeta(name, [uuid], body, 'meta');
  });

  test("POST /ops/api/services/aggregate/:type/:uuid/:name with 'catchup' returns 200", () async {
    // Arrange
    final repo = harness.trackingServer.manager.get<DeviceRepository>();
    await repo.readyAsync();
    final name = harness.instances.first;
    final uuid = await createDevice(repo);

    // Act
    final response = await harness.agent.post(
      '/ops/api/services/aggregate/device/$uuid/$name?expand=all',
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

  test("POST /ops/api/services/aggregate/:type/:uuid with 'replace_all' returns 200", () async {
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
      '/ops/api/services/aggregate/device/$uuid?expand=all',
      body: {
        'action': 'replace_all',
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
    _assertItemsMeta(name, [uuid], body, 'meta');
    expect(body.mapAt('items/0/meta/data'), equals(data2));
    expect(repo.get(uuid).data, equals(data2));
  });

  test("POST /ops/api/services/aggregate/:type/:uuid/:name with 'replace' returns 200", () async {
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
      '/ops/api/services/aggregate/device/$uuid/$name?expand=all',
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

void _assertItemsMeta(
  String name,
  List<String> uuids,
  Map<String, dynamic> body, [
  String field,
]) {
  var i = 0;
  final items = body.listAt<Map<String, dynamic>>('items');
  for (var item in items) {
    _assertInstanceMeta(
      name,
      uuids[i++],
      field == null ? item : item.mapAt(field),
    );
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
