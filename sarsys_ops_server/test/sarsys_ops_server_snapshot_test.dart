import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:event_source/event_source.dart';
import 'package:collection_x/collection_x.dart';
import 'package:sarsys_app_server/sarsys_app_server.dart';
import 'package:sarsys_domain/sarsys_domain.dart';
import 'package:sarsys_ops_server_test/sarsys_ops_server_test.dart';
import 'package:test/test.dart';

Future main() async {
  final harness = SarSysOpsHarness()
    ..withContext()
    ..withTrackingServer()
    ..withSnapshots()
    ..withLogger(debug: false)
    ..install();

  test('GET /ops/api/services/snapshot/:type returns 200 OK', () async {
    // Arrange
    await _prepare(harness, true, force: false);
    final name = harness.instances.first;

    // Act
    final response = await harness.agent.get('/ops/api/services/snapshot/device?expand=all');

    // Assert
    expect(response.statusCode, 200);
    final body = Map<String, dynamic>.from(
      await response.body.decode(),
    );
    _assertItemsMeta(name, 0, 0, body, 'meta');
  });

  test('GET /ops/api/services/snapshot/:type/:name returns 200 OK', () async {
    // Arrange
    await _prepare(harness, true, force: true);
    final name = harness.instances.first;

    // Act
    final response = await harness.agent.get('/ops/api/services/snapshot/device/$name?expand=all');

    // Assert
    expect(response.statusCode, 200);
    final body = Map.from(
      await response.body.decode(),
    );
    _assertInstanceMeta(name, 1, 1, body.mapAt<String, dynamic>('meta'));
  });

  test("POST /ops/api/services/snapshot/:type with 'save_all' returns 200", () async {
    // Arrange
    await _prepare(harness, true, force: false);
    final name = harness.instances.first;

    // Act
    final response = await harness.agent.post(
      '/ops/api/services/snapshot/device?expand=all',
      body: {
        'action': 'save_all',
        'params': {'force': true}
      },
    );

    // Assert
    expect(response.statusCode, 200);
    final body = Map<String, dynamic>.from(
      await response.body.decode(),
    );
    _assertItemsMeta(name, 1, 1, body, 'meta');
  });

  test("POST /ops/api/services/snapshot/:type/:name with 'save' returns 200", () async {
    // Arrange
    await _prepare(harness, true, force: true);
    final name = harness.instances.first;

    // Act
    final response = await harness.agent.post(
      '/ops/api/services/snapshot/device/$name?expand=all',
      body: {
        'action': 'save',
        'params': {'force': true}
      },
    );

    // Assert
    expect(response.statusCode, 200);
    final body = Map<String, dynamic>.from(
      await response.body.decode(),
    );
    _assertInstanceMeta(name, 2, 1, body.mapAt('meta'));
  });

  test("POST /ops/api/services/snapshot/:type with 'configure_all' returns 200", () async {
    // Arrange
    await _prepare(harness, true, force: true);
    final name = harness.instances.first;

    // Act
    final response = await harness.agent.post(
      '/ops/api/services/snapshot/device?expand=all',
      body: {
        'action': 'configure_all',
        'params': {
          'config': {
            'keep': 15,
            'threshold': 150,
            'automatic': false,
          }
        }
      },
    );

    // Assert
    expect(response.statusCode, 200);
    final body = Map<String, dynamic>.from(
      await response.body.decode(),
    );
    _assertItemsMeta(name, 1, 1, body, 'meta');
  });

  test("POST /ops/api/services/snapshot/:type/:name with 'configure' returns 200", () async {
    // Arrange
    await _prepare(harness, true, force: false);
    final name = harness.instances.first;

    // Act
    final response = await harness.agent.post(
      '/ops/api/services/snapshot/device/$name?expand=all',
      body: {
        'action': 'configure',
        'params': {
          'config': {
            'keep': 15,
            'threshold': 150,
            'automatic': false,
          }
        }
      },
    );

    // Assert
    expect(response.statusCode, 200);
    final body = Map<String, dynamic>.from(
      await response.body.decode(),
    );
    final config = body.mapAt('meta/config');
    expect(config.elementAt('keep'), 15);
    expect(config.elementAt('threshold'), 150);
    expect(config.elementAt('automatic'), false);
  });

  test("POST /ops/api/services/snapshot/upload/:type returns 200", () async {
    // Arrange
    final snapshot = await _prepare(harness, true, force: true);
    final name = harness.instances.first;
    final file = File('test/.hive/device.hive');
    expect(file.existsSync(), isTrue);

    // Created MultipartFile request
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${harness.agent.baseURL}/ops/api/services/snapshot/upload/device?expand=all'),
    );
    request.files.add(http.MultipartFile.fromBytes(
      'device',
      await file.readAsBytes(),
      filename: 'device.hive',
      contentType: MediaType('application', 'octet-stream'),
    ));

    // Act
    final response = await request.send();
    expect(response.statusCode, 200, reason: response.reasonPhrase);

    final body = jsonDecode(
      await response.stream.bytesToString(),
    ) as Map;

    // Assert
    _assertItemsMeta(name, 1, 1, body, 'meta');
    expect(body.elementAt('items/0/meta/uuid'), snapshot.uuid);
  });

  test("POST /ops/api/services/snapshot/upload/:type/:name returns 200", () async {
    // Arrange
    final snapshot = await _prepare(harness, true, force: true);
    final name = harness.instances.first;
    final file = File('test/.hive/device.hive');
    expect(file.existsSync(), isTrue);

    // Created MultipartFile request
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${harness.agent.baseURL}/ops/api/services/snapshot/upload/device/$name?expand=all'),
    );
    request.files.add(http.MultipartFile.fromBytes(
      'device',
      await file.readAsBytes(),
      filename: 'device.hive',
      contentType: MediaType('application', 'octet-stream'),
    ));

    // Act
    final response = await request.send();
    expect(response.statusCode, 200, reason: response.reasonPhrase);

    final body = jsonDecode(
      await response.stream.bytesToString(),
    ) as Map;

    // Assert
    _assertInstanceMeta(name, 1, 1, body.mapAt('meta'));
    expect(body.elementAt('meta/uuid'), snapshot.uuid);
  });

  test("GET /ops/api/services/snapshot/download/:type/:name returns 200", () async {
    // Arrange
    final snapshot = await _prepare(harness, true, force: true);
    final name = harness.instances.first;

    // Act
    final response = await harness.agent.get(
      '/ops/api/services/snapshot/download/device/$name',
    );

    // Assert
    expect(response.statusCode, 200);

    // Download file from server
    final prefix = '${DateTime.now().millisecondsSinceEpoch}';
    final path = '${Directory.systemTemp.path}';
    final file = File('$path/$prefix-device.hive');
    file.openWrite();
    final stream = response.body.decode().asStream();
    await for (var items in stream) {
      await file.writeAsBytes(List.from(items as List));
    }

    // Assert downloaded file
    final storage = Storage.fromType<Device>();
    await storage.load(path: path);

    expect(storage.contains(snapshot.uuid), isTrue);
    file.deleteSync();
  });
}

