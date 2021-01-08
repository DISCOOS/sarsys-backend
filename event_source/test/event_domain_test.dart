import 'dart:async';
import 'dart:collection';

import 'package:meta/meta.dart';
import 'package:hive/hive.dart';
import 'package:json_patch/json_patch.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';
import 'package:async/async.dart';
import 'package:pedantic/pedantic.dart';

import 'package:event_source/event_source.dart';
import 'package:event_source/src/models/aggregate_root_model.dart';
import 'package:event_source/src/models/event_number_model.dart';
import 'package:event_source/src/models/snapshot_model.dart';

import 'bar.dart';
import 'foo.dart';
import 'harness.dart';

Future main() async {
  const instances = 2;
  final harness = EventSourceHarness()
    ..withTenant()
    ..withPrefix()
    ..withLogger(debug: false)
    ..withSnapshot()
    ..withRepository<Foo>(
      (manager, store, instance) => FooRepository(store, instance),
      instances: instances,
    )
    ..withRepository<Bar>(
      (manager, store, instance) => BarRepository(
        store,
        instance,
        manager.get<FooRepository>(),
      ),
      instances: instances,
    )
    ..withProjections(projections: ['\$by_category', '\$by_event_type'])
    ..addServer(port: 4000)
    ..addServer(port: 4001)
    ..addServer(port: 4002)
    ..install();

  test('Repository should support build operation', () async {
    final repository = harness.get<FooRepository>();
    final ready = await repository.readyAsync();
    // Assert repository state
    expect(ready, equals(true), reason: 'Repository should be ready');
    expect(repository.count(), equals(0), reason: 'Repository should be empty');
  });

  test('Repository should emit events with correct patches', () async {
    // Arrange
    final repo = harness.get<FooRepository>();
    await repo.readyAsync();

    // Act - created
    final uuid = Uuid().v4();
    final data1 = {
      'uuid': uuid,
      'property1': 'value1',
      'property2': 'value2',
      'property3': 'value3',
      'list1': [
        {'name': 'item1'},
        {'name': 'item2'},
      ]
    };
    final foo = repo.get(uuid, data: data1);
    final patches1 = JsonUtils.diff({}, data1);
    expect(foo.data, data1);

    // Act - changed
    final data2 = {
      'uuid': uuid,
      'property1': 'patched',
      'property2': 'value2',
      'list1': [
        {'name': 'item3'},
      ],
    };
    final patches2 = JsonUtils.diff(data1, data2);
    foo.patch(data2, emits: FooUpdated);
    // Patch should not remove 'property3'
    expect(foo.data, Map.from(data2)..addAll({'property3': 'value3'}));

    // Assert state
    final events = foo.getLocalEvents();
    expect(events.length, equals(2), reason: 'Events should contain two events');

    // Assert patches
    expect(events.first.patches, patches1);
    expect(events.last.patches, patches2);
  });

  test('Repository should support create -> patch -> push operations', () async {
    // Arrange
    final repository = harness.get<FooRepository>();
    final stream = harness.server().getStream(repository.store.aggregate);
    await repository.readyAsync();

    // Assert create operation
    final uuid = Uuid().v4();
    final foo = repository.get(uuid);
    expect(foo.uuid, equals(uuid), reason: 'Foo uuid should be $uuid');
    expect(foo.isNew, equals(true), reason: "Foo should be flagged as 'New'");
    expect(foo.isChanged, equals(true), reason: "Foo should be flagged as 'Changed'");
    expect(foo.isDeleted, equals(false), reason: "Foo should not be flagged as 'Deleted'");
    expect(stream.toEvents().isEmpty, equals(true), reason: 'Events should not be committed yet');

    // Assert patch operation
    foo.patch({'property': 'patched'}, emits: FooUpdated);
    expect(foo.data, containsPair('property', 'patched'), reason: "Foo should contain value 'patched'");
    expect(foo.isNew, equals(true), reason: "Foo should be flagged as 'New'");
    expect(foo.isChanged, equals(true), reason: "Foo should be flagged as 'Changed'");
    expect(foo.isDeleted, equals(false), reason: "Foo should not be flagged as 'Deleted'");
    expect(stream.toEvents().isEmpty, equals(true), reason: 'Events should not be committed yet');

    // Assert push operation
    final events = await repository.push(foo);
    expect(events.length, equals(2), reason: 'Push should return 2 events');
    expect(foo.isNew, equals(false), reason: "Foo should not be flagged as 'New' after push");
    expect(foo.isChanged, equals(false), reason: "Foo should not be flagged as 'Changed' after push");
    expect(foo.isDeleted, equals(false), reason: "Foo should not be flagged as 'Deleted' after push");
    expect(stream.toEvents().length, equals(2), reason: 'Stream should contain 2 events after push');
    expect(
      stream.toEvents().keys,
      equals(
        events.map((event) => event.uuid),
      ),
      reason: 'Stream should only contain events returned by push',
    );
  });

  test('Repository subscription should handle JsonPatchError', () async {
    // Arrange
    final repo = harness.get<FooRepository>();
    await repo.readyAsync();
    final uuid = Uuid().v4();
    final foo = repo.get(uuid, data: {'property11': 'value11'});
    final data1 = foo.data;
    await repo.push(foo);

    // Stop catchup subscription
    repo.store.pause();

    // Perform remote modification on data not found locally
    final stream = harness.server().getStream(repo.store.aggregate);
    final data2 = {
      'property12': ['value12', 'value13', 'value14']
    };
    final data3 = {
      'property12': ['value13', 'value14', 'value15']
    };
    final eventId = Uuid().v4();
    stream.append(
      '${stream.instanceStream}-0',
      [
        TestStream.asSourceEvent<FooUpdated>(
          uuid,
          data2,
          data3,
          eventId: eventId,
          number: EventNumber(1),
        ),
      ],
    );

    // Act - resume catchup
    repo.store.resume();

    // Wait for catchup to complete
    await Future.delayed(Duration(milliseconds: 400));

    // Assert - patches in event 2 is skipped
    expect(foo.number.value, equals(1));
    expect(foo.data, equals(data1));
    expect(foo.skipped, contains(eventId));
    expect(repo.store.isTainted(uuid), isTrue);
  });

  test('Repository catchup should throw JsonPatchError', () async {
    // Arrange
    final repo = harness.get<FooRepository>();
    await repo.readyAsync();
    final uuid = Uuid().v4();
    final foo = repo.get(uuid, data: {'property11': 'value11'});
    final data1 = foo.data;
    await repo.push(foo);

    // Stop ALL catchup subscription
    harness.pause();

    // Perform remote modification on data not found locally
    final stream = harness.server().getStream(repo.store.aggregate);
    final data2 = {
      'property12': ['value12', 'value13', 'value14']
    };
    final data3 = {
      'property12': ['value13', 'value14', 'value15']
    };
    final eventId = Uuid().v4();
    stream.append(
      '${stream.instanceStream}-0',
      [
        TestStream.asSourceEvent<FooUpdated>(
          uuid,
          data2,
          data3,
          eventId: eventId,
          number: EventNumber(1),
        ),
      ],
    );

    // Act - resume catchup
    await expectLater(
      repo.catchup(strict: true),
      throwsA(isA<JsonPatchError>()),
      reason: 'should throw a JsonPatchError',
    );

    // Assert - patches in event 2 is skipped
    expect(foo.number.value, equals(0));
    expect(foo.data, equals(data1));
    expect(foo.skipped, isNot(contains(eventId)));
    expect(repo.store.isTainted(uuid), isFalse);
    expect(repo.store.isCordoned(uuid), isFalse);
  });

  test('Repository catchup should handle JsonPatchError', () async {
    // Arrange
    final repo = harness.get<FooRepository>();
    await repo.readyAsync();
    final uuid = Uuid().v4();
    final foo = repo.get(uuid, data: {'property11': 'value11'});
    final data1 = foo.data;
    await repo.push(foo);

    // Stop ALL catchup subscription
    harness.pause();

    // Perform remote modification on data not found locally
    final stream = harness.server().getStream(repo.store.aggregate);
    final data2 = {
      'property12': ['value12', 'value13', 'value14']
    };
    final data3 = {
      'property12': ['value13', 'value14', 'value15']
    };
    final eventId = Uuid().v4();
    stream.append(
      '${stream.instanceStream}-0',
      [
        TestStream.asSourceEvent<FooUpdated>(
          uuid,
          data2,
          data3,
          eventId: eventId,
          number: EventNumber(1),
        ),
      ],
    );

    // Act - resume catchup
    await repo.store.catchup(
      repo,
      strict: false,
    );

    // Assert - patches in event 2 is skipped
    expect(foo.number.value, equals(1));
    expect(foo.data, equals(data1));
    expect(foo.skipped, contains(eventId));
    expect(repo.store.isTainted(uuid), isTrue);
  });

  test('Repository replay should throw JsonPatchError', () async {
    // Arrange
    final repo = harness.get<FooRepository>();
    await repo.readyAsync();
    final uuid = Uuid().v4();
    final foo = repo.get(uuid, data: {'property11': 'value11'});
    final data1 = foo.data;
    await repo.push(foo);

    // Stop ALL catchup subscription
    harness.pause();

    // Perform remote modification on data not found locally
    final stream = harness.server().getStream(repo.store.aggregate);
    final data2 = {
      'property12': ['value12', 'value13', 'value14']
    };
    final data3 = {
      'property12': ['value13', 'value14', 'value15']
    };
    final eventId = Uuid().v4();
    stream.append(
      '${stream.instanceStream}-0',
      [
        TestStream.asSourceEvent<FooUpdated>(
          uuid,
          data2,
          data3,
          eventId: eventId,
          number: EventNumber(1),
        ),
      ],
    );

    // Act - resume catchup
    await expectLater(
      repo.replay(strict: true),
      throwsA(isA<JsonPatchError>()),
      reason: 'should throw a JsonPatchError',
    );

    // Assert - patches in event 2 is skipped
    expect(foo.number.value, equals(0));
    expect(foo.data, equals(data1));
    expect(foo.skipped, isNot(contains(eventId)));
    expect(repo.store.isTainted(uuid), isFalse);
    expect(repo.store.isCordoned(uuid), isFalse);
  });

  test('Repository replay should handle JsonPatchError', () async {
    // Arrange
    final repo = harness.get<FooRepository>();
    await repo.readyAsync();
    final uuid = Uuid().v4();
    final foo = repo.get(uuid, data: {'property11': 'value11'});
    final data1 = foo.data;
    await repo.push(foo);

    // Stop ALL catchup subscription
    harness.pause();

    // Perform remote modification on data not found locally
    final stream = harness.server().getStream(repo.store.aggregate);
    final data2 = {
      'property12': ['value12', 'value13', 'value14']
    };
    final data3 = {
      'property12': ['value13', 'value14', 'value15']
    };
    final eventId = Uuid().v4();
    stream.append(
      '${stream.instanceStream}-0',
      [
        TestStream.asSourceEvent<FooUpdated>(
          uuid,
          data2,
          data3,
          eventId: eventId,
          number: EventNumber(1),
        ),
      ],
    );

    // Act - resume catchup
    await repo.store.replay(repo, strict: false);

    // Assert - patches in event 2 is skipped
    expect(foo.number.value, equals(1));
    expect(foo.data, equals(data1));
    expect(foo.skipped, contains(eventId));
    expect(repo.store.isTainted(uuid), isTrue);
  });

  test('Repository subscription should handle EventNumberNotStrictMonotone', () async {
    // Arrange
    final repo = harness.get<FooRepository>();
    await repo.readyAsync();
    final uuid = Uuid().v4();
    final foo = repo.get(uuid, data: {'property11': 'value11'});
    final data1 = foo.data;
    await repo.push(foo);

    // Stop catchup subscription
    repo.store.pause();

    // Perform remote modification on data not found locally
    final stream = harness.server().getStream(repo.store.aggregate);
    final data2 = {
      'uuid': uuid,
      'property11': 'value11',
      'property12': ['value12', 'value13', 'value14']
    };
    final eventId = Uuid().v4();
    stream.append(
      '${stream.instanceStream}-0',
      [
        TestStream.asSourceEvent<FooUpdated>(
          uuid,
          data1,
          data2,
          eventId: eventId,
          // Expected is 1
          number: EventNumber(2),
        ),
      ],
      increment: false,
    );

    // Act - resume catchup
    repo.store.resume();

    // Wait for catchup to complete
    await Future.delayed(Duration(milliseconds: 400));

    // Assert - patches in event 2 is skipped
    expect(foo.number.value, equals(2));
    expect(foo.data, equals(data1));
    expect(foo.skipped, contains(eventId));
    expect(repo.store.isTainted(uuid), isFalse);
    expect(repo.store.isCordoned(uuid), isTrue);
  });

  test('Repository catchup should throw EventNumberNotStrictMonotone', () async {
    // Arrange
    final repo = harness.get<FooRepository>();
    await repo.readyAsync();
    final uuid = Uuid().v4();
    final foo = repo.get(uuid, data: {'property11': 'value11'});
    final data1 = foo.data;
    await repo.push(foo);

    // Stop catchup subscription
    repo.store.pause();

    // Perform remote modification on data not found locally
    final stream = harness.server().getStream(repo.store.aggregate);
    final data2 = {
      'uuid': uuid,
      'property11': 'value11',
      'property12': ['value12', 'value13', 'value14']
    };
    final eventId = Uuid().v4();
    stream.append(
      '${stream.instanceStream}-0',
      [
        TestStream.asSourceEvent<FooUpdated>(
          uuid,
          data1,
          data2,
          eventId: eventId,
          // Expected is 1
          number: EventNumber(2),
        ),
      ],
      increment: false,
    );

    // Act - resume catchup
    await expectLater(
      repo.catchup(strict: true),
      throwsA(isA<EventNumberNotStrictMonotone>()),
      reason: 'should throw a EventNumberNotStrictMonotone',
    );

    // Assert - patches in event 2 is skipped
    expect(foo.number.value, equals(0));
    expect(foo.data, equals(data1));
    expect(foo.skipped, isNot(contains(eventId)));
    expect(repo.store.isTainted(uuid), isFalse);
    expect(repo.store.isCordoned(uuid), isFalse);
  });

  test('Repository catchup should handle EventNumberNotStrictMonotone', () async {
    // Arrange
    final repo = harness.get<FooRepository>();
    await repo.readyAsync();
    final uuid = Uuid().v4();
    final foo = repo.get(uuid, data: {'property11': 'value11'});
    final data1 = foo.data;
    await repo.push(foo);

    // Stop catchup subscription
    repo.store.pause();

    // Perform remote modification on data not found locally
    final stream = harness.server().getStream(repo.store.aggregate);
    final data2 = {
      'uuid': uuid,
      'property11': 'value11',
      'property12': ['value12', 'value13', 'value14']
    };
    final eventId = Uuid().v4();
    stream.append(
      '${stream.instanceStream}-0',
      [
        TestStream.asSourceEvent<FooUpdated>(
          uuid,
          data1,
          data2,
          eventId: eventId,
          // Expected is 1
          number: EventNumber(2),
        ),
      ],
      increment: false,
    );

    // Act - resume catchup
    await repo.catchup(strict: false);

    // Assert - patches in event 2 is skipped
    expect(foo.number.value, equals(2));
    expect(foo.data, equals(data1));
    expect(foo.skipped, contains(eventId));
    expect(repo.store.isTainted(uuid), isFalse);
    expect(repo.store.isCordoned(uuid), isTrue);
  });

  test('Repository should replay throw EventNumberNotStrictMonotone', () async {
    // Arrange
    final repo = harness.get<FooRepository>();
    await repo.readyAsync();
    final uuid = Uuid().v4();
    final foo = repo.get(uuid, data: {'property11': 'value11'});
    final data1 = foo.data;
    await repo.push(foo);

    // Stop catchup subscription
    repo.store.pause();

    // Perform remote modification on data not found locally
    final stream = harness.server().getStream(repo.store.aggregate);
    final data2 = {
      'uuid': uuid,
      'property11': 'value11',
      'property12': ['value12', 'value13', 'value14']
    };
    final eventId = Uuid().v4();
    stream.append(
      '${stream.instanceStream}-0',
      [
        TestStream.asSourceEvent<FooUpdated>(
          uuid,
          data1,
          data2,
          eventId: eventId,
          // Expected is 1
          number: EventNumber(2),
        ),
      ],
      increment: false,
    );

    // Act - resume catchup
    await expectLater(
      repo.replay(strict: true),
      throwsA(isA<EventNumberNotStrictMonotone>()),
      reason: 'should throw a EventNumberNotStrictMonotone',
    );

    // Assert - patches in event 2 is skipped
    expect(foo.number.value, equals(0));
    expect(foo.data, equals(data1));
    expect(foo.skipped, isNot(contains(eventId)));
    expect(repo.store.isTainted(uuid), isFalse);
    expect(repo.store.isCordoned(uuid), isFalse);
  });

  test('Repository replay should handle EventNumberNotStrictMonotone', () async {
    // Arrange
    final repo = harness.get<FooRepository>();
    await repo.readyAsync();
    final uuid = Uuid().v4();
    final foo = repo.get(uuid, data: {'property11': 'value11'});
    final data1 = foo.data;
    await repo.push(foo);

    // Stop catchup subscription
    repo.store.pause();

    // Perform remote modification on data not found locally
    final stream = harness.server().getStream(repo.store.aggregate);
    final data2 = {
      'uuid': uuid,
      'property11': 'value11',
      'property12': ['value12', 'value13', 'value14']
    };
    final eventId = Uuid().v4();
    stream.append(
      '${stream.instanceStream}-0',
      [
        TestStream.asSourceEvent<FooUpdated>(
          uuid,
          data1,
          data2,
          eventId: eventId,
          // Expected is 1
          number: EventNumber(2),
        ),
      ],
      increment: false,
    );

    // Act - resume catchup
    await repo.replay(strict: false);

    // Assert - patches in event 2 is skipped
    expect(foo.number.value, equals(2));
    expect(foo.data, equals(data1));
    expect(foo.skipped, contains(eventId));
    expect(repo.store.isTainted(uuid), isFalse);
    expect(repo.store.isCordoned(uuid), isTrue);
  });

  test('Repository should recover from ES error on push', () async {
    // Arrange
    final repo = harness.get<FooRepository>();
    final stream = harness.server().getStream(repo.store.aggregate);
    await repo.readyAsync();

    // Act - force 500 error on push
    final uuid = Uuid().v4();
    var foo = repo.get(uuid);
    final requests = Future.wait([
      repo.push(foo),
      stream.onWriteServerError(),
    ], eagerError: true);
    await expectLater(requests, throwsA(isA<WriteFailed>()));
    expect(repo.isEmpty, isTrue, reason: 'Repository should be rolled back');

    // Assert second attempt is allowed
    foo = repo.get(uuid);
    await repo.push(foo);
    expect(foo.baseEvent.number, equals(EventNumber(0)));
  });

  test('Repository should recover from ES status 500 on execute', () async {
    // Arrange
    final repo = harness.get<FooRepository>();
    final stream = harness.server().getStream(repo.store.aggregate);
    await repo.readyAsync();

    // Act - force 500 error on execute
    final uuid = Uuid().v4();
    final requests = Future.wait([
      repo.execute(CreateFoo({'uuid': uuid})),
      stream.onWriteServerError(),
    ], eagerError: true);
    await expectLater(requests, throwsA(isA<WriteFailed>()));
    expect(repo.isEmpty, isTrue, reason: 'Repository should be rolled back');

    // Assert second attempt is allowed
    await repo.execute(CreateFoo({'uuid': uuid}));
    final foo = repo.get(uuid);
    expect(foo.baseEvent.number, equals(EventNumber(0)));
  });

  test('Repository should recover on timeout and ES error on push', () async {
    // Arrange
    final repo = harness.get<FooRepository>();
    final stream = harness.server().getStream(repo.store.aggregate);
    await repo.readyAsync();

    // Act - force 500 error on push
    final uuid = Uuid().v4();
    var foo = repo.get(uuid);
    final requests = Future.wait([
      stream.onWriteDelay(
        override: true,
        duration: Duration(milliseconds: 100),
      ),
      repo.push(
        foo,
        timeout: Duration(milliseconds: 10),
      ),
    ], eagerError: false);
    await expectLater(
      requests,
      throwsA(isA<TimeoutException>()),
    );
    expect(repo.isEmpty, isTrue, reason: 'Repository should be rolled back');

    // Assert second attempt is allowed
    foo = repo.get(uuid);
    await repo.push(foo);
    expect(foo.baseEvent.number, equals(EventNumber(0)));
  });

  test('Repository should recover on timeout and ES error on execute', () async {
    // Arrange
    final repo = harness.get<FooRepository>();
    final stream = harness.server().getStream(repo.store.aggregate);
    await repo.readyAsync();

    // Act - force 500 error on push
    final uuid = Uuid().v4();
    final requests = Future.wait([
      stream.onWriteDelay(
        override: true,
        duration: Duration(milliseconds: 100),
      ),
      repo.execute(
        CreateFoo({'uuid': uuid}),
        timeout: Duration(milliseconds: 10),
      ),
    ], eagerError: false);
    await expectLater(
      requests,
      throwsA(isA<TimeoutException>()),
    );
    expect(repo.isEmpty, isTrue, reason: 'Repository should be rolled back');

    // Assert second attempt is allowed
    await repo.execute(CreateFoo({'uuid': uuid, 'property1': 'value1'}));
    final foo = repo.get(uuid);
    expect(foo.baseEvent.number, equals(EventNumber(0)));
  });

  test('Repository should recover push timeout and ES write completes after', () async {
    // Arrange
    final repo = harness.get<FooRepository>();
    final stream = harness.server().getStream(repo.store.aggregate);
    await repo.readyAsync();

    // Act - force 500 error on push
    final uuid = Uuid().v4();
    var foo = repo.get(uuid);
    final requests = Future.wait([
      repo.push(
        foo,
        timeout: Duration(milliseconds: 10),
      ),
      stream.onWriteDelay(
        override: false,
        duration: Duration(milliseconds: 100),
      ),
    ], eagerError: false);
    await expectLater(
      requests,
      throwsA(isA<TimeoutException>()),
    );
    // Wait for write to complete
    await Future.delayed(Duration(milliseconds: 250));
    expect(
      repo.isNotEmpty,
      isTrue,
      reason: 'Repository should contain aggregate written after timeout',
    );

    // Assert second attempt is allowed
    foo = repo.get(uuid);
    foo.patch({'uuid': uuid, 'property1': 'value1'}, emits: FooUpdated);
    await repo.push(foo);

    // Assert that FooCreated which was late is applied
    expect(foo.createdBy.type, equals('$FooCreated'));
    expect(foo.baseEvent.number, equals(EventNumber(1)));
  });

  test('Repository should recover execute timeout and ES write completes after', () async {
    // Arrange
    final repo = harness.get<FooRepository>();
    final stream = harness.server().getStream(repo.store.aggregate);
    await repo.readyAsync();

    // Act - force 500 error on push
    final uuid = Uuid().v4();
    final requests = Future.wait([
      repo.execute(
        CreateFoo({'uuid': uuid}),
        timeout: Duration(milliseconds: 10),
      ),
      stream.onWriteDelay(
        override: false,
        duration: Duration(milliseconds: 100),
      ),
    ], eagerError: false);
    await expectLater(
      requests,
      throwsA(isA<TimeoutException>()),
    );
    // Wait for write to complete
    await Future.delayed(Duration(milliseconds: 250));
    expect(
      repo.isNotEmpty,
      isTrue,
      reason: 'Repository should contain aggregate written after timeout',
    );

    // Assert second attempt is allowed
    await repo.execute(UpdateFoo({'uuid': uuid, 'property1': 'value1'}));
    final foo = repo.get(uuid);

    // Assert that FooCreated which was late is applied
    expect(foo.createdBy.type, equals('$FooCreated'));
    expect(foo.baseEvent.number, equals(EventNumber(1)));
  });

  test('Repository should update field createdBy after create and push', () async {
    // Arrange
    final repo = harness.get<FooRepository>();
    await repo.readyAsync();

    // Act
    final uuid = Uuid().v4();
    final foo = repo.get(uuid);
    final createdBy = foo.createdBy;
    final createdLocally = createdBy.created;
    unawaited(repo.push(foo));

    // Allow subscription to catch up
    await repo.store.asStream().where(
      (event) {
        return event.remote;
      },
    ).first;
    final createdWhen = repo.get(uuid).createdWhen;

    // Assert
    expect(foo.createdBy, equals(createdBy), reason: 'createdBy should not change identity');
    expect(
      createdWhen,
      isNot(equals(createdLocally)),
      reason: 'createdBy should change created datetime',
    );
  });

  test('Repository should update field updatedBy after patch and push', () async {
    // Arrange
    final repository = harness.get<FooRepository>();
    await repository.readyAsync();

    // Act
    final uuid = Uuid().v4();
    final foo = repository.get(uuid);
    foo.patch({'property': 'patched'}, emits: FooUpdated);
    final createdBy = foo.createdBy;
    final changedBy = foo.changedBy;
    expect(
      createdBy,
      isNot(equals(changedBy)),
      reason: 'Patch should changed updatedBy',
    );
    unawaited(repository.push(foo));

    // Allow subscription to catch up
    await repository.store.asStream().take(4).toList();
    final changedWhen = repository.get(uuid).changedWhen;

    // Assert
    expect(
      identical(foo.changedBy, changedBy),
      isFalse,
      reason: 'changedBy should change identity',
    );
    expect(
      changedWhen,
      isNot(equals(changedBy.created)),
      reason: 'changedBy should not change created datetime',
    );
  });

  test('Repository should only apply operations [add, replace, move] when patching local changes', () async {
    // Arrange
    final repository = harness.get<FooRepository>();
    await repository.readyAsync();

    // Act
    final uuid = Uuid().v4();
    final foo = repository.get(uuid, data: {
      'property1': 'value1',
      'property2': 'value2',
      'list1': ['item1', 'item2'],
      'object1': {
        'member1': 'value1',
        'member2': 'value2',
      }
    });
    foo.patch({
      'property3': 'value3',
      'property2': 'value4',
      'list1': ['item3'],
      'object1': {
        'member2': 'value4',
        'member3': 'value3',
      }
    }, emits: FooUpdated);

    // Assert
    expect(foo.data, containsPair('property1', 'value1')); // keep
    expect(foo.data, containsPair('property3', 'value3')); // add value
    expect(foo.data, containsPair('property2', 'value4')); // replace value
    expect(foo.data, containsPair('list1', ['item3'])); // replace list of values
    expect(
        foo.data,
        containsPair('object1', {
          'member1': 'value1',
          'member2': 'value4',
          'member3': 'value3',
        }));
  });

  test('Repository should only apply operations [add, replace, move] when patching remote changes', () async {
    // Arrange
    final repo1 = harness.get<FooRepository>(port: 4000);
    final repo2 = harness.get<FooRepository>(port: 4001);
    await repo1.readyAsync();
    await repo2.readyAsync();

    // Act
    final uuid = Uuid().v4();
    final foo1 = repo1.get(uuid, data: {
      'property1': 'value1',
      'property2': 'value2',
      'list1': ['item1', 'item2'],
      'object1': {
        'member1': 'value1',
        'member2': 'value2',
      }
    });
    unawaited(repo1.push(foo1));
    await repo2.store.asStream().first;
    final foo2 = repo2.get(uuid);
    foo2.patch({
      'property3': 'value3',
      'property2': 'value4',
      'list1': ['item3'],
      'object1': {
        'member2': 'value4',
        'member3': 'value3',
      }
    }, emits: FooUpdated);
    unawaited(repo2.push(foo2));
    await repo1.store.asStream().where((event) {
      return event.type == 'FooUpdated';
    }).first;

    // Assert
    expect(foo1.data, containsPair('property1', 'value1')); // keep
    expect(foo1.data, containsPair('property3', 'value3')); // add value
    expect(foo1.data, containsPair('property2', 'value4')); // replace value
    expect(foo1.data, containsPair('list1', ['item3'])); // replace list of values
    expect(
        foo1.data,
        containsPair('object1', {
          'member1': 'value1',
          'member2': 'value4',
          'member3': 'value3',
        })); // keep, add and replace member values
  });

  test('Repository should catch-up to head of events in remote stream', () async {
    // Arrange
    final repo1 = harness.get<FooRepository>(port: 4000);
    final repo2 = harness.get<FooRepository>(port: 4001);
    final repo3 = harness.get<FooRepository>(port: 4002);
    await repo1.readyAsync();
    await repo2.readyAsync();
    await repo3.readyAsync();

    await _assertCatchUp(repo1, repo2, repo3, 1);
    await _assertCatchUp(repo1, repo2, repo3, 2);
    await _assertCatchUp(repo1, repo2, repo3, 3);
    await _assertCatchUp(repo1, repo2, repo3, 4);
    await _assertCatchUp(repo1, repo2, repo3, 5);
    await _assertCatchUp(repo1, repo2, repo3, 6);
  });

  test('Repository should catch-up given aggregates only', () async {
    // Arrange
    final repo = harness.get<FooRepository>(port: 4000);
    await repo.readyAsync();
    final uuid1 = Uuid().v4();
    final foo1 = repo.get(uuid1, data: {'property11': 'value11'});
    final data11 = foo1.data;
    await repo.push(foo1);

    final uuid2 = Uuid().v4();
    final foo2 = repo.get(uuid2, data: {'property21': 'value21'});
    final data21 = foo2.data;
    await repo.push(foo2);

    final uuid3 = Uuid().v4();
    final foo3 = repo.get(uuid3, data: {'property31': 'value31'});
    final data31 = foo3.data;
    await repo.push(foo3);

    // Stop catchup subscription
    repo.store.pause();

    // Perform remote modification
    final stream = harness.server().getStream(repo.store.aggregate);
    final data12 = Map<String, dynamic>.from(data11)
      ..addAll(
        {'property12': 'value12'},
      );
    stream.append(
      '${stream.instanceStream}-0',
      [
        TestStream.asSourceEvent<FooUpdated>(
          uuid1,
          data11,
          data12,
          number: EventNumber(1),
        ),
      ],
    );
    final data22 = Map<String, dynamic>.from(data21)
      ..addAll(
        {'property22': 'value22'},
      );
    stream.append(
      '${stream.instanceStream}-1',
      [
        TestStream.asSourceEvent<FooUpdated>(
          uuid2,
          data21,
          data22,
          number: EventNumber(1),
        ),
      ],
    );
    final data32 = Map<String, dynamic>.from(data31)
      ..addAll(
        {'property32': 'value32'},
      );
    stream.append(
      '${stream.instanceStream}-2',
      [
        TestStream.asSourceEvent<FooUpdated>(
          uuid3,
          data31,
          data32,
          number: EventNumber(1),
        ),
      ],
    );

    // Act - catchup on foo1 and foo3 only
    final events = await repo.catchup(uuids: [uuid1, uuid3]);

    // Assert - foo1 and foo3 is updated
    expect(events, 2, reason: 'should catchup on 2 events');
    expect(foo1.number.value, equals(1));
    expect(foo1.data, equals(data12));
    expect(foo3.number.value, equals(1));
    expect(foo3.data, equals(data32));

    // Assert - foo2 is unchanged
    expect(foo2.number.value, equals(0));
    expect(foo2.data, equals(data21));
  });

  test('Repository should replace data in given aggregate', () async {
    // Arrange
    final repo = harness.get<FooRepository>();
    await repo.readyAsync();

    final uuid = Uuid().v4();
    final data1 = {'uuid': uuid, 'parameter1': 'value1'};
    final prev = repo.get(uuid, data: data1);
    await repo.push(prev);
    await repo.store.asStream().where((e) => e.remote).first;

    // Act
    final data2 = {'uuid': 'any', 'parameter2': 'value2'};
    final next = repo.replace(
      uuid,
      data: data2,
      strict: false,
    );

    // Assert
    expect(next.data, data2..addAll({'uuid': uuid}));
    expect(prev.number, next.number);
    expect(prev.skipped, next.skipped);
    expect(prev.applied, next.applied);
    expect(prev.createdBy, next.createdBy);
    expect(prev.changedBy, next.changedBy);
    expect(prev.deletedBy, next.deletedBy);
    expect(
      next.headEvent,
      equals(prev.headEvent),
    );
    expect(
      next.baseEvent,
      equals(prev.baseEvent),
    );
    expect(next.base, equals(isNot(prev.base)));
    expect(next.data, equals(isNot(prev.data)));
    expect(next.head, equals(isNot(prev.head)));
  });

  test('Repository should replay given aggregates only', () async {
    // Arrange
    final repo = harness.get<FooRepository>(port: 4000);
    await repo.readyAsync();
    final uuid1 = Uuid().v4();
    final foo1 = repo.get(uuid1, data: {'property11': 'value11'});
    final data11 = foo1.data;
    await repo.push(foo1);

    final uuid2 = Uuid().v4();
    final foo2 = repo.get(uuid2, data: {'property21': 'value21'});
    final data21 = foo2.data;
    await repo.push(foo2);

    final uuid3 = Uuid().v4();
    final foo3 = repo.get(uuid3, data: {'property31': 'value31'});
    final data31 = foo3.data;
    await repo.push(foo3);

    // Stop catchup subscriptions
    harness.pause();

    // Perform remote modification
    final stream = harness.server().getStream(repo.store.aggregate);
    final data12 = Map<String, dynamic>.from(data11)
      ..addAll(
        {'property12': 'value12'},
      );
    stream.append(
      '${stream.instanceStream}-0',
      [
        TestStream.asSourceEvent<FooUpdated>(
          uuid1,
          data11,
          data12,
          number: EventNumber(1),
        ),
      ],
    );
    final data22 = Map<String, dynamic>.from(data21)
      ..addAll(
        {'property22': 'value22'},
      );
    stream.append(
      '${stream.instanceStream}-1',
      [
        TestStream.asSourceEvent<FooUpdated>(
          uuid2,
          data21,
          data22,
          number: EventNumber(1),
        ),
      ],
    );
    final data32 = Map<String, dynamic>.from(data31)
      ..addAll(
        {'property32': 'value32'},
      );
    stream.append(
      '${stream.instanceStream}-2',
      [
        TestStream.asSourceEvent<FooUpdated>(
          uuid3,
          data31,
          data32,
          number: EventNumber(1),
        ),
      ],
    );

    // Act - replay on foo1 and foo3 only
    final events = await repo.replay(uuids: [
      uuid1,
      uuid3,
    ]);

    // Assert - foo1 and foo3 is updated
    expect(events, 4, reason: 'should catchup on 4 events');
    expect(foo1.number.value, equals(1));
    expect(foo1.data, equals(data12));
    expect(foo3.number.value, equals(1));
    expect(foo3.data, equals(data32));

    // Assert - foo2 is unchanged
    expect(foo2.number.value, equals(0));
    expect(foo2.data, equals(data21));
  });

  test('Repository should restart subscriptions when behind', () async {
    // Arrange
    final repo = harness.get<FooRepository>(port: 4000);
    await repo.readyAsync();

    final uuid1 = Uuid().v4();
    final data11 = {'property11': 'value11'};

    final uuid2 = Uuid().v4();
    final data21 = {'property21': 'value21'};

    final uuid3 = Uuid().v4();
    final data31 = {'property31': 'value31'};

    // Stop catchup subscription
    repo.store.pause();

    // Perform remote modification
    final stream = harness.server().getStream(repo.store.aggregate);
    final data12 = Map<String, dynamic>.from(data11)
      ..addAll(
        {'property12': 'value12'},
      );
    stream.append(
      '${stream.instanceStream}-0',
      [
        TestStream.asSourceEvent<FooCreated>(
          uuid1,
          {},
          data11,
          number: EventNumber(0),
        ),
        TestStream.asSourceEvent<FooUpdated>(
          uuid1,
          data11,
          data12,
          number: EventNumber(1),
        ),
      ],
    );
    final data22 = Map<String, dynamic>.from(data21)
      ..addAll(
        {'property22': 'value22'},
      );
    stream.append(
      '${stream.instanceStream}-1',
      [
        TestStream.asSourceEvent<FooCreated>(
          uuid2,
          {},
          data21,
          number: EventNumber(0),
        ),
        TestStream.asSourceEvent<FooUpdated>(
          uuid2,
          data21,
          data22,
          number: EventNumber(1),
        ),
      ],
    );
    final data32 = Map<String, dynamic>.from(data31)
      ..addAll(
        {'property32': 'value32'},
      );
    stream.append(
      '${stream.instanceStream}-2',
      [
        TestStream.asSourceEvent<FooCreated>(
          uuid3,
          {},
          data31,
          number: EventNumber(0),
        ),
        TestStream.asSourceEvent<FooUpdated>(
          uuid3,
          data31,
          data32,
          number: EventNumber(1),
        ),
      ],
    );

    // Catch any events raised
    // before waiting on all
    // events to be seen
    final seen = <Event>[];
    repo.store.asStream().where((e) => e.remote).listen((event) {
      seen.add(event);
    });

    // Act - Force subscription behind
    await repo.replay();

    // Act - resume subscriptions
    final offsets2 = repo.store.resume();

    // Assert - subscription offset to current + 1
    expect(
      offsets2[FooRepository],
      repo.store.current() + 1,
      reason: 'should resume from current',
    );
  });

  test('Repository should not push local aggregate with local concurrent modifications', () async {
    // Arrange - local aggregate
    final repo = harness.get<FooRepository>();
    await repo.readyAsync();
    final uuid = Uuid().v4();
    final foo = repo.get(uuid, data: {'property1': 0});

    // Act on repo without waiting
    final request1 = repo.execute(
      UpdateFoo({'uuid': uuid, 'property1': repo.get(uuid).elementAt<int>('property1') + 1}),
    );
    final request2 = repo.execute(
      UpdateFoo({'uuid': uuid, 'property1': repo.get(uuid).elementAt<int>('property1') + 1}),
    );

    // Assert that exception is thrown
    await expectLater(
      // Will not on each command
      // before executing the next
      Future.wait<Iterable<DomainEvent>>(
        [request1, request2],
      ),
      throwsA(isA<ConcurrentWriteOperation>()),
    );

    // Assert
    expect(foo.isChanged, isFalse);
    expect(foo.getLocalEvents(), isEmpty);
    expect(foo.data, containsPair('property1', 1));
    expect(repo.count(), equals(1));
    expect(repo.inTransaction(uuid), isFalse);
  });

  test('Repository should not push remote aggregate with local concurrent modifications', () async {
    // Arrange - remote aggregate
    final repo = harness.get<FooRepository>();
    await repo.readyAsync();
    final uuid = Uuid().v4();
    final foo = repo.get(uuid, data: {'property1': 0});
    await repo.push(foo);

    // Act on repo without waiting
    final request1 = repo.execute(
      UpdateFoo({'uuid': uuid, 'property1': repo.get(uuid).elementAt<int>('property1') + 1}),
    );
    final request2 = repo.execute(
      UpdateFoo({'uuid': uuid, 'property1': repo.get(uuid).elementAt<int>('property1') + 1}),
    );

    // Assert that exception is thrown
    await expectLater(
      // Will not on each command
      // before executing the next
      Future.wait<Iterable<DomainEvent>>(
        [request1, request2],
      ),
      throwsA(isA<ConcurrentWriteOperation>()),
    );

    // Assert
    expect(foo.isChanged, isFalse);
    expect(foo.getLocalEvents(), isEmpty);
    expect(foo.data, containsPair('property1', 1));
    expect(repo.count(), equals(1));
    expect(repo.inTransaction(uuid), isFalse);
  });

  test('Repository should resolve remote concurrent modification on push', () async {
    // Arrange
    final repo = harness.get<FooRepository>();
    final stream = harness.server().getStream(repo.store.aggregate);
    await repo.readyAsync();
    final uuid = Uuid().v4();
    final foo = repo.get(uuid, data: {'property1': 'value1'});
    await repo.push(foo);
    expect(foo.number.value, equals(0));

    // Simulate concurrent modification
    // by manually updating remote stream
    stream.append('${stream.instanceStream}-0', [
      TestStream.asSourceEvent<FooUpdated>(
        uuid,
        {'property1': 'value1'},
        {
          'property1': 'value1',
          'property2': 'value2',
          'property3': 'value3',
        },
      )
    ]);

    // Act
    foo.patch({'property3': 'value3'}, emits: FooUpdated);
    await repo.push(foo);
    foo.patch({'property4': 'value4'}, emits: FooUpdated);
    await repo.push(foo);
    foo.patch({'property5': 'value5'}, emits: FooUpdated);
    await repo.push(foo);

    // Assert conflict resolved
    expect(repo.count(), equals(1));
    expect(foo.number.value, equals(4), reason: 'Should be 4');
    expect(repo.number.value, equals(4), reason: 'Should be 4');
    expect(foo.data, containsPair('property1', 'value1'));
    expect(foo.data, containsPair('property2', 'value2'));
    expect(foo.data, containsPair('property3', 'value3'));
    expect(foo.data, containsPair('property4', 'value4'));
    expect(foo.data, containsPair('property5', 'value5'));
  });

  test(
    'Repository should fail on push when manual merge is needed',
    () async {
      // Arrange
      final repo = harness.get<FooRepository>();
      final stream = harness.server().getStream(repo.store.aggregate);
      await repo.readyAsync();

      // Act - Simulate conflict by manually updating remote stream
      final uuid = Uuid().v4();
      final foo = repo.get(uuid, data: {'property1': 'value1'});
      await repo.push(foo);
      final data1 = foo.data;
      final data2 = {
        'uuid': uuid,
        'property1': 'value1',
        'property2': 'value2',
        'property3': 'remote',
      };
      stream.append('${stream.instanceStream}-0', [
        TestStream.asSourceEvent<FooUpdated>(
          uuid,
          {'property1': 'value1'},
          data2,
        )
      ]);
      foo.patch({'property3': 'local'}, emits: FooUpdated);

      // Assert
      await expectLater(
        repo.push(foo),
        throwsA(isA<ConflictNotReconcilable>()),
      );

      // Assert rollback to remote state
      expect(repo.count(), equals(1));
      expect(foo.data, isNot(equals(data1)));
      expect(foo.data, equals(data2));
    },
    // TODO: Fix missing rollback
    retry: 1,
  );

  test('Repository should not push on execute in an transaction', () async {
    // Arrange
    final repo = harness.get<FooRepository>();
    await repo.readyAsync();
    final uuid = Uuid().v4();
    final trx = repo.getTransaction(uuid);
    final foo = repo.get(uuid, data: {'property1': 1});

    // Act on repo
    await repo.execute(
      UpdateFoo({'uuid': uuid, 'property1': repo.get(uuid).elementAt<int>('property1') + 1}),
    );

    // Act on transaction
    await trx.execute(
      UpdateFoo({'uuid': uuid, 'property1': repo.get(uuid).elementAt<int>('property1') + 1}),
    );

    // Assert
    expect(foo.isChanged, isTrue);
    expect(foo.getLocalEvents(), isNotEmpty);
    expect(await trx.push(), isA<Iterable<DomainEvent>>());
    expect(foo.isChanged, isFalse);
    expect(foo.getLocalEvents(), isEmpty);
    expect(repo.count(), equals(1));
    expect(repo.inTransaction(uuid), isFalse);
    expect(foo.data, containsPair('property1', 3));
  });

  test(
    'Repository should commit transactions on push',
    () async {
      // Arrange - turn of snapshots to ensure all events are kept during this test
      await _repositoryShouldCommitTransactionsOnPush(
        harness,
        withSnapshots: false,
      );
      final repo1 = harness.get<FooRepository>(instance: 1);
      final repo2 = harness.get<FooRepository>(instance: 2);
      expect(repo1.snapshot, isNull);
      expect(repo2.snapshot, isNull);
    },
    // TODO: Fix await timeout
    retry: 1,
    timeout: Timeout(Duration(seconds: 5)),
  );

  test(
    'Transaction should fail on push when manual merge is needed',
    () async {
      // Arrange
      final repo = harness.get<FooRepository>();
      final stream = harness.server().getStream(repo.store.aggregate);
      await repo.readyAsync();

      // Act - Simulate conflict by manually updating remote stream
      final uuid = Uuid().v4();
      final foo = repo.get(uuid, data: {'property1': 'value1'});
      await repo.push(foo);
      stream.append('${stream.instanceStream}-0', [
        TestStream.asSourceEvent<FooUpdated>(
          uuid,
          {'property1': 'value1'},
          {
            'property1': 'value1',
            'property2': 'value2',
            'property3': 'remote',
          },
        )
      ]);

      // Act - make conflict patch
      final trx = repo.getTransaction(uuid);
      foo.patch({'property3': 'local'}, emits: FooUpdated);

      // Assert
      await expectLater(
        trx.push(),
        throwsA(isA<ConflictNotReconcilable>()),
      );

      // Assert conflict unresolved
      expect(repo.count(), equals(1));
      expect(repo.isAutomatic, isTrue);
      expect(repo.inTransaction(uuid), isFalse);
      expect(
        trx.isCompleted,
        isTrue,
        reason: 'Should be completed',
      );
      expect(foo.data, containsPair('property1', 'value1'));
      expect(foo.data, containsPair('property2', 'value2'));
      expect(foo.data, containsPair('property3', 'remote'));
    },
    // TODO: Fix unstable rollback
    retry: 1,
  );

  test('Repository should consume events with strategy RoundRobin', () async {
    // Arrange
    final repo1 = harness.get<FooRepository>(instance: 1)..compete(consume: 1);
    final repo2 = harness.get<FooRepository>(instance: 2)..compete(consume: 1);
    harness.server().withSubscription(repo1.store.aggregate, group: '${repo1.aggregateType}');
    final stream = harness.server().getStream(repo1.store.aggregate);
    await repo1.readyAsync();
    await repo2.readyAsync();

    // Act
    final uuid1 = Uuid().v4();
    stream.append('${stream.instanceStream}-0', [
      TestStream.asSourceEvent<FooCreated>(
        uuid1,
        {},
        {'property1': 'value1'},
      )
    ]);
    final uuid2 = Uuid().v4();
    stream.append('${stream.instanceStream}-1', [
      TestStream.asSourceEvent<FooCreated>(
        uuid2,
        {},
        {'property2': 'value2'},
      )
    ]);

    // Assert
    await repo1.store.asStream().first;
    final foo1 = repo1.get(uuid1);
    expect(repo1.count(), equals(1));
    expect(foo1.data, containsPair('property1', 'value1'));

    await repo2.store.asStream().first;
    final foo2 = repo2.get(uuid2);
    expect(repo2.count(), equals(1));
    expect(foo2.data, containsPair('property2', 'value2'));
  });

  test('Repository should throw AggregateNotFound on push with unknown AggregateRoot', () async {
    // Arrange - start two empty repos both assuming stream-0 to be first write
    final repo1 = harness.get<FooRepository>(instance: 1);
    await repo1.readyAsync();
    final repo2 = harness.get<FooRepository>(instance: 2);
    await repo2.readyAsync();

    // Act
    final foo1 = repo1.get(Uuid().v4());

    // Assert
    await expectLater(() => repo2.push(foo1), throwsA(isA<AggregateNotFound>()));
  });

  test('Transaction should throw AggregateNotFound on push with unknown AggregateRoot', () async {
    // Arrange - start two empty repos both assuming stream-0 to be first write
    final repo1 = harness.get<FooRepository>(instance: 1);
    await repo1.readyAsync();
    final repo2 = harness.get<FooRepository>(instance: 2);
    await repo2.readyAsync();

    // Act
    final foo1 = repo1.get(Uuid().v4());

    // Assert
    final trx = repo2.getTransaction(foo1.uuid);
    await expectLater(() => trx.push(), throwsA(isA<AggregateNotFound>()));
    expect(repo2.inTransaction(foo1.uuid), isTrue);
  });

  test('Repository should enforce strict order of in-proc create aggregate operations', () async {
    // Arrange
    final repo = harness.get<FooRepository>();
    await repo.readyAsync();

    // Act - execute pushes without awaiting
    // the result. Note: Will not on each command
    // before executing the next
    final results = await Future.wait<Iterable<DomainEvent>>(
      _createMultipleAggregates(repo, 10).cast(),
    );

    // Assert - strict order
    final events = _assertResultStrictOrder(results);

    // Assert - unique events
    _assertUniqueEvents(repo, events);
  });

  test('Repository should enforce strict incremental order of in-proc command executions', () async {
    // Arrange1
    final repo = harness.get<FooRepository>();
    await repo.readyAsync();
    final uuid = Uuid().v4();
    final foo = repo.get(uuid, data: {'property1': 0});
    final created = await repo.push(foo);

    // Act - execute pushes without awaiting the result
    final results = <Iterable<DomainEvent>>[];
    for (var i = 0; i < 10; i++) {
      results.add(await repo.execute(
        UpdateFoo({'uuid': uuid, 'property1': repo.get(uuid).elementAt<int>('property1') + 1}),
      ));
    }

    // Assert - strict order
    final events = [
      ...created,
      ..._assertMonotonePatch(results),
    ];

    // Assert - unique events
    _assertUniqueEvents(repo, events);
  });

  test('Repository should enforce strict order of event numbers', () async {
    // Arrange
    final uuid = Uuid().v4();
    final repo1 = harness.get<FooRepository>();
    final repo2 = harness.get<FooRepository>();
    await repo1.readyAsync();
    await repo2.readyAsync();

    // Act - execute
    unawaited(_createMultipleEvents(repo1, uuid, 10));
    final events = await takeLocal(repo2.store.asStream(), 10);
    expect(events.last.number.value, equals(9));

    // Assert - repo 1
    final events1 = _assertEventNumberStrictOrder(repo1, uuid);
    _assertUniqueEvents(repo1, events1);

    // Assert - repo 2
    final events2 = _assertEventNumberStrictOrder(repo2, uuid);
    _assertUniqueEvents(repo1, events2);
  });

  test(
    'Repository should resolve concurrent remote modification on command execute',
    () async {
      // Arrange
      final repo = harness.get<FooRepository>();
      final stream = harness.server().getStream(repo.store.aggregate);
      await repo.readyAsync();

      // Catch any events raised
      // before waiting on all
      // events to be seen
      final seen = <Event>[];
      repo.store.asStream().where((e) => e.remote).listen((event) {
        seen.add(event);
      });

      // Act - Simulate concurrent modification by manually updating remote stream
      final uuid = Uuid().v4();
      final foo = repo.get(uuid, data: {'property1': 'value1'});
      await repo.push(foo);
      stream.append('${stream.instanceStream}-0', [
        TestStream.asSourceEvent<FooUpdated>(
          uuid,
          {'property1': 'value1'},
          {
            'property1': 'value1',
            'property2': 'value2',
            'property3': 'value3',
          },
        )
      ]);

      // Act
      await repo.execute(UpdateFoo({'uuid': uuid, 'property3': 'value3'}));

      // Assert conflict resolved
      expect(repo.count(), equals(1));
      expect(foo.data, containsPair('property1', 'value1'));
      expect(foo.data, containsPair('property2', 'value2'));
      expect(foo.data, containsPair('property3', 'value3'));
      expect(foo.hasConflicts, isFalse);

      // Wait until event is remote
      await takeRemote(repo.store.asStream(), 2 - seen.length, distinct: true);
      expect(repo.number.value, equals(2));
    },
    // TODO: Fix timeout on takeRemote
    retry: 1,
    timeout: Timeout(Duration(seconds: 3)),
  );

  test('Repository should enforce strict order of concurrent create aggregate operations ', () async {
    // Arrange
    final repo1 = harness.get<FooRepository>(port: 4000);
    final repo2 = harness.get<FooRepository>(port: 4001);
    await repo1.readyAsync();
    await repo2.readyAsync();
    final group = StreamGroup<Event>();
    await group.add(repo1.store.asStream());
    await group.add(repo2.store.asStream());

    // Act - execute pushes and await the results
    final requests1 = _createMultipleAggregates(repo1, 10, prefix: '4000');
    final requests2 = _createMultipleAggregates(repo2, 10, prefix: '4001');

    // Wait for subscriptions to catch up in both repos
    await takeRemote(group.stream, 2 * 2 * 10, distinct: false);
    await group.close();

    // Assert - strict order
    final results1 = await Future.wait<Iterable<DomainEvent>>(requests1);
    final results2 = await Future.wait<Iterable<DomainEvent>>(requests2);
    _assertResultStrictOrder(results1);
    _assertResultStrictOrder(results2);
    expect(repo1.number.value, equals(19));
    expect(repo2.number.value, equals(19));
  });

  test('Repository should rollback changes when command fails', () async {
    // Arrange
    final repo = harness.get<FooRepository>();
    final stream = harness.server().getStream(repo.store.aggregate);
    await repo.readyAsync();

    // Act - Simulate conflict by manually updating remote stream
    final uuid = Uuid().v4();
    final foo = repo.get(uuid, data: {'property1': 'value1'});
    await repo.push(foo);
    stream.append('${stream.instanceStream}-0', [
      TestStream.asSourceEvent<FooUpdated>(
        uuid,
        {'property1': 'value1'},
        {
          'property1': 'value1',
          'property2': 'value2',
          'property3': 'value3',
        },
      )
    ]);
    final command = UpdateFoo({
      'uuid': uuid,
      'property3': 'value4',
    });

    // Assert
    await expectLater(
      repo.execute(command),
      throwsA(isA<ConflictNotReconcilable>()),
    );
    expect(
      repo.isChanged,
      isFalse,
      reason: 'Repository should rollback changes when command fails',
    );
    expect(
      foo.isChanged,
      isFalse,
      reason: 'Repository should rollback changes when command fails',
    );
  });

  test('Repository should rollback changes when transaction fails', () async {
    // Arrange
    final repo = harness.get<FooRepository>();
    final stream = harness.server().getStream(repo.store.aggregate);
    await repo.readyAsync();
    final uuid = Uuid().v4();
    final foo = repo.get(uuid, data: {'property1': 'value1'});
    await repo.push(foo);
    final trx = repo.getTransaction(uuid);

    // Act - Simulate conflict by manually updating remote stream
    stream.append('${stream.instanceStream}-0', [
      TestStream.asSourceEvent<FooUpdated>(
        uuid,
        {'property1': 'value1'},
        {
          'property1': 'value1',
          'property2': 'value2',
          'property3': 'value3',
        },
      )
    ]);
    final command = UpdateFoo({
      'uuid': uuid,
      'property3': 'value4',
    });
    await trx.execute(command);

    // Assert
    await expectLater(
      trx.push(),
      throwsA(isA<ConflictNotReconcilable>()),
    );
    expect(repo.inTransaction(uuid), isFalse);
    expect(
      repo.isChanged,
      isFalse,
      reason: 'Repository should rollback changes when command fails',
    );
    expect(
      foo.isChanged,
      isFalse,
      reason: 'Repository should rollback changes when command fails',
    );
  });

  test('Repository should catchup before policy write', () async {
    // Arrange first server
    final foos1 = harness.get<FooRepository>(port: 4000);
    final bars1 = harness.get<BarRepository>(port: 4000);
    await foos1.readyAsync();
    await bars1.readyAsync();

    // Arrange second server
    final foos2 = harness.get<FooRepository>(port: 4001);
    final bars2 = harness.get<BarRepository>(port: 4001);
    await foos2.readyAsync();
    await bars2.readyAsync();

    final group = StreamGroup<Event>.broadcast();
    await group.add(foos1.store.asStream());
    await group.add(bars1.store.asStream());
    await group.add(foos2.store.asStream());
    await group.add(bars2.store.asStream());

    // Catch any events raised
    // before waiting on all
    // events to be seen
    final seen = <Event>[];
    group.stream.listen((event) {
      seen.add(event);
    });

    // Act on first server
    final fuuid = Uuid().v4();
    final fdata = {
      'uuid': fuuid,
      'property1': 'value1',
    };
    final foo = foos1.get(fuuid, data: fdata);
    await foos1.push(foo);

    // Ensure Foo exists in server 4001 before
    // proceeding (boo rule will not wait if
    // catchup returns empty)
    await foos2.store.asStream().where((e) => e is FooCreated).first;

    // Act on second server
    final buuid = Uuid().v4();
    final bdata = {
      'uuid': buuid,
      // Bar has a rule that will match this
      'foo': {'uuid': fuuid}
    };
    final bar = bars2.get(buuid, data: bdata);
    await bars2.push(bar);

    // Wait for catchup
    // 3 local events
    // 3 _onReplace from subscription
    // 3 _onApply from subscription
    await group.stream.take(9 - seen.length).toList();
    // await group.close();

    // Assert all states are up to date
    fdata.addAll({'updated': 'value'});
    expect(foos1.get(fuuid).data, fdata, reason: 'Foo in instance 1 should be updated');
    expect(bars1.get(buuid).data, bdata, reason: 'Bar in instance 1 should be updated');
    expect(foos2.get(fuuid).data, fdata, reason: 'Foo in instance 2 should be updated');
    expect(bars2.get(buuid).data, bdata, reason: 'Bar in instance 2 should be updated');
  });

  test('Repository should build from last snapshot', () async {
    // Arrange
    await _testShouldBuildFromLastSnapshot(harness);
  });

  test('Repository should build from last partial snapshot', () async {
    // Arrange
    await _testShouldBuildFromLastSnapshot(harness, partial: true);
  });

  test(
    'Repository should save on replay',
    () async {
      // Arrange
      final events = 102;
      final snapshots = events ~/ 20;
      await _repositoryShouldCommitTransactionsOnPush(
        harness,
        withSnapshots: false,
      );
      final repo1 = harness.get<FooRepository>(instance: 1);
      final repo2 = harness.get<FooRepository>(instance: 2);
      expect(repo1.snapshot, isNull);
      expect(repo2.snapshot, isNull);
      repo1.store.snapshots
        ..threshold = 10
        ..automatic = true;
      repo2.store.snapshots
        ..threshold = 10
        ..automatic = true;

      // Act on repo 1
      await repo1.load();
      await repo1.replay();
      await repo1.store.snapshots.onIdle;

      // Assert repo 1
      expect(repo1.snapshot, isNotNull);
      expect(repo1.store.snapshots.length, snapshots); // (total 102 events and page size is 20 => 5 snapshots)
      expect(repo1.store.length, events - repo1.snapshot.number.value + 1);

      // Act on repo 2
      await repo2.load(); // Required since storage instances are not synchronized!
      await repo2.replay();
      await repo2.store.snapshots.onIdle;

      // Assert repo 2
      expect(repo2.snapshot, isNotNull);
      expect(repo2.store.snapshots.length, snapshots); // (total 102 events and page size is 20 => 5 snapshots)
      expect(repo2.store.length, events - repo2.snapshot.number.value + 1);
    },
    // TODO: Fix expectation failure in _repositoryShouldCommitTransactionsOnPush
    retry: 1,
  );

  test('Repository push from last snapshot', () async {
    // Arrange
    await _testShouldBuildFromLastSnapshot(harness);
    final repo = harness.get<FooRepository>();
    final foo1 = repo.aggregates.first;
    final foo2 = repo.aggregates.last;

    // Act
    final event3 = foo1.patch({'property3': 'value3'}, emits: FooUpdated);
    await repo.push(foo1);
    final event4 = foo2.patch({'property3': 'value3'}, emits: FooUpdated);
    await repo.push(foo2);

    // Assert
    expect(repo.snapshot, isNotNull, reason: 'Should have a snapshot');
    expect(repo.number, repo.store.current(), reason: 'Should be equal');
    expect(repo.store.current(), equals(EventNumber(3)), reason: 'Should cumulate to (offset + events.length - 1)');
    expect(event3.number, repo.store.current(uuid: foo1.uuid), reason: 'Should be equal');
    expect(event4.number, repo.store.current(uuid: foo2.uuid), reason: 'Should be equal');

    expect(foo1.number, equals(event3.number));
    expect(foo2.number, equals(event4.number));
  });

  test('Repository should save snapshot manually', () async {
    // Arrange
    final repo = harness.get<FooRepository>();
    await repo.readyAsync();
    repo.store.snapshots
      ..threshold = null
      ..automatic = false;
    expect(repo.snapshot, isNull, reason: 'Should have NO snapshot');

    // Act
    final uuid = Uuid().v4();
    final foo = repo.get(uuid, data: {
      'property1': 'value1',
    });
    expect(
      foo.data,
      containsPair('property1', 'value1'),
    );
    await repo.push(foo);
    expect(foo.applied.length, 1);

    // Wait for repo to catching up to head of remote stream
    await takeRemote(repo.store.asStream(), 1, distinct: true);

    // Act
    final snapshot = repo.save();

    // Wait for save to finish
    await repo.store.snapshots.onIdle;

    // Assert snapshot
    expect(repo.snapshot, isNotNull, reason: 'Should have a snapshot');
    expect(repo.snapshot.uuid, equals(snapshot.uuid), reason: 'Should have snapshot ${snapshot.uuid}');
    expect(repo.contains(uuid), isTrue, reason: 'Should contain aggregate root $uuid');

    // Assert aggregate
    final saved = repo.get(uuid);
    expect(saved.applied.length, 1, reason: 'Applied events should be reset on save to snapshot');
    expect(saved.number.value, equals(snapshot.number.value));
    expect(
      saved.data,
      equals(snapshot.aggregates.values.first.data),
    );
    expect(
      saved.applied.last.uuid,
      snapshot.aggregates[saved.uuid].changedBy.uuid,
      reason: 'Applied events should be reset on save to snapshot',
    );
    expect(
      repo.store.length,
      equals(1),
      reason: 'Events before saved snapshot should be removed',
    );
    expect(
      repo.store.containsEvent(saved.changedBy),
      isTrue,
      reason: 'Store should contain applied event',
    );
  });

  test('Repository should not save snapshot', () async {
    // Arrange
    final repo = harness.get<FooRepository>();
    await repo.readyAsync();
    expect(repo.snapshot, isNull, reason: 'Should have NO snapshot');

    // Act
    final uuid = Uuid().v4();
    final foo = repo.get(uuid, data: {
      'property1': 'value1',
    });
    expect(foo.data, containsPair('property1', 'value1'));
    await repo.push(foo);

    // Act
    final snapshot1 = repo.save();
    final snapshot2 = repo.save();

    // Assert
    expect(snapshot1, equals(snapshot2), reason: 'Should not have a new snapshot');
  });

  test('Repository should save snapshot on threshold automatically', () async {
    // Arrange
    final threshold = 10;
    final repo = harness.get<FooRepository>();
    await repo.readyAsync();
    repo.store.snapshots.keep = threshold;
    repo.store.snapshots.threshold = threshold;
    expect(repo.snapshot, isNull, reason: 'Should have NO snapshot');

    // Act
    const count = 100;
    final uuid = Uuid().v4();
    final foo = repo.get(uuid);
    await repo.push(foo);
    for (var i = 1; i <= count; i++) {
      foo.patch({'property1': 'value$i'}, emits: FooUpdated);
      await repo.push(foo);
    }
    final last = repo.get(foo.uuid);
    expect(last.data, containsPair('property1', 'value$count'));
    expect(repo.number.value, equals(count));

    // Wait for all saves to complete
    await repo.store.snapshots.onIdle;

    // Assert
    expect(repo.snapshot, isNotNull, reason: 'Should have snapshot');
    expect(
      repo.snapshot.number.value,
      equals(count),
      reason: 'Event number should be $count',
    );
    final snapshots = count ~/ threshold;
    expect(
      repo.store.snapshots.length,
      equals(snapshots),
      reason: 'Should have $snapshots snapshots',
    );
  }, timeout: Timeout.factor(100));

  test('Repository should delete snapshots automatically', () async {
    // Arrange
    final keep = 5;
    final repo = harness.get<FooRepository>(instance: 1);
    await repo.readyAsync();
    expect(repo.snapshot, isNull, reason: 'Should have NO snapshot');
    repo.store.snapshots.keep = keep;
    repo.store.snapshots.threshold = 10;

    // Disable snapshots for instance 2
    harness.get<FooRepository>(instance: 2).store.snapshots.automatic == false;

    // Act
    const last = 90;
    final uuid = Uuid().v4();
    final foo = repo.get(uuid);
    await repo.push(foo);
    for (var i = 1; i <= last; i++) {
      foo.patch({'property1': 'value$i'}, emits: FooUpdated);
      await repo.push(foo);
    }
    expect(foo.data, containsPair('property1', 'value$last'));
    expect(repo.number.value, equals(last));

    // Wait for all saves to complete
    await repo.store.snapshots.onIdle;

    // Assert
    expect(repo.snapshot, isNotNull, reason: 'Should have snapshot');
    expect(repo.snapshot.number.value, equals(last), reason: 'Event number should be $last');
    expect(repo.store.snapshots.keys.length, equals(keep), reason: 'Should have $keep snapshots');
  });
}

