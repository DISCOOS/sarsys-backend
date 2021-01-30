import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:sarsys_ops_cli/sarsys_ops_cli.dart';
import 'package:sarsys_ops_cli/src/run.dart';
import 'package:test/test.dart';

Future main() async {
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

  test('sarsysctl status', () async {
    final result = await run(['status']);
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

  test('sarsysctl help', () async {
    expect(await run(['help']), isNull);
  });

  test('sarsysctl help auth', () async {
    expect(await run(['help', 'auth']), isNull);
  });

  test('sarsysctl help auth init', () async {
    expect(await run(['help', 'auth', 'init']), isNull);
  });

  test('sarsysctl help status', () async {
    expect(await run(['help', 'status']), isNull);
  });
}