Future<SnapshotModel> _prepare(
  SarSysOpsHarness harness,
  bool automatic, {
  bool force = false,
}) async {
  final repo = harness.trackingServer.manager.get<DeviceRepository>();
  await repo.readyAsync();
  repo.store.snapshots.automatic = automatic;
  await createDevice(repo);
  final snapshot = repo.save(
    force: force,
  );
  // Wait for save to complete
  await repo.store.snapshots.onIdle;
  return snapshot;
}

void _assertItemsMeta(
  String name,
  int snapshots,
  int aggregates,
  Map<String, dynamic> body, [
  String field,
]) {
  final items = body.listAt<Map<String, dynamic>>('items');
  for (var item in items) {
    _assertInstanceMeta(
      name,
      snapshots,
      aggregates,
      field == null ? item : item.mapAt(field),
    );
  }
}

void _assertInstanceMeta(
  String name,
  int snapshots,
  int aggregates,
  Map<String, dynamic> meta,
) {
  // Assert root meta
  expect(meta.elementAt('name'), name);
  expect(meta.elementAt('type'), 'Device');

  // Assert metrics meta
  expect(meta.elementAt('metrics'), isA<Map>());
  expect(meta.elementAt<int>('metrics/snapshots'), snapshots);
  expect(meta.elementAt('metrics/isPartial'), isFalse);
  expect(meta.elementAt('metrics/save'), isA<Map>());

  // Assert connection meta
  expect(meta.elementAt('aggregates'), isA<Map>());
  expect(meta.elementAt('aggregates/count'), aggregates);
  expect(meta.elementAt('aggregates/items'), aggregates > 0 ? isA<List>() : isNull);
}