Future _repositoryShouldCommitTransactionsOnPush(
  EventSourceHarness harness, {
  @required bool withSnapshots,
}) async {
  final repo1 = harness.get<FooRepository>(instance: 1)..store.snapshots.automatic = withSnapshots;
  final repo2 = harness.get<FooRepository>(instance: 2)..store.snapshots.automatic = withSnapshots;
  await repo1.readyAsync();
  await repo2.readyAsync();

  final uuid1 = 'foo1';
  await repo1.push(repo1.get(uuid1, data: {'property1': 0}));
  final foo1 = repo1.get(uuid1);

  final uuid2 = 'foo2';
  await repo2.push(repo2.get(uuid2, data: {'property1': 0}));
  final foo2 = repo2.get(uuid2);

  // Catch any events raised
  // before waiting on all
  // events to be seen
  final seen1 = <Event>[];
  final seen2 = <Event>[];
  repo1.store.asStream().where((e) => e.remote).listen((event) {
    seen1.add(event);
  });
  repo2.store.asStream().where((e) => e.remote).listen((event) {
    seen2.add(event);
  });

  // Act on foo1 and foo2 concurrently
  for (var i = 1; i <= 5; i++) {
    final trx1 = repo1.getTransaction(uuid1);
    for (var j = 1; j <= 10; j++) {
      await repo1.execute(
        UpdateFoo({'uuid': uuid1, 'property1': repo1.get(uuid1).elementAt<int>('property1') + 1}),
      );
    }
    await trx1.push();
    final trx2 = repo2.getTransaction(uuid2);
    for (var j = 1; j <= 10; j++) {
      await repo2.execute(
        UpdateFoo({'uuid': uuid2, 'property1': repo2.get(uuid2).elementAt<int>('property1') + 1}),
      );
    }
    await trx2.push();
  }

  // Wait until all events is confirmed remote
  await repo1.store.asStream().where((e) => e.remote).take(101 - seen1.length).toList();
  await repo2.store.asStream().where((e) => e.remote).take(101 - seen2.length).toList();

  // Assert state of foo1
  expect(foo1.isChanged, isFalse);
  expect(foo1.getLocalEvents(), isEmpty);
  expect(foo1.data, containsPair('property1', 50));

  // Assert state of foo2
  expect(foo2.isChanged, isFalse);
  expect(foo2.getLocalEvents(), isEmpty);
  expect(foo2.data, containsPair('property1', 50));

  // Assert state of repo1
  expect(repo1.count(), equals(2));
  expect(repo1.inTransaction(uuid1), isFalse);

  // Assert state of repo2
  expect(repo2.count(), equals(2));
  expect(repo2.inTransaction(uuid2), isFalse);

  // Assert events - counts are dependant on snapshots not being taken
  final stream = harness.server().getStream(typeOf<Foo>().toColonCase());
  expect(stream.instances[0].length, equals(51));
  expect(stream.instances[1].length, equals(51));

  expect(repo1.store.aggregateMap[uuid1].length, equals(51));
  expect(repo1.store.aggregateMap[uuid2].length, equals(51));

  expect(repo2.store.aggregateMap[uuid1].length, equals(51));
  expect(repo2.store.aggregateMap[uuid2].length, equals(51));

  // Assert event numbers
  expect(repo1.store.current().value, equals(101));
  expect(repo1.store.current(uuid: uuid1).value, equals(50));
  expect(repo1.store.current(uuid: uuid2).value, equals(50));
  expect(repo1.store.aggregateMap[uuid1].last.number.value, equals(50));

  expect(repo2.store.current().value, equals(101));
  expect(repo2.store.current(uuid: uuid1).value, equals(50));
  expect(repo2.store.current(uuid: uuid2).value, equals(50));
  expect(repo2.store.aggregateMap[uuid2].last.number.value, equals(50));
}

