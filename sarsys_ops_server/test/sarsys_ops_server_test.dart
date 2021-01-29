import 'package:test/test.dart';

import 'harness.dart';

Future main() async {
  final harness = SarSysOpsHarness()
    ..withLogger(debug: false)
    ..withContext()
    ..install();

  test('GET /ops/api/healthz/alive returns 200 OK', () async {
    final response = await harness.agent.get('/ops/api/healthz/alive');
    expect(response.statusCode, 200);
  });

  test('GET /ops/api/healthz/ready returns 200 OK', () async {
    final response = await harness.agent.get('/ops/api/healthz/ready');
    expect(response.statusCode, 200);
  });
}
