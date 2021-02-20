import 'dart:async';

import 'package:event_source_grpc/event_source_grpc.dart';
import 'package:event_source_grpc/src/generated/file.pb.dart';
import 'package:event_source_grpc_test/event_source_grpc_test.dart';
import 'package:event_source_test/event_source_test.dart';
import 'package:fixnum/fixnum.dart';

import 'package:test/test.dart';
import 'package:uuid/uuid.dart';
import 'package:logging/logging.dart';

void main() {
  const instances = 1;
  final harness = EventSourceGrpcHarness()
    ..withTenant()
    ..withPrefix()
    ..withLogger(
      debug: false,
      level: Level.INFO,
    )
    ..withSnapshotService()
    ..withRepository<Foo>(
      (manager, store, instance) => FooRepository(store, instance),
      instances: instances,
    )
    ..withProjections(projections: [
      '\$by_category',
      '\$by_event_type',
    ])
    ..addServer(port: 4000)
    ..install();

  test('GRPC GetMeta with no snapshot returns 404', () async {
    // Arrange
    final client = harness.client<SnapshotGrpcServiceClient>();

    final response = await client.getMeta(
      GetSnapshotMetaRequest()..type = 'Bar',
    );
    expect(response.type, 'Bar');
    expect(response.statusCode, 404);
    expect(response.reasonPhrase, 'Repository for aggregate Bar not found');
  });

  test('GRPC GetMeta returns 200 when snapshot exists', () async {
    // Arrange
    final repo = harness.get<FooRepository>();
    await repo.readyAsync();
    final uuid = Uuid().v4();
    final foo = repo.get(uuid, data: {'property11': 'value11'});
    await repo.push(foo);
    repo.save(force: true);
    await repo.store.snapshots.onIdle;
    final client = harness.client<SnapshotGrpcServiceClient>();

    // Act
    final response = await client.getMeta(
      GetSnapshotMetaRequest()
        ..type = 'Foo'
        ..expand.add(
          SnapshotExpandFields.SNAPSHOT_EXPAND_FIELDS_ALL,
        ),
    );

    // Assert
    expect(response.type, 'Foo');
    expect(response.statusCode, 200);
    expect(response.reasonPhrase, 'OK');
    expect(response.meta, isNotNull);
  });

  test('GRPC Configure returns 204 when no snapshot', () async {
    // Arrange
    final client = harness.client<SnapshotGrpcServiceClient>();

    // Act
    final response = await client.configure(
      ConfigureSnapshotRequest()
        ..type = 'Foo'
        ..keep = 2
        ..threshold = 20
        ..automatic = false
        ..expand.add(
          SnapshotExpandFields.SNAPSHOT_EXPAND_FIELDS_ALL,
        ),
    );

    // Assert
    expect(response.type, 'Foo');
    expect(response.meta, isNotNull);
    expect(response.statusCode, 204);
    expect(response.reasonPhrase, 'No snapshot');
  });

  test('GRPC Save returns 200', () async {
    // Arrange
    final repo = harness.get<FooRepository>();
    await repo.readyAsync();
    final uuid = Uuid().v4();
    final foo = repo.get(uuid, data: {'property11': 'value11'});
    await repo.push(foo);
    repo.save(force: true);
    await repo.store.snapshots.onIdle;
    final client = harness.client<SnapshotGrpcServiceClient>();

    // Act
    final response = await client.save(
      SaveSnapshotRequest()
        ..type = 'Foo'
        ..force = true
        ..expand.add(
          SnapshotExpandFields.SNAPSHOT_EXPAND_FIELDS_ALL,
        ),
    );

    // Assert
    expect(response.type, 'Foo');
    expect(response.statusCode, 200);
    expect(response.reasonPhrase, 'Snapshot saved (force was true)');
    expect(response.meta, isNotNull);
  });

  test('GRPC Download returns 200', () async {
    // Act
    final content = await _download(harness, 100);

    // Assert
    expect(content.isNotEmpty, isTrue);
  });

  test('GRPC Upload returns 200', () async {
    // Arrange
    final chunks = await _download(harness, 100);
    final client = harness.client<SnapshotGrpcServiceClient>();

    // Act
    final response = await client.upload(
      _upload('Foo', 100, chunks),
    );

    // Assert
    expect(response.type, 'Foo');
    expect(response.statusCode, 200);
    expect(response.reasonPhrase, 'Uploading Foo snapshots...DONE');
  });
}

Stream<SnapshotChunk> _upload(String type, int chunkSize, List<List<int>> chunks) async* {
  final fileSize = chunks.fold(0, (length, content) => length + content.length);
  for (var content in chunks) {
    yield SnapshotChunk()
      ..type = type
      ..chunk = (FileChunk()
        ..content = content
        ..fileSize = Int64(fileSize)
        ..chunkSize = Int64(chunkSize));
  }
}

Future<List<List<int>>> _download(EventSourceGrpcHarness harness, int chunkSize) async {
  // Arrange
  final repo = harness.get<FooRepository>();
  await repo.readyAsync();
  final uuid = Uuid().v4();
  final foo = repo.get(uuid, data: {'property11': 'value11'});
  await repo.push(foo);
  repo.save(force: true);
  await repo.store.snapshots.onIdle;
  final client = harness.client<SnapshotGrpcServiceClient>();

  final response = client.download(
    DownloadSnapshotRequest()
      ..type = 'Foo'
      ..chunkSize = Int64(chunkSize),
  );

  var content = <List<int>>[];
  await for (var chunk in response) {
    content.add(chunk.content);
  }
  return content;
}
