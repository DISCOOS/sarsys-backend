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

  test('sarsysctl auth', () async {
    final result = await expectLater(() => run(['auth']), throwsA(isA<UsageException>()));
    expect(result, isNull);
  });

  test('sarsysctl auth init', () async {
    final result = await run(['auth', 'init']);
    expect(result, isNotEmpty);
  });

  test('sarsysctl auth update', () async {
    final init = await run(['auth', 'init']);
    expect(init, isNotEmpty);
    final update = await run(['auth', 'update']);
    expect(update, isNotEmpty);
  });

  test('sarsysctl auth check', () async {
    final init = await run(['auth', 'init']);
    expect(init, isNotEmpty);
    final update = await run(['auth', 'check']);
    expect(update, isNotEmpty);
  });
}
