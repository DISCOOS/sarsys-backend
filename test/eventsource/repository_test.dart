import 'package:json_patch/json_patch.dart';
import 'package:sarsys_app_server/eventsource/eventsource.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

import 'eventstore_mock_server.dart';
import 'foo.dart';
import 'harness.dart';

Future main() async {
  final harness = EventSourceHarness()
    ..withTenant()
    ..withPrefix()
    ..withProjection()
    ..withRepository<Foo>((store) => FooRepository(store))
    ..add(port: 4000)
    ..add(port: 4001)
    ..install();

  test("Repository should support build operation", () async {
    final repository = harness.get<FooRepository>();
    final ready = await repository.readyAsync();
    // Assert repository state
    expect(ready, equals(true), reason: "Repository should be ready");
    expect(repository.count, equals(0), reason: "Repository should be empty");
  });

  test("Repository should support create -> patch -> push operations", () async {
    // Arrange
    final repository = harness.get<FooRepository>();
    final stream = harness.server().getStream(repository.store.aggregate);
    await repository.readyAsync();

    // Assert create operation
    final uuid = Uuid().v4();
    final foo = repository.get(uuid);
    expect(foo.uuid, equals(uuid), reason: "Foo uuid should be $uuid");
    expect(foo.isNew, equals(true), reason: "Foo should be flagged as 'New'");
    expect(foo.isChanged, equals(true), reason: "Foo should be flagged as 'Changed'");
    expect(foo.isDeleted, equals(false), reason: "Foo should not be flagged as 'Deleted'");
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

  test("Repository should only apply operations [add, replace, move] when patching local changes", () async {
    // Arrange
    final repository = harness.get<FooRepository>();
    await repository.readyAsync();

    // Act
    final uuid = Uuid().v4();
    final foo = repository.get(uuid, data: {
      "property1": "value1",
      "property2": "value2",
      "list1": ["item1", "item2"],
      "object1": {
        "member1": "value1",
        "member2": "value2",
      }
    });
    foo.patch({
      "property3": "value3",
      "property2": "value4",
      "list1": ["item3"],
      "object1": {
        "member2": "value4",
        "member3": "value3",
      }
    }, emits: FooUpdated);

    // Assert
    expect(foo.data, containsPair("property1", "value1")); // keep
    expect(foo.data, containsPair("property3", "value3")); // add value
    expect(foo.data, containsPair("property2", "value4")); // replace value
    expect(foo.data, containsPair("list1", ["item3"])); // replace list of values
    expect(
        foo.data,
        containsPair("object1", {
          "member1": "value1",
          "member2": "value4",
          "member3": "value3",
        }));
  });

  test("Repository should only apply operations [add, replace, move] when patching remote changes", () async {
    // Arrange
    final repo1 = harness.get<FooRepository>(port: 4000);
    final repo2 = harness.get<FooRepository>(port: 4001);
    await repo1.readyAsync();
    await repo2.readyAsync();

    // Act
    final uuid = Uuid().v4();
    final foo1 = repo1.get(uuid, data: {
      "property1": "value1",
      "property2": "value2",
      "list1": ["item1", "item2"],
      "object1": {
        "member1": "value1",
        "member2": "value2",
      }
    });
    await repo1.push(foo1);
    await repo2.store.asStream().first;
    final foo2 = repo2.get(uuid);
    foo2.patch({
      "property3": "value3",
      "property2": "value4",
      "list1": ["item3"],
      "object1": {
        "member2": "value4",
        "member3": "value3",
      }
    }, emits: FooUpdated);
    await repo2.push(foo2);
    await repo1.store.asStream().first;

    // Assert
    expect(foo1.data, containsPair("property1", "value1")); // keep
    expect(foo1.data, containsPair("property3", "value3")); // add value
    expect(foo1.data, containsPair("property2", "value4")); // replace value
    expect(foo1.data, containsPair("list1", ["item3"])); // replace list of values
    expect(
        foo1.data,
        containsPair("object1", {
          "member1": "value1",
          "member2": "value4",
          "member3": "value3",
        })); // keep, add and replace member values
  });

  test("Repository should catch-up to head of events in remote stream", () async {
    // Arrange
    final repo1 = harness.get<FooRepository>(port: 4000);
    final repo2 = harness.get<FooRepository>(port: 4001);
    await repo1.readyAsync();
    await repo2.readyAsync();

    // Act
    final uuid = Uuid().v4();
    final foo1 = repo1.get(uuid, data: {"property1": "value1"});
    final events = await repo1.push(foo1);
    final remote = await repo2.store.asStream().first;
    final foo2 = repo2.get(uuid);

    // Assert catch-up event from repo1
    expect(repo2.count, equals(1));
    expect([remote], containsAll(events));
    expect(foo1.data, containsPair("property1", "value1"));
    expect(foo2.data, containsPair("property1", "value1"));
  });

  test("Repository should resolve conflicts on push", () async {
    // Arrange
    final repo = harness.get<FooRepository>();
    final stream = harness.server().getStream(repo.store.aggregate);
    await repo.readyAsync();

    // Act - Simulate conflict by manually updating remote stream
    final uuid = Uuid().v4();
    final foo = repo.get(uuid, data: {"property1": "value1"});
    await repo.push(foo);
    stream.append('${stream.instanceStream}-0', [
      TestStream.asSourceEvent<FooUpdated>(
        uuid,
        {"property1": "value1"},
        {"property2": "value2"},
      )
    ]);
    foo.patch({"property3": "value3"}, emits: FooUpdated);

    // Assert conflict occurred - will rollback changes
    expect(() => repo.push(foo), throwsA(const TypeMatcher<WrongExpectedEventVersion>()));

    // Act - retry
    await repo.store.asStream().take(2).first;
    foo.patch({"property3": "value3"}, emits: FooUpdated);
    await repo.push(foo);

    // Assert conflict resolved
    expect(repo.count, equals(1));
    expect(foo.data, containsPair("property1", "value1"));
    expect(foo.data, containsPair("property2", "value2"));
    expect(foo.data, containsPair("property3", "value3"));
  });
}
