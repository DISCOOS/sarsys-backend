import 'dart:async';

import 'package:sarsys_domain/sarsys_domain.dart';
import 'package:uuid/uuid.dart';
import 'package:test/test.dart';

import 'harness.dart';

Future main() async {
  final harness = SarSysHarness()
    ..withEventStoreMock()
    ..install(restartForEachTest: true);

  test("PATCH /api/trackings/{uuid}/status returns 400 when empty", () async {
    final uuid = Uuid().v4();
    final body = createTracking(uuid);
    expectResponse(
        await harness.agent.post(
          "/api/trackings",
          headers: createAuthn(createAuthnAdmin()),
          body: body,
        ),
        201,
        body: null);
    expectResponse(
      await harness.agent.execute(
        'PATCH',
        "/api/trackings/$uuid/status",
        headers: createAuthn(createAuthnCommander()),
        body: {
          'status': 'tracking',
        },
      ),
      400,
    );
  });

  test("PATCH /api/trackings/{uuid}/status returns 400 when closed", () async {
    final repo = harness.channel.manager.get<TrackingRepository>();
    await repo.readyAsync();
    final uuid = Uuid().v4();
    await _createWithStatus(repo, uuid, 'closed');
    expectResponse(
      await harness.agent.execute(
        'PATCH',
        "/api/trackings/$uuid/status",
        headers: createAuthn(createAuthnCommander()),
        body: {
          'status': 'tracking',
        },
      ),
      400,
    );
  });

  test("PATCH /api/trackings/{uuid}/status returns 204 when paused", () async {
    final repo = harness.channel.manager.get<TrackingRepository>();
    await repo.readyAsync();
    final uuid = Uuid().v4();
    await _createWithStatus(repo, uuid, 'paused');
    expectResponse(
      await harness.agent.execute(
        'PATCH',
        "/api/trackings/$uuid/status",
        headers: createAuthn(createAuthnCommander()),
        body: {
          'status': 'tracking',
        },
      ),
      204,
    );
  });

  test("PATCH /api/trackings/{uuid}/status returns 204 when tracking", () async {
    final repo = harness.channel.manager.get<TrackingRepository>();
    await repo.readyAsync();
    final uuid = Uuid().v4();
    await _createWithStatus(repo, uuid, 'tracking');
    expectResponse(
      await harness.agent.execute(
        'PATCH',
        "/api/trackings/$uuid/status",
        headers: createAuthn(createAuthnCommander()),
        body: {
          'status': 'tracking',
        },
      ),
      204,
    );
  });
}

FutureOr<Map<String, dynamic>> _createWithStatus(
  TrackingRepository repo,
  String uuid,
  String status,
) async {
  final data = createTracking(uuid, status: status);
  await repo.execute(CreateTracking(data));
  return data;
}
