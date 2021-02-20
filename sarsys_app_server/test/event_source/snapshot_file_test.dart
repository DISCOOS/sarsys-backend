import 'dart:convert';
import 'dart:io';

import 'package:event_source/src/models/snapshot_model.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:sarsys_domain/sarsys_domain.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

import 'package:sarsys_app_server_test/sarsys_app_server_test.dart';

Future main() async {
  final harness = SarSysAppHarness()
    ..withContext()
    ..withSnapshot()
    ..withEventStoreMock()
    ..install(restartForEachTest: true);

  group('Snapshot file operations', () {
    test("GET /api/snapshots/device/download returns status code 416 on pod mismatch", () async {
      // Arrange
      await _prepare(harness, true);

      final request = harness.agent.get("/api/snapshots/device/download", headers: {
        'x-if-match-pod': 'foo',
      });
      final response = expectResponse(await request, 416);
      final data = await response.body.decode();

      expect(data, isEmpty);
    });

    test("GET /api/snapshots/device/download returns status code 200", () async {
      // Arrange
      final snapshot = await _prepare(harness, false);

      final request = harness.agent.get("/api/snapshots/device/download", headers: {
        'x-if-match-pod': 'bar',
      });
      final response = expectResponse(await request, 200);

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

    test("POST /api/snapshots/device/upload valid file returns status code 200", () async {
      // Arrange
      final snapshot = await _prepare(harness, false);
      final file = File('test/.hive/device.hive');

      // Created MultipartFile request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse("${harness.agent.baseURL}/api/snapshots/device/upload"),
      );
      request.files.add(http.MultipartFile.fromBytes(
        'device',
        await file.readAsBytes(),
        filename: 'device.hive',
        contentType: MediaType('application', 'octet-stream'),
      ));

      // Act
      final response = await request.send();
      final data = jsonDecode(
        await response.stream.bytesToString(),
      ) as Map;

      // Assert
      expect(response.statusCode, 200);
      expect(data, isNotNull);
      expect(data.elementAt('uuid'), isNotEmpty);
      expect(data.elementAt('uuid'), equals(snapshot.uuid));
    });

    test("POST /api/snapshots/device/upload invalid file returns status code 400", () async {
      // Arrange
      final snapshot = await _prepare(harness, true);
      final snapshots = harness.channel.manager.get<DeviceRepository>().store.snapshots;
      final file = File('test/.hive/device-broken.hive');
      await file.writeAsBytes(List.filled(100, -1));

      // Created MultipartFile request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse("${harness.agent.baseURL}/api/snapshots/device/upload"),
      );
      request.files.add(http.MultipartFile.fromBytes(
        'device',
        await file.readAsBytes(),
        filename: 'device.hive',
        contentType: MediaType('application', 'octet-stream'),
      ));

      // Act
      final response = await request.send();

      // Assert
      expect(response.statusCode, 400);
      expect(snapshots.last, snapshot);
      expect(snapshots.isReady, isTrue);
    });
  }, skip: true);
}

Future<SnapshotModel> _prepare(SarSysAppHarness harness, bool withSnapshots) async {
  final uuid = Uuid().v4();
  final body = createDevice(uuid);
  final repo = harness.channel.manager.get<DeviceRepository>();
  repo.store.snapshots.automatic = withSnapshots;
  expectResponse(await harness.agent.post("/api/devices", body: body), 201, body: null);
  final snapshot = repo.save();
  // Wait for save to complete
  await repo.store.snapshots.onIdle;
  return snapshot;
}
