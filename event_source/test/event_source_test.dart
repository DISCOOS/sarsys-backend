import 'package:event_source/src/error.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

import 'foo.dart';
import 'harness.dart';

Future main() async {
  final harness = EventSourceHarness()
    ..withTenant()
    ..withPrefix()
    ..withLogger()
    ..withRepository<Foo>((store) => FooRepository(store), instances: 2)
    ..withProjections(projections: ['\$by_category', '\$by_event_type'])
    ..add(port: 4000)
    ..add(port: 4001)
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
    await expectLater(events2, throwsA(const TypeMatcher<WrongExpectedEventVersion>()));
  });
}
