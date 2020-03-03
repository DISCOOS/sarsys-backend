import 'package:event_source/src/core.dart';
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

  test('EventStore throw a WriteFailed exception on second concurrent write', () async {
    // Arrange
    final repository = harness.get<FooRepository>();
    await repository.readyAsync();
    final foo1 = repository.get(Uuid().v4());
    final foo2 = repository.get(Uuid().v4());

    // Act - preform two concurrent pushes without awaiting the result
    final events1 = repository.store.push(foo1);
    final events2 = repository.store.push(foo2);

    // Assert - store write fails
    expect(await events1.asStream().first, equals([isA<FooCreated>()]));
    await expectLater(events2, throwsA(const TypeMatcher<WriteFailed>()));
  });
}
