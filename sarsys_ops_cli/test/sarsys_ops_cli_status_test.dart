import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:sarsys_ops_cli/sarsys_ops_cli.dart';
import 'package:sarsys_ops_cli/src/run.dart';
import 'package:test/test.dart';

import 'harness.dart';

Future main() async {
  final harness = SarSysCliHarness()
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

  test('sarsysctl status module', () async {
    final result = await run([
      'status',
      'module',
      '-m',
      'sarsys-tracking-server',
      '-v',
    ]);
    expect(result, isNotEmpty);
  });
}
