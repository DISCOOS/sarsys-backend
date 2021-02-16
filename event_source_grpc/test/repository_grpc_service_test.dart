import 'package:event_source_grpc/event_source_grpc.dart';
import 'package:event_source_grpc_test/event_source_grpc_test.dart';
import 'package:event_source_test/event_source_test.dart';

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
    ..withRepository<Foo>(
      (manager, store, instance) => FooRepository(store, instance),
      instances: instances,
    )
    ..withProjections(projections: [
      '\$by_category',
      '\$by_event_type',
    ])
    ..addServer(port: 4000)
    ..withRepositoryService()
    ..install();

  test('GRPC GetMeta with empty repo returns 404', () async {
    // Arrange
    final client = harness.client<RepositoryServiceClient>();

    final response = await client.getMeta(
      GetRepoMetaRequest()..type = 'Bar',
    );
    expect(response.type, 'Bar');
    expect(response.statusCode, 404);
    expect(response.reasonPhrase, 'Repository for aggregate Bar not found');
  });

  test('GRPC GetMeta returns 200 when aggregate exists', () async {
    // Arrange
    final repo = harness.get<FooRepository>();
    await repo.readyAsync();
    final uuid = Uuid().v4();
    final foo = repo.get(uuid, data: {'property11': 'value11'});
    await repo.push(foo);
    final client = harness.client<RepositoryServiceClient>();

    // Act
    final response = await client.getMeta(
      GetRepoMetaRequest()
        ..type = 'Foo'
        ..expand.add(
          RepoExpandFields.REPO_EXPAND_FIELDS_ALL,
        ),
    );

    // Assert
    expect(response.type, 'Foo');
    expect(response.statusCode, 200);
    expect(response.reasonPhrase, 'OK');
    expect(response.meta, isNotNull);
  });

  test('GRPC ReplayEvents returns 200', () async {
    // Arrange
    final repo = harness.get<FooRepository>();
    await repo.readyAsync();
    final uuid = Uuid().v4();
    final foo = repo.get(uuid, data: {'property11': 'value11'});
    await repo.push(foo);
    final client = harness.client<RepositoryServiceClient>();

    // Act
    final response = await client.replayEvents(
      ReplayRepoEventsRequest()
        ..type = 'Foo'
        ..uuids.add(uuid)
        ..expand.add(
          RepoExpandFields.REPO_EXPAND_FIELDS_ALL,
        ),
    );

    // Assert
    expect(response.type, 'Foo');
    expect(response.statusCode, 200);
    expect(response.reasonPhrase, 'OK');
    expect(response.meta, isNotNull);
  });

  test('GRPC CatchupEvents returns 200', () async {
    // Arrange
    final repo = harness.get<FooRepository>();
    await repo.readyAsync();
    final uuid = Uuid().v4();
    final foo = repo.get(uuid, data: {'property11': 'value11'});
    await repo.push(foo);
    final client = harness.client<RepositoryServiceClient>();

    // Act
    final response = await client.catchupEvents(
      CatchupRepoEventsRequest()
        ..type = 'Foo'
        ..uuids.add(uuid)
        ..expand.add(
          RepoExpandFields.REPO_EXPAND_FIELDS_ALL,
        ),
    );

    // Assert
    expect(response.type, 'Foo');
    expect(response.statusCode, 200);
    expect(response.reasonPhrase, 'OK');
    expect(response.meta, isNotNull);
  });

  test('GRPC Repair returns 200', () async {
    // Arrange
    final repo = harness.get<FooRepository>();
    await repo.readyAsync();
    final uuid = Uuid().v4();
    final foo = repo.get(uuid, data: {'property11': 'value11'});
    await repo.push(foo);
    final client = harness.client<RepositoryServiceClient>();

    // Act
    final response = await client.repair(
      RepairRepoRequest()
        ..type = 'Foo'
        ..master = true
        ..expand.add(
          RepoExpandFields.REPO_EXPAND_FIELDS_ALL,
        ),
    );

    // Assert
    expect(response.type, 'Foo');
    expect(response.statusCode, 200);
    expect(response.reasonPhrase, 'OK');
    expect(response.meta, isNotNull);
  });

  test('GRPC Rebuild returns 200', () async {
    // Arrange
    final repo = harness.get<FooRepository>();
    await repo.readyAsync();
    final uuid = Uuid().v4();
    final foo = repo.get(uuid, data: {'property11': 'value11'});
    await repo.push(foo);
    final client = harness.client<RepositoryServiceClient>();

    // Act
    final response = await client.rebuild(
      RebuildRepoRequest()
        ..type = 'Foo'
        ..master = true
        ..expand.add(
          RepoExpandFields.REPO_EXPAND_FIELDS_ALL,
        ),
    );

    // Assert
    expect(response.type, 'Foo');
    expect(response.statusCode, 200);
    expect(response.reasonPhrase, 'OK');
    expect(response.meta, isNotNull);
  });
}
