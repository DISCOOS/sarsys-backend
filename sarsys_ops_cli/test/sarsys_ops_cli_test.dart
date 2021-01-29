import 'dart:convert';
import 'dart:io';

import 'package:sarsys_ops_cli/src/run.dart';
import 'package:test/test.dart';

Future main() async {
  test('sarsysctl init', () async {
    final result = await run(['init']);
    print(result);
    expect(result, isNotEmpty);
  });

  test('sarsysctl auth', () async {
    final result = await run(['auth']);
    print(result);
    expect(result, isNotEmpty);
  });

  test('sarsysctl status', () async {
    final result = await run(['status']);
    print(result);
    expect(result, isNotEmpty);
  });

  test('sarsysctl help', () async {
    expect(await run(['help']), isNull);
  });

  test('sarsysctl help init', () async {
    expect(await run(['help', 'init']), isNull);
  });

  test('sarsysctl help auth', () async {
    expect(await run(['help', 'init']), isNull);
  });

  test('sarsysctl help status', () async {
    expect(await run(['help', 'status']), isNull);
  });
}
