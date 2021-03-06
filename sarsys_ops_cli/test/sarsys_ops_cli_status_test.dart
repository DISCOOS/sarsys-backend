import 'dart:io';

import 'package:sarsys_ops_cli/sarsys_ops_cli.dart';
import 'package:sarsys_ops_cli/src/run.dart';
import 'package:test/test.dart';

import 'harness.dart';

Future main() async {
  SarSysCliHarness()
    ..withTrackingServer()
    ..withLogger(debug: false)
    ..withContext(
      apiSpecPath: '../sarsys_ops_server/web/sarsys-ops.json',
    )
    ..install(
      file: '../sarsys_ops_server/config.src.yaml',
    );

  tearDown(() {
    final file = Directory(appDataDir);
    file.deleteSync(recursive: true);
  });

  test('sarsysctl status all', () async {
    final result = await run([
      'status',
      'all',
      '-v',
    ]);
    expect(result, isNotEmpty);
  });

  test('sarsysctl status app', () async {
    final result = await run([
      'status',
      'app',
      '-v',
    ]);
    expect(result, isNotEmpty);
  });
  test('sarsysctl status app -i {instance}', () async {
    final result = await run([
      'status',
      'app',
      '-v',
    ]);
    expect(result, isNotEmpty);
  });

  test('sarsysctl status tracking', () async {
    final result = await run([
      'status',
      'app',
      '-v',
    ]);
    expect(result, isNotEmpty);
  });
  test('sarsysctl status tracking -i {instance}', () async {
    final result = await run([
      'status',
      'tracking',
      '-i',
      'sarsys-tracking-server-1',
      '-v',
    ]);
    expect(result, isNotEmpty);
  });
}
