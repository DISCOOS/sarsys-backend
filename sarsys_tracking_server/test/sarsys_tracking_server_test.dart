import 'package:sarsys_core/sarsys_core.dart';
import 'package:sarsys_tracking_server/src/generated/tracking_service.pb.dart';
import 'package:sarsys_tracking_server_test/sarsys_tracking_server_test.dart';

import 'package:test/test.dart';

Future main() async {
  final harness = SarSysTrackingHarness()
    ..withGrpcClient()
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

  test('GRPC GetMeta returns default values', () async {
    // Act
    final response = await harness.grpcClient.getMeta(
      GetTrackingMetaRequest()
        ..expand.addAll([
          TrackingExpandFields.TRACKING_EXPAND_FIELDS_REPO,
          TrackingExpandFields.TRACKING_EXPAND_FIELDS_REPO_QUEUE,
          TrackingExpandFields.TRACKING_EXPAND_FIELDS_REPO_METRICS,
        ]),
    );

    // Assert service meta
    expect(response.managerOf, isEmpty);
    expect(response.status, TrackingServerStatus.TRACKING_STATUS_READY);

    // Assert trackings meta
    expect(response.trackings.total.toInt(), 0);
    expect(response.trackings.eventsPerMinute, 0);
    expect(response.trackings.averageProcessingTimeMillis, 0);
    expect(response.trackings.lastEvent.uuid, isEmpty);
    expect(response.trackings.lastEvent.remote, isFalse);
    expect(response.trackings.lastEvent.number.toInt(), -1);
    expect(response.trackings.lastEvent.position.toInt(), -1);
    expect(response.trackings.lastEvent.timestamp.seconds.toInt(), 0);
    expect(response.trackings.fractionManaged, 0);

    // Assert positions meta
    expect(response.positions.total.toInt(), 0);
    expect(response.positions.eventsPerMinute, 0);
    expect(response.positions.averageProcessingTimeMillis, 0);
    expect(response.positions.lastEvent.uuid, isEmpty);
    expect(response.positions.lastEvent.remote, isFalse);
    expect(response.positions.lastEvent.number.toInt(), -1);
    expect(response.positions.lastEvent.position.toInt(), -1);
    expect(response.positions.lastEvent.timestamp.seconds.toInt(), 0);

    // Assert repo meta
    expect(response.repo.type, 'Tracking');
    expect(response.repo.lastEvent, isNotNull);
    expect(response.repo.lastEvent.uuid, isEmpty);
    expect(response.repo.lastEvent.remote, isFalse);
    expect(response.repo.lastEvent.number.toInt(), -1);
    expect(response.repo.lastEvent.position.toInt(), -1);
    expect(response.repo.lastEvent.timestamp.seconds.toInt(), 0);

    // Assert repo queue meta
    expect(response.repo.queue.pressure.total, 0);
    expect(response.repo.queue.pressure.commands, 0);
    expect(response.repo.queue.pressure.maximum, 100);
    expect(response.repo.queue.pressure.exceeded, false);
    expect(response.repo.queue.status.idle, true);
    expect(response.repo.queue.status.ready, true);
    expect(response.repo.queue.status.disposed, false);

    // Assert repo metrics meta
    expect(response.repo.metrics.transactions, 0);
    expect(response.repo.metrics.events.toInt(), 0);
  });

  test('GRPC Start returns status code 200', () async {
    final response = await harness.grpcClient.start(
      StartTrackingRequest(),
    );

    expect(response.statusCode, 200);
    expect(response.reasonPhrase, 'OK');
    expect(response.meta.status, TrackingServerStatus.TRACKING_STATUS_STARTED);
  });

  test('GRPC Stop returns status code 200', () async {
    // Arrange
    final started = await harness.grpcClient.start(
      StartTrackingRequest(),
    );
    expect(started.statusCode, 200);

    // Act
    final stopped = await harness.grpcClient.stop(
      StopTrackingRequest(),
    );

    expect(stopped.statusCode, 200);
    expect(stopped.reasonPhrase, 'OK');
    expect(stopped.meta.status, TrackingServerStatus.TRACKING_STATUS_STOPPED);
  });

  test('GRPC AddTrackings returns status code 404 without uuids', () async {
    final uuid = Uuid().v4();
    final response = await harness.grpcClient.addTrackings(
      AddTrackingsRequest()..uuids.add(uuid),
    );

    expect(response.statusCode, 404);
    expect(response.meta, isNotNull);
    expect(response.failed, contains(uuid));
    expect(response.reasonPhrase, 'Not found: $uuid');
  });

  test('GRPC RemoveTrackings returns status code 404 without uuids', () async {
    final uuid = Uuid().v4();
    final response = await harness.grpcClient.removeTrackings(
      RemoveTrackingsRequest()..uuids.add(uuid),
    );

    expect(response.statusCode, 404);
    expect(response.meta, isNotNull);
    expect(response.failed, contains(uuid));
    expect(response.reasonPhrase, 'Not found: $uuid');
  });
}