/// Build from last snapshot.
/// Current event number is 1.
Future _testShouldBuildFromLastSnapshot(
  EventSourceHarness harness, {
  bool partial = false,
}) async {
  // -----------------------------------
  // Arrange repos
  // -----------------------------------
  final repo1 = harness.get<FooRepository>(instance: 1);
  final repo2 = harness.get<FooRepository>(instance: 2);
  await repo1.readyAsync();
  await repo2.readyAsync();
  expect(repo1.snapshot, isNull, reason: 'Should have NO snapshot');
  expect(repo2.snapshot, isNull, reason: 'Should have NO snapshot');

  // Prevent catchup on all repos
  harness.pause();

  // -----------------------------------
  // Arrange stream and storage
  // -----------------------------------
  final stream = harness.server().getStream(repo1.store.aggregate);
  final box = await Hive.lazyBox<StorageState>(repo1.store.snapshots.filename);

  // -----------------------------------
  // Arrange Foo1
  // -----------------------------------
  final fuuid1 = Uuid().v4();
  final data11 = {
    'uuid': fuuid1,
    'parameter11': 'value11',
  };
  final data12 = {
    'uuid': fuuid1,
    'parameter11': 'value11',
    'parameter12': 'value12',
  };
  final event11 = Event(
    uuid: Uuid().v4(),
    data: {
      'patches': JsonPatch.diff({}, data11),
    },
    local: false,
    type: '$FooCreated',
    number: EventNumber(0),
    created: DateTime.now(),
  );
  final event12 = Event(
    uuid: Uuid().v4(),
    data: {
      'patches': JsonPatch.diff(data11, data12),
    },
    local: false,
    type: '$FooUpdated',
    number: EventNumber(1),
    created: DateTime.now(),
  );
  stream.append(
    '${stream.instanceStream}-0',
    [
      TestStream.asSourceEvent<FooCreated>(
        fuuid1,
        {},
        data11,
        eventId: event11.uuid,
        number: EventNumber(0),
      ),
      if (partial)
        TestStream.asSourceEvent<FooUpdated>(
          fuuid1,
          data11,
          data12,
          eventId: event12.uuid,
          number: EventNumber(1),
        ),
    ],
  );

  // -----------------------------------
  // Arrange Foo2
  // -----------------------------------
  final fuuid2 = Uuid().v4();
  final data21 = {
    'uuid': fuuid2,
    'parameter21': 'value21',
  };
  final data22 = {
    'uuid': fuuid2,
    'parameter21': 'value21',
    'parameter22': 'value22',
  };
  final event21 = Event(
    uuid: Uuid().v4(),
    data: {
      'patches': JsonPatch.diff({}, data21),
    },
    local: false,
    type: '$FooCreated',
    number: EventNumber(0),
    created: DateTime.now(),
  );
  final event22 = Event(
    uuid: Uuid().v4(),
    data: {
      'patches': JsonPatch.diff(data21, data22),
    },
    local: false,
    type: '$FooUpdated',
    number: EventNumber(1),
    created: DateTime.now(),
  );
  stream.append(
    '${stream.instanceStream}-1',
    [
      TestStream.asSourceEvent<FooCreated>(
        fuuid2,
        {},
        data21,
        eventId: event21.uuid,
        number: EventNumber(0),
      ),
      if (partial)
        TestStream.asSourceEvent<FooUpdated>(
          fuuid2,
          data21,
          data22,
          eventId: event22.uuid,
          number: EventNumber(1),
        ),
    ],
  );

  // -----------------------------------
  // Create snapshot
  // -----------------------------------
  final timestamp = DateTime.now();
  final suuid1 = Uuid().v4();
  final snapshot1 = SnapshotModel(
    uuid: suuid1,
    timestamp: timestamp,
    type: '${repo1.aggregateType}',
    number: EventNumberModel.from(EventNumber.none),
  );
  await box.put(
    suuid1,
    StorageState(value: snapshot1),
  );
  final suuid2 = Uuid().v4();
  final snapshot2 = SnapshotModel(
    uuid: suuid2,
    timestamp: timestamp,
    type: '${repo2.aggregateType}',
    // Partial snapshot where
    // aggregates are not up
    // to date. This indicates
    // that an error has occurred
    // that should be recovered
    // on catchup or replay
    //
    number: EventNumberModel(value: partial ? 3 : 1),
    aggregates: LinkedHashMap.from({
      fuuid1: AggregateRootModel(
        uuid: fuuid1,
        createdBy: event11,
        changedBy: event11,
        data: data11,
        number: EventNumberModel.from(event11.number),
      ),
      fuuid2: AggregateRootModel(
        uuid: fuuid2,
        createdBy: event21,
        changedBy: event21,
        data: data21,
        number: EventNumberModel.from(event21.number),
      ),
    }),
  );
  await box.put(
    suuid2,
    StorageState(value: snapshot2),
  );
  await repo1.store.snapshots.load();
  await repo2.store.snapshots.load();

  // -----------------------------------
  // Act in repo1
  // -----------------------------------
  final count1 = await repo1.replay();

  // Resume catchup
  repo1.store.resume();

  // Wait for deletes to complete
  await repo1.store.snapshots.onIdle;

  // -----------------------------------
  // Assert repo1
  // -----------------------------------
  expect(count1, equals(partial ? 2 : 0), reason: 'Should replay ${partial ? 2 : 0} events');
  expect(repo1.snapshot, isNotNull, reason: 'Should have a snapshot');
  expect(repo1.snapshot.uuid, equals(suuid2), reason: 'Should have snapshot $suuid2');
  expect(repo1.number, repo1.store.current(), reason: 'Should be equal');
  expect(
    repo1.store.current(),
    equals(EventNumber(partial ? 3 : 1)),
    reason: 'Should cumulate to (events.length - 1)',
  );
  final n11 = (partial ? event12 : event11).number;
  final n12 = (partial ? event22 : event21).number;
  expect(repo1.store.current(uuid: fuuid1), equals(n11), reason: 'Should be equal');
  expect(repo1.store.current(uuid: fuuid2), equals(n12), reason: 'Should be equal');

  expect(repo1.contains(fuuid1), isTrue, reason: 'Should contain aggregate root $fuuid1');
  final foo11 = repo1.get(fuuid1);
  expect(foo11.number, equals(n11));
  expect(foo11.data, equals(partial ? data12 : data11));
  expect(repo1.contains(fuuid2), isTrue, reason: 'Should contain aggregate root $fuuid2');
  final foo12 = repo1.get(fuuid2);
  expect(foo12.number, equals(n12));
  expect(foo12.data, equals(partial ? data22 : data21));

  // -----------------------------------
  // Act on repo2
  // -----------------------------------
  final count2 = await repo2.replay();

  // Resume catchup
  repo2.store.resume();

  // Wait for deletes to complete
  await repo2.store.snapshots.onIdle;

  // -----------------------------------
  // Assert repo2
  // -----------------------------------
  expect(count2, equals(partial ? 2 : 0), reason: 'Should replay ${partial ? 2 : 0} events');
  expect(repo2.snapshot, isNotNull, reason: 'Should have a snapshot');
  expect(repo2.snapshot.uuid, equals(suuid2), reason: 'Should have snapshot $suuid2');
  expect(repo2.number, repo2.store.current(), reason: 'Should be equal');
  expect(
    repo2.store.current(),
    equals(EventNumber(partial ? 3 : 1)),
    reason: 'Should cumulate to (events.length - 1)',
  );
  final n21 = (partial ? event12 : event11).number;
  final n22 = (partial ? event22 : event21).number;
  expect(repo2.store.current(uuid: fuuid1), equals(n21), reason: 'Should be equal');
  expect(repo2.store.current(uuid: fuuid2), equals(n22), reason: 'Should be equal');

  expect(repo2.contains(fuuid1), isTrue, reason: 'Should contain aggregate root $fuuid1');
  final foo21 = repo2.get(fuuid1);
  expect(foo21.number, equals(n21));
  expect(foo21.data, equals(partial ? data12 : data11));
  expect(repo2.contains(fuuid2), isTrue, reason: 'Should contain aggregate root $fuuid2');
  final foo22 = repo2.get(fuuid2);
  expect(foo22.number, equals(n12));
  expect(foo22.data, equals(partial ? data22 : data21));
}

