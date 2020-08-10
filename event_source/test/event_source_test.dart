import 'package:event_source/src/error.dart';
import 'package:event_source/src/mock.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';
import 'package:async/async.dart';

import 'foo.dart';
import 'harness.dart';

Future main() async {
  final harness = EventSourceHarness()
    ..withTenant()
    ..withPrefix()
    ..withLogger()
    ..withRepository<Foo>((store) => FooRepository(store), instances: 2)
    ..withProjections(projections: ['\$by_category', '\$by_event_type'])
    ..addServer(port: 4000)
    ..addServer(port: 4001)
    ..addServer(port: 4002)
    ..install();

  test('EventStore throws WrongExpectedEventVersion on second concurrent write', () async {
    // Arrange
    final repo = harness.get<FooRepository>();
    await repo.readyAsync();
    final foo1 = repo.get(Uuid().v4());
    final foo2 = repo.get(Uuid().v4());

    // Act - preform two concurrent pushes without awaiting the result
    final events1 = repo.store.push(foo1);
    final events2 = repo.store.push(foo2);

    // Assert - store write fails
    expect(await events1.asStream().first, equals([isA<FooCreated>()]));
    await expectLater(events2, throwsA(isA<WrongExpectedEventVersion>()));
  });

  test('EventStore should catchup after replay', () async {
    // Arrange
    final repo1 = await _createStreamsAndReplay(harness, 4000, 3);
    final repo2 = await _createStreamsAndReplay(harness, 4001, 3);
    final repo3 = await _createStreamsAndReplay(harness, 4002, 3);

    // Act - create new instance stream
    final uuid = Uuid().v4();
    final foo = repo1.get(uuid, data: {'property1': 'value1'});
    final pending = StreamGroup.merge([
      repo2.store.asStream(),
      repo3.store.asStream(),
    ]);
    await repo1.push(foo);
    await pending.take(2).toList();

    // Assert instances
    expect(repo1.count(), equals(4));
    expect(repo2.count(), equals(4), reason: '${repo2.aggregates}');
    expect(repo3.count(), equals(4));
  });
}

Future<FooRepository> _createStreamsAndReplay(EventSourceHarness harness, int port, int count) async {
  final repo = harness.get<FooRepository>(port: port);
  await repo.readyAsync();
  final stream = harness.server(port: port).getStream(repo.store.aggregate);
  for (var i = 0; i < count; i++) {
    _createStream(i, stream);
  }
  await repo.replay();
  expect(repo.count(), equals(3));
  return repo;
}

Map<String, Map<String, dynamic>> _createStream(
  int index,
  TestStream stream,
) {
  return stream.append('${stream.instanceStream}-${stream.instances.length}', [
    TestStream.asSourceEvent<FooCreated>(
      '$index',
      {'property1': 'value1'},
      {
        'property1': 'value1',
        'property2': 'value2',
        'property3': 'value3',
      },
    )
  ]);
}
