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
    ..withAggregateService()
    ..install();

  test('GRPC GetMeta with empty repo returns 404', () async {
    // Arrange
    final uuid = Uuid().v4();
    final client = harness.client<AggregateGrpcServiceClient>();

    final response = await client.getMeta(
      GetAggregateMetaRequest()
        ..type = 'Foo'
        ..uuid = uuid,
    );
    expect(response.type, 'Foo');
    expect(response.uuid, uuid);
    expect(response.statusCode, 404);
    expect(response.reasonPhrase, 'Aggregate Foo $uuid not found');
  });

  test('GRPC GetMeta returns 200 when aggregate exists', () async {
    // Arrange
    final repo = harness.get<FooRepository>();
    await repo.readyAsync();
    final uuid = Uuid().v4();
    final foo = repo.get(uuid, data: {'property11': 'value11'});
    final data1 = foo.data;
    await repo.push(foo);
    final client = harness.client<AggregateGrpcServiceClient>();

    // Act
    final response = await client.getMeta(
      GetAggregateMetaRequest()
        ..type = 'Foo'
        ..uuid = uuid
        ..expand.add(
          AggregateExpandFields.AGGREGATE_EXPAND_FIELDS_ALL,
        ),
    );

    // Assert
    expect(response.type, 'Foo');
    expect(response.uuid, uuid);
    expect(response.statusCode, 200);
    expect(response.reasonPhrase, 'OK');
    expect(
      fromJsonValue(
        toJsonValueFromAny(
          response.meta.data,
        ),
      ),
      equals(data1),
    );
  });

  test('GRPC SearchMeta returns 200 when aggregate exists', () async {
    // Arrange
    final repo = harness.get<FooRepository>();
    await repo.readyAsync();
    final uuid = Uuid().v4();
    final foo = repo.get(uuid, data: {'property11': 'value11'});
    final data1 = foo.data;
    await repo.push(foo);
    final client = harness.client<AggregateGrpcServiceClient>();

    // Act
    final response = await client.searchMeta(
      SearchAggregateMetaRequest()
        ..type = 'Foo'
        ..query = r"$.data[?(@.property11=='value11')]"
        ..expand.add(
          AggregateExpandFields.AGGREGATE_EXPAND_FIELDS_ALL,
        ),
    );

    // Assert
    expect(response.type, 'Foo');
    expect(response.statusCode, 200);
    expect(response.reasonPhrase, 'OK');
    expect(response.matches, isNotNull);
    expect(response.matches.count, 1);
    expect(
      toJsonFromAny(
        response.matches.items.first.meta.data,
      ),
      equals(data1),
    );
  });

  test('GRPC SearchMeta returns 200 with regex', () async {
    // Arrange
    final repo = harness.get<FooRepository>();
    await repo.readyAsync();
    final uuid = Uuid().v4();
    final foo = repo.get(uuid, data: {'property11': 'value11'});
    final data1 = foo.data;
    await repo.push(foo);
    final client = harness.client<AggregateGrpcServiceClient>();

    // Act
    final response = await client.searchMeta(
      SearchAggregateMetaRequest()
        ..type = 'Foo'
        ..query = r'$.data[?(@.property11=~/VALUE.*/i)]'
        ..expand.add(
          AggregateExpandFields.AGGREGATE_EXPAND_FIELDS_ALL,
        ),
    );

    // Assert
    expect(response.type, 'Foo');
    expect(response.statusCode, 200);
    expect(response.reasonPhrase, 'OK');
    expect(response.matches, isNotNull);
    expect(response.matches.count, 1);
    expect(
      toJsonFromAny(
        response.matches.items.first.meta.data,
      ),
      equals(data1),
    );
  });

  test('GRPC ReplayEvents returns 200', () async {
    // Arrange
    final repo = harness.get<FooRepository>();
    await repo.readyAsync();
    final uuid = Uuid().v4();
    final foo = repo.get(uuid, data: {'property11': 'value11'});
    final data1 = foo.data;
    await repo.push(foo);
    final client = harness.client<AggregateGrpcServiceClient>();

    // Act
    final response = await client.replayEvents(
      ReplayAggregateEventsRequest()
        ..type = 'Foo'
        ..uuid = uuid
        ..expand.add(
          AggregateExpandFields.AGGREGATE_EXPAND_FIELDS_ALL,
        ),
    );

    // Assert
    expect(response.type, 'Foo');
    expect(response.uuid, uuid);
    expect(response.statusCode, 200);
    expect(response.reasonPhrase, 'OK');
    expect(
      fromJsonValue(
        toJsonValueFromAny(
          response.meta.data,
        ),
      ),
      equals(data1),
    );
  });

  test('GRPC CatchupEvents returns 200', () async {
    // Arrange
    final repo = harness.get<FooRepository>();
    await repo.readyAsync();
    final uuid = Uuid().v4();
    final foo = repo.get(uuid, data: {'property11': 'value11'});
    final data1 = foo.data;
    await repo.push(foo);
    final client = harness.client<AggregateGrpcServiceClient>();

    // Act
    final response = await client.catchupEvents(
      CatchupAggregateEventsRequest()
        ..type = 'Foo'
        ..uuid = uuid
        ..expand.add(
          AggregateExpandFields.AGGREGATE_EXPAND_FIELDS_ALL,
        ),
    );

    // Assert
    expect(response.type, 'Foo');
    expect(response.uuid, uuid);
    expect(response.statusCode, 200);
    expect(response.reasonPhrase, 'OK');
    expect(
      fromJsonValue(
        toJsonValueFromAny(
          response.meta.data,
        ),
      ),
      equals(data1),
    );
  });

  test('GRPC ReplaceData returns 200', () async {
    // Arrange
    final repo = harness.get<FooRepository>();
    await repo.readyAsync();
    final uuid = Uuid().v4();
    final foo = repo.get(uuid, data: {'property11': 'value11'});
    await repo.push(foo);
    final client = harness.client<AggregateGrpcServiceClient>();

    // Act
    final data2 = {'uuid': uuid, 'property11': 'value12'};
    final response = await client.replaceData(
      ReplaceAggregateDataRequest()
        ..type = 'Foo'
        ..uuid = uuid
        ..data = Any.pack(
          toJsonValue(data2),
        )
        ..expand.add(
          AggregateExpandFields.AGGREGATE_EXPAND_FIELDS_ALL,
        ),
    );

    // Assert
    expect(response.type, 'Foo');
    expect(response.uuid, uuid);
    expect(response.statusCode, 200);
    expect(response.reasonPhrase, 'OK');
    expect(
      fromJsonValue(
        toJsonValueFromAny(
          response.meta.data,
        ),
      ),
      equals(data2),
    );
    expect(repo.get(uuid).data, equals(data2));
  });
}
