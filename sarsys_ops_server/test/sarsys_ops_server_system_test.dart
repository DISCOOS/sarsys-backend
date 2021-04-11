import 'dart:async';

import 'package:collection_x/collection_x.dart';
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

  test('GET /ops/api/system/status/:type returns 200 OK', () async {
    // Arrange
    const module = 'sarsys-tracking-server';

    // Act
    final response = await harness.agent.get('/ops/api/system/status/$module?expand=metrics');

    // Assert
    expect(response.statusCode, 200);
    final body = Map.from(await response.body.decode());
    final instances = body.listAt('instances');
    expect(instances.length, 1);
    expect(body.elementAt('name'), module);
    final instance = body.mapAt<String, dynamic>('instances/0');
    expect(instance.elementAt('name'), SarSysOpsHarness.trackingInstance0);
    expect(instance.elementAt('status/health/alive'), isFalse);
    expect(instance.elementAt('status/health/ready'), isFalse);
    expect(instance.elementAt('status/conditions/0/type'), 'Unknown');
    expect(instance.elementAt('metrics/usage'), isNotEmpty);
    expect(instance.elementAt('metrics/limits'), isNotEmpty);
  });

  test('GET /ops/api/system/status/:type/:name returns 200 OK', () async {
    // Arrange
    const module = 'sarsys-tracking-server';
    const instance = 'sarsys-tracking-server-0';

    // Act
    final response = await harness.agent.get('/ops/api/system/status/$module/$instance?expand=metrics');

    // Assert
    expect(response.statusCode, 200);
    final body = Map.from(await response.body.decode());
    expect(body.elementAt('name'), SarSysOpsHarness.trackingInstance0);
    expect(body.elementAt('status/health/alive'), isFalse);
    expect(body.elementAt('status/health/ready'), isFalse);
    expect(body.elementAt('status/conditions/0/type'), 'Unknown');
    expect(body.elementAt('metrics/usage'), isNotEmpty);
    expect(body.elementAt('metrics/limits'), isNotEmpty);
  });
}