Future<List<Event>> takeLocal(Stream<Event> stream, int count, {bool distinct = true}) {
  final seen = <Event>[];
  return stream
      .where((event) {
        final take = !distinct || !seen.contains(event);
        if (event.local) {
          seen.add(event);
        }
        return event.local && take;
      })
      .take(count)
      .toList();
}

Future<List<Event>> takeRemote(
  Stream<Event> stream,
  int count, {
  @required bool distinct,
}) {
  final seen = <Event>[];
  return stream
      .where((event) {
        final take = !distinct || !seen.contains(event);
        if (event.remote) {
          seen.add(event);
        }
        return event.remote && take;
      })
      .take(count)
      .toList();
}

Future<List<Event>> takeDistinct(
  Stream<Event> stream,
  int count,
) {
  final seen = <Event>[];
  final distinct = <Event>[];
  return stream
      .where((event) {
        final take = !seen.contains(event);
        seen.add(event);
        if (take) {
          distinct.add(event);
        }
        return take;
      })
      .take(count)
      .toList();
}

Future _assertCatchUp(FooRepository repo1, FooRepository repo2, FooRepository repo3, int count) async {
  // Act
  final uuid = Uuid().v4();
  final foo1 = repo1.get(uuid, data: {'property1': 'value1'});

  // Prepare join
  final group = StreamGroup<Event>();
  await group.add(repo2.store.asStream());
  await group.add(repo3.store.asStream());

  // Push to repo 1
  final events = await repo1.push(foo1);
  final domain1 = events.first;

  // Wait for repo 2 and 3 catching up
  await takeRemote(group.stream, 2, distinct: false);
  await group.close();

  // Get actual source events
  final source2 = repo2.store.aggregateMap[uuid].last;
  final source3 = repo3.store.aggregateMap[uuid].last;

  // Get actual aggregates
  final foo2 = repo2.get(uuid);
  final foo3 = repo3.get(uuid);

  // Get actual domain events
  final domain2 = repo2.toDomainEvent(source2);
  final domain3 = repo3.toDomainEvent(source3);

  // Assert catch-up event from repo1
  expect(repo2.count(), equals(count));
  expect(repo3.count(), equals(count));
  expect([source2], containsAll(events));
  expect([source3], containsAll(events));
  expect([domain2], containsAll(events));
  expect([domain3], containsAll(events));

  // Assert change and state information critical for automatic merge resolution
  expect(domain2.mapAt('changed'), equals(domain1.mapAt('changed')));
  expect(domain2.mapAt('previous'), equals(domain1.mapAt('previous')));
  expect(domain2.listAt('patches'), equals(domain1.listAt('patches')));
  expect(domain3.mapAt('changed'), equals(domain1.mapAt('changed')));
  expect(domain3.mapAt('previous'), equals(domain1.mapAt('previous')));
  expect(domain3.listAt('patches'), equals(domain1.listAt('patches')));

  final check = repo1.get(uuid);
  expect(identical(check, foo1), isTrue);

  // Assert even numbers
  expect(domain1.number.value, equals(0));
  expect(source2.number.value, equals(0));
  expect(source2.number.value, equals(0));
  expect(foo1.number.value, equals(0));
  expect(foo2.number.value, equals(0));
  expect(foo3.number.value, equals(0));
  expect(repo1.number.value, equals(count - 1));
  expect(repo2.number.value, equals(count - 1));
  expect(repo3.number.value, equals(count - 1));

  // Assert data
  expect(foo1.data, containsPair('property1', 'value1'));
  expect(foo2.data, containsPair('property1', 'value1'));
  expect(foo3.data, containsPair('property1', 'value1'));
}

