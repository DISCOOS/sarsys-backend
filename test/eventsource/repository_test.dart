import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

import 'foo.dart';
import 'harness.dart';

Future main() async {
  final harness = Harness()
    ..withTenant()
    ..withPrefix()
    ..withProjection()
    ..withRepository<Foo>((store) => FooRepository(store))
    ..install();

  test("Repository should support build operation", () async {
    final repository = harness.get<FooRepository>();
    final ready = await repository.readyAsync();
    // Assert repository state
    expect(ready, equals(true), reason: "Repository should be ready");
    expect(repository.count, equals(0), reason: "Repository should be empty");
  });

  test("Repository should support create -> patch -> push operations", () async {
    final repository = harness.get<FooRepository>();
    await repository.readyAsync();

    // Assert create operation
    final uuid = Uuid().v4();
    final foo = repository.get(uuid);
    expect(foo.uuid, equals(uuid), reason: "Foo uuid should be $uuid");
    expect(foo.isNew, equals(true), reason: "Foo should be flagged as 'New'");
    expect(foo.isChanged, equals(true), reason: "Foo should be flagged as 'Changed'");
    expect(foo.isDeleted, equals(false), reason: "Foo should not be flagged as 'Deleted'");
    final stream = harness.server.getStream(repository.store.aggregate);
    expect(stream.toEvents().isEmpty, equals(true), reason: "Events should not be commited yet");

    // Assert patch operation
    foo.patch({"property": "patched"}, emits: FooUpdated);
    expect(foo.data, containsPair("property", "patched"), reason: "Foo should contain value 'patched'");
    expect(foo.isNew, equals(true), reason: "Foo should be flagged as 'New'");
    expect(foo.isChanged, equals(true), reason: "Foo should be flagged as 'Changed'");
    expect(foo.isDeleted, equals(false), reason: "Foo should not be flagged as 'Deleted'");
    expect(stream.toEvents().isEmpty, equals(true), reason: "Events should not be commited yet");

    // Assert push operation
    final events = await repository.push(foo);
    expect(events.length, equals(2), reason: "Push should return 2 events");
    expect(foo.isNew, equals(false), reason: "Foo should not be flagged as 'New' after push");
    expect(foo.isChanged, equals(false), reason: "Foo should not be flagged as 'Changed' after push");
    expect(foo.isDeleted, equals(false), reason: "Foo should not be flagged as 'Deleted' after push");
    expect(stream.toEvents().length, equals(2), reason: "Stream should contain 2 events after push");
    expect(
      stream.toEvents().keys,
      equals(
        events.map((event) => event.uuid),
      ),
      reason: "Stream should only contain events returned by push",
    );
  });
}
