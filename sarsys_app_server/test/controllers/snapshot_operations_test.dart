import 'package:event_source/src/models/snapshot_model.dart';
import 'package:sarsys_domain/sarsys_domain.dart';
import 'package:uuid/uuid.dart';
import 'package:test/test.dart';

import 'harness.dart';

Future main() async {
  final harness = SarSysHttpHarness()
    ..withContext()
    ..withSnapshot()
    ..withEventStoreMock()
    ..install(restartForEachTest: true);

  test("GET /api/snapshots/device returns status code 416 on pod mismatch", () async {
    // Arrange
    await _prepare(harness, true);

    final request = harness.agent.get("/api/snapshots/device", headers: {
      'x-if-match-pod': 'foo',
    });
    final response = expectResponse(await request, 416);
    final data = await response.body.decode();

    expect(data, isEmpty);
  });

  test("GET /api/snapshots/device returns status code 200", () async {
    // Arrange
    await _prepare(harness, true);

    final request = harness.agent.get("/api/snapshots/device", headers: {
      'x-if-match-pod': 'bar',
    });
    final response = expectResponse(await request, 200);
    final data = await response.body.decode();

    expect(data, isNotNull);
  });

  test("POST /api/snapshots/device returns status code 20 for action 'save' when repo is unchanged", () async {
    // Arrange
    await _prepare(harness, false);

    // Save new snapshot
    final request = harness.agent.post("/api/snapshots/device", body: {
      'action': 'save',
      'params': {
        'keep': 100,
        'threshold': 1000,
        'automatic': false,
      }
    });
    expectResponse(await request, 204);
  });

  test("POST /api/snapshots/device returns status code 200 for action 'save'", () async {
    // Arrange
    final snapshot = await _prepare(harness, false);
    final repo = harness.channel.manager.get<DeviceRepository>();

    // Ensure that more events are added
    await repo.execute(CreateDevice({'uuid': Uuid().v4()}));

    // Save new snapshot
    final request = harness.agent.post("/api/snapshots/device", body: {
      'action': 'save',
      'params': {
        'keep': 100,
        'threshold': 1000,
        'automatic': false,
      }
    });
    final response = expectResponse(await request, 200);
    final data = await response.body.decode() as Map;

    expect(data, isNotNull);
    expect(data.elementAt('config/keep'), 100);
    expect(data.elementAt('config/threshold'), 1000);
    expect(data.elementAt('config/automatic'), isFalse);
    expect(data.elementAt('uuid'), isNotNull);
    expect(data.elementAt('uuid'), isNot(equals(snapshot.uuid)));
  });
}

Future<SnapshotModel> _prepare(SarSysHttpHarness harness, bool withSnapshots) async {
  final uuid = Uuid().v4();
  final body = createDevice(uuid);
  final repo = harness.channel.manager.get<DeviceRepository>();
  repo.store.snapshots.automatic = withSnapshots;
  expectResponse(await harness.agent.post("/api/devices", body: body), 201, body: null);
  final snapshot = repo.save();
  return snapshot;
}
