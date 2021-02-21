import 'dart:io';

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

  test('sarsysctl tracking status', () async {
    // Arrange
    harness.writeOpsConfig();
    // Act
    final status = await run(['tracking', 'status']);
    // Assert
    expect(status, isNotEmpty);
  });

  test('sarsysctl tracking add', () async {
    // Arrange
    harness.writeOpsConfig();
    // Act
    final status = await run([
      'tracking',
      'add',
      '-s',
      'server1',
      '-u',
      'uuid1,uuid2',
    ]);
    // Assert
    expect(status, isNotEmpty);
  });

  test('sarsysctl tracking remove', () async {
    // Arrange
    harness.writeOpsConfig();
    // Act
    final status = await run([
      'tracking',
      'remove',
      '-s',
      'server1',
      '-u',
      'uuid1,uuid2',
    ]);
    // Assert
    expect(status, isNotEmpty);
  });

  test('sarsysctl tracking start', () async {
    // Arrange
    harness.writeOpsConfig();
    // Act
    final status = await run([
      'tracking',
      'start',
      '-s',
      'server1',
    ]);
    // Assert
    expect(status, isNotEmpty);
  });

  test('sarsysctl tracking stop', () async {
    // Arrange
    harness.writeOpsConfig();
    // Act
    final status = await run([
      'tracking',
      'stop',
      '-s',
      'server1',
    ]);
    // Assert
    expect(status, isNotEmpty);
  });
}
