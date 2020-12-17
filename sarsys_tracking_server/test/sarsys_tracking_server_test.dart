import 'package:test/test.dart';

import 'harness.dart';

Future main() async {
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
}