Iterable<Event> _assertResultStrictOrder(List<Iterable<Event>> results) {
  var data = <String, dynamic>{};
  final events = <Event>[];
  for (var i = 0; i < 10; i++) {
    expect(
      results[i].length,
      equals(1),
      reason: 'Should contain one event',
    );
    final event = results[i].first;
    events.add(event);
    expect(event, isA<FooCreated>());
    data = JsonUtils.apply(data, event.patches);
    expect(data.elementAt<int>('index'), equals(i));
  }
  return events;
}

Iterable<DomainEvent> _assertMonotonePatch(List<Iterable<DomainEvent>> results) {
  var data = <String, dynamic>{};
  final events = <DomainEvent>[];
  for (var i = 0; i < 10; i++) {
    expect(
      results[i].length,
      equals(1),
      reason: 'Result $i should contain one event',
    );
    final event = results[i].first;
    events.add(event);
    expect(event, isA<FooUpdated>());
    data = JsonUtils.apply(data, event.patches);
    expect(
      data.elementAt('property1'),
      equals(i + 1),
      reason: 'Result ${results[i]} should be an monotone increment',
    );
  }
  return events;
}

Future<List<DomainEvent>> _createMultipleEvents(FooRepository repo, String uuid, int count) async {
  final operations = <DomainEvent>[];
  final foo = repo.get(uuid, data: {'index': 0});
  // Create
  final events = await repo.push(foo);
  operations.addAll(
    events.toList(),
  );
  // Patch
  for (var i = 1; i < count; i++) {
    final events = await repo.push(
      foo..patch({'index': i}, emits: FooUpdated),
    );
    operations.addAll(
      events.toList(),
    );
  }
  return operations;
}

Iterable<DomainEvent> _assertEventNumberStrictOrder(Repository repo, String uuid) {
  final events = repo.get(uuid).applied.toList();
  for (var i = 0; i < events.length; i++) {
    expect(
      events[i].number.value,
      equals(i),
      reason: 'Event number should be $i',
    );
  }
  return events;
}

void _assertUniqueEvents(Repository repo, Iterable<Event> events) {
  final actual = repo.store.aggregateMap.values.fold(
    <String>[],
    (uuids, items) => uuids..addAll(items.map((e) => e.uuid)),
  );
  final expected = events.map((e) => e.uuid).toList();
  expect(expected, equals(actual));
  expect(repo.number.value, equals(events.length - 1));
}

List<Future<Iterable<DomainEvent>>> _createMultipleAggregates(FooRepository repo, int count, {String prefix}) {
  final operations = <Future<Iterable<DomainEvent>>>[];
  for (var i = 0; i < count; i++) {
    final uuid = '${prefix == null ? '' : '$prefix:'}foo:$i:${Uuid().v4()}';
    operations.add(repo.push(repo.get(uuid, data: {'index': i})));
  }
  return operations;
}
