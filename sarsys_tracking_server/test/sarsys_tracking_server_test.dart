import 'package:sarsys_http_core/sarsys_http_core.dart';
import 'package:sarsys_tracking_server/sarsys_tracking_server.dart';
import 'package:sarsys_tracking_server_test/sarsys_tracking_server_test.dart';

import 'package:test/test.dart';

Future main() async {
  final harness = SarSysTrackingHarness()
    ..withGrpc()
    ..withLogger(debug: false)
    ..withEventStoreMock()
    ..install();

  test('Server should start', () async {
    expect(harness.server.isOpen, isTrue);
  });

  test('Server should be ready', () async {
    expect(harness.server.isReady, isTrue);
  });

  test('GET /api/healthz/alive returns 200 OK', () async {
    final request = await harness.httpClient.get('localhost', 8082, '/api/healthz/alive');
    final response = await request.close();
    expect(response.statusCode, 200);
  });

  test('GET /api/healthz/ready returns 200 OK', () async {
    final request = await harness.httpClient.get('localhost', 8082, '/api/healthz/ready');
    final response = await request.close();
    expect(response.statusCode, 200);
  });

  test('GRPC GetMetaRequest returns GetMetaResponse with default values', () async {
    final response = await harness.grpcClient.getMeta(
      GetMetaRequest()..expand.add(ExpandFields.EXPAND_FIELDS_REPO),
    );

    expect(response.total, 0);
    expect(response.managerOf, isEmpty);
    expect(response.fractionManaged, 0);
    expect(response.positions.total, 0);
    expect(response.positions.positionsPerMinute, 0);
    expect(response.positions.averageProcessingTimeMillis, 0);
    expect(response.positions.lastEvent.uuid, isEmpty);
    expect(response.positions.lastEvent.number, -1);
    expect(response.positions.lastEvent.remote, isFalse);
    expect(response.positions.lastEvent.position, -1);
    expect(response.repo.type, 'Tracking');
    expect(response.repo.lastEvent, isNotNull);
    expect(response.repo.lastEvent.uuid, isEmpty);
    expect(response.repo.lastEvent.number, -1);
    expect(response.repo.lastEvent.remote, isFalse);
    expect(response.repo.lastEvent.position, -1);
    expect(response.repo.queue.pressure.total, 0);
    expect(response.repo.queue.pressure.commands, 0);
    expect(response.repo.queue.pressure.maximum, 100);
    expect(response.repo.queue.pressure.exceeded, false);
    expect(response.repo.queue.status.idle, true);
    expect(response.repo.queue.status.ready, true);
    expect(response.repo.queue.status.disposed, false);
  });

  test('GRPC AddTrackingsRequest returns AddTrackingResponse with code 404', () async {
    final uuid = Uuid().v4();
    final response = await harness.grpcClient.addTrackings(
      AddTrackingsRequest()..uuids.add(uuid),
    );

    expect(response.statusCode, 404);
    expect(response.meta, isNotNull);
    expect(response.failed, contains(uuid));
    expect(response.reasonPhrase, 'Not found');
  });

  test('GRPC RemoveTrackingsRequest returns RemoveTrackingResponse with code 404', () async {
    final uuid = Uuid().v4();
    final response = await harness.grpcClient.removeTrackings(
      RemoveTrackingsRequest()..uuids.add(uuid),
    );

    expect(response.statusCode, 404);
    expect(response.meta, isNotNull);
    expect(response.failed, contains(uuid));
    expect(response.reasonPhrase, 'Not found');
  });
}
