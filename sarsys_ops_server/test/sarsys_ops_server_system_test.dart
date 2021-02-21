import 'dart:async';

import 'package:event_source/event_source.dart';
import 'package:sarsys_app_server/sarsys_app_server.dart';
import 'package:sarsys_ops_server_test/sarsys_ops_server_test.dart';
import 'package:test/test.dart';

Future main() async {
  final harness = SarSysOpsHarness()
    ..withLogger(debug: false)
    ..withTrackingServer()
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
    final response = await harness.agent.get('/ops/api/system/status?expand=metrics');
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
    final instance = statuses.mapAt<String, dynamic>('sarsys-tracking-server/instances/0');
    expect(instance.elementAt('name'), SarSysOpsHarness.trackingInstance0);
    expect(instance.elementAt('status/health/alive'), isFalse);
    expect(instance.elementAt('status/health/ready'), isFalse);
    expect(instance.elementAt('status/conditions/0/type'), 'Unknown');
    expect(instance.elementAt('metrics/usage'), isNotEmpty);
    expect(instance.elementAt('metrics/limits'), isNotEmpty);
  });
}
