import 'dart:io';
import 'package:test/test.dart';

import 'harness.dart';

Future main() async {
  final client = HttpClient();
  final harness = SarSysHarness()
    ..withLogger(debug: false)
    ..withEventStoreMock()
    ..install();

  test('Server should start', () async {
    expect(harness.server.isOpen, isTrue);
  });

  test('Server should be ready', () async {
    expect(harness.server.isReady, isTrue);
  });

  test('api/healthz/alive returns 200 OK', () async {
    final request = await client.get('localhost', 8083, 'api/healthz/alive');
    final response = await request.close();
    expect(response.statusCode, 200);
  });

  test('api/healthz/ready returns 200 OK', () async {
    final request = await client.get('localhost', 8083, 'api/healthz/ready');
    final response = await request.close();
    expect(response.statusCode, 200);
  });
}
