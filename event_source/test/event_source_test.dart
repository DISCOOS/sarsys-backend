import 'package:test/test.dart';
import 'package:uuid/uuid.dart';
import 'package:async/async.dart';
import 'package:pedantic/pedantic.dart';
import 'package:collection_x/collection_x.dart';
import 'package:event_source/event_source.dart';
import 'package:event_source/src/error.dart';
import 'package:event_source_test/src/mock.dart';
import 'package:event_source_test/event_source_test.dart';

import 'event_domain_test.dart';

Future main() async {
  final harness = EventSourceHarness()
    ..withTenant()
    ..withPrefix()
    ..withLogger(debug: false)
    ..withRepository<Foo>(
      (_, store, instance) => FooRepository(store, instance),
      instances: 2,
    )
    ..withProjections(projections: ['\$by_category', '\$by_event_type'])
    ..withMaster(4000)
    ..addServer(port: 4000)
    ..addServer(port: 4001)
    ..addServer(port: 4002)
    ..install();

  test('EventStore throws WrongExpectedEventVersion on second concurrent write',
      () async {
    // Arrange
    final repo = harness.get<FooRepository>();
    await repo.readyAsync();
    final foo1 = repo.get(Uuid().v4());
    final foo2 = repo.get(Uuid().v4());

    // Act - preform two concurrent pushes without awaiting the result
    final events1 = repo.store.push(foo1.uuid, foo2.getLocalEvents());
    final events2 = repo.store.push(foo2.uuid, foo2.getLocalEvents());

    // Assert - store write fails
    expect(await events1.asStream().first, equals([isA<FooCreated>()]));
    await expectLater(events2, throwsA(isA<WrongExpectedEventVersion>()));
  });

  test('EventStore redirects to master when ES-RequireMaster=true', () async {
    // Arrange for calls to slave
    final repo = harness.get<FooRepository>(port: 4001);
    await repo.readyAsync();
    final foo = repo.get(Uuid().v4());

    // Act
    final events = await repo.store.push(foo.uuid, foo.getLocalEvents());

    // Assert - store write fails
    expect(events, equals([isA<FooCreated>()]));
  });

  test('EventStore should catchup after replay', () async {
    // Arrange
    final repo1 = await _createStreamsAndReplay(harness, 4000, 0, 3);
    final repo2 = await _createStreamsAndReplay(harness, 4001, 3, 3);
    final repo3 = await _createStreamsAndReplay(harness, 4002, 6, 3);

    // Act - replay
    await repo1.replay();
    await repo2.replay();
    await repo3.replay();

    // Assert instances
    expect(repo1.count(), equals(9), reason: '${repo1.aggregates}');
    expect(repo2.count(), equals(9), reason: '${repo2.aggregates}');
    expect(repo3.count(), equals(9), reason: '${repo3.aggregates}');
  });

  test('EventStore should catchup after push', () async {
    // Arrange
    final repo1 = await _createStreamsAndReplay(harness, 4000, 0, 3);
    final repo2 = await _createStreamsAndReplay(harness, 4001, 3, 3);
    final repo3 = await _createStreamsAndReplay(harness, 4002, 6, 3);

    // Act - create new instance stream
    final uuid = Uuid().v4();
    final foo = repo1.get(uuid, data: {'property1': 'value1'});

    // Wait for catchup from eventstore
    final pending = StreamGroup.merge([
      repo2.store
          .asStream()
          .expand((events) => events)
          .where((event) => event.data.elementAt('uuid') == uuid),
      repo3.store
          .asStream()
          .expand((events) => events)
          .where((event) => event.data.elementAt('uuid') == uuid),
    ]);
    await repo1.push(foo);
    await pending.take(2).toList();

    // Assert instances
    expect(repo1.count(), equals(10), reason: '${repo1.aggregates}');
    expect(repo2.count(), equals(10), reason: '${repo2.aggregates}');
    expect(repo3.count(), equals(10), reason: '${repo3.aggregates}');
  });

  test('EventStore should enforce strict order of event numbers', () async {
    // Arrange
    final uuid = Uuid().v4();
    final repo1 = harness.get<FooRepository>(instance: 1);
    final repo2 = harness.get<FooRepository>(instance: 2);
    await repo1.readyAsync();
    await repo2.readyAsync();

    // Act - execute
    unawaited(_createMultipleEvents(repo1, uuid));

    // Wait for repo2 to catch up
    await takeRemote(repo2.store.asStream(), 10, distinct: true);

    // Assert - repo 1
    final events1 = _assertEventNumberStrictOrder(repo1, uuid);
    _assertUniqueEvents(repo1, events1);
    expect(repo1.number.value, 9);
    expect(repo1.count(), equals(1), reason: 'Should contain one aggregate');
    expect(repo1.get(uuid).applied.length, equals(10),
        reason: 'Should contain 10 events');

    // Assert - repo 2
    final events2 = _assertEventNumberStrictOrder(repo2, uuid);
    _assertUniqueEvents(repo2, events2);
    expect(repo2.number.value, 9);
    expect(repo2.count(), equals(1), reason: 'Should contain one aggregate');
    expect(repo2.get(uuid).applied.length, equals(10),
        reason: 'Should contain 10 events');
  });
}

Future<FooRepository> _createStreamsAndReplay(
    EventSourceHarness harness, int port, int existing, int count) async {
  final repo = harness.get<FooRepository>(port: port);
  await repo.readyAsync();
  final stream = harness.server(port: port).getStream(repo.store.aggregate);
  for (var i = 0; i < count; i++) {
    _createStream(i, stream);
  }
  await repo.replay();
  expect(repo.count(), equals(existing + count));
  return repo;
}

Map<String, Map<String, dynamic>> _createStream(
  int index,
  TestStream stream,
) {
  return stream.append('${stream.instanceStream}-${stream.instances.length}', [
    TestStream.asSourceEvent<FooCreated>(
      '$index:${Uuid().v4()}',
      {'property1': 'value1'},
      {
        'property1': 'value1',
        'property2': 'value2',
        'property3': 'value3',
      },
    )
  ]);
}

Future<List<DomainEvent>> _createMultipleEvents(
    FooRepository repo, String uuid) async {
  final operations = <DomainEvent>[];
  final foo = repo.get(uuid, data: {'index': 0});
  // Create
  final events = await repo.push(foo);
  operations.addAll(
    events.toList(),
  );
  // Patch
  for (var i = 1; i < 10; i++) {
    final events = await repo.push(
      foo..patch({'index': i}, emits: FooUpdated),
    );
    operations.addAll(
      events.toList(),
    );
  }
  expect(
    repo.number.value,
    9,
    reason: 'Event number should match',
  );
  return operations;
}

Iterable<SourceEvent> _assertEventNumberStrictOrder(
    Repository repo, String uuid) {
  final events = repo.store.aggregateMap[uuid].toList();
  for (var i = 0; i < events.length; i++) {
    expect(
      events[i].number.value,
      equals(i),
      reason: 'Event number should be $i',
    );
  }
  expect(
    repo.number.value,
    events.length - 1,
    reason: 'Event number should match',
  );
  return events;
}

void _assertUniqueEvents(Repository repo, Iterable<Event> events) {
  final actual = repo.store.aggregateMap.values.fold(
    <String>[],
    (uuids, items) => uuids..addAll(items.map((e) => e.uuid)),
  );
  final expected = events.map((e) => e.uuid).toList();
  expect(expected, equals(actual));
}
