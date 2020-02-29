import 'dart:async';

import 'package:sarsys_domain/sarsys_domain.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

import '../controllers/harness.dart';
import 'harness.dart';

Future main() async {
  const String subscription = '\$et-TrackingCreated';
  const String group = 'TrackingPositionManager';

  final harness = EventSourceHarness()
    ..withTenant()
    ..withPrefix()
    ..withLogger()
    ..withStream(subscription, useInstanceStreams: false, useCanonicalName: false)
    ..withSubscription(subscription, group: group)
    ..withProjections(projections: ['\$by_category', '\$by_event_type'])
    ..withRepository<Device>((store) => DeviceRepository(store))
    ..withRepository<Tracking>((store) => TrackingRepository(store))
    ..add(port: 4000)
    ..install();

  test('TrackingRepository should build', () async {
    final repository = harness.get<TrackingRepository>();
    final ready = await repository.readyAsync();
    // Assert repository state
    expect(ready, equals(true), reason: 'Repository should be ready');
    expect(repository.count, equals(0), reason: 'Repository should be empty');
  });

  test('Each tracking instance shall only be owned by one manager', () async {
    // Arrange
    final stream = harness.server().getStream('\$et-TrackingCreated');
    final repo = harness.get<TrackingRepository>();
    await repo.readyAsync();

    // Act
    await _createTracking(repo, stream, subscription);
    await _createTracking(repo, stream, subscription);
    final manager1 = TrackingPositionManager(repo, consume: 1)..build();
    final manager2 = TrackingPositionManager(repo, consume: 1)..build();

    // Assert - states
    await expectLater(manager1.asStream(), emits(isA<TrackingCreated>()));
    await expectLater(manager2.asStream(), emits(isA<TrackingCreated>()));
    expect(repo.count, equals(2));
    expect(manager1.managed.length, equals(1));
    expect(manager2.managed.length, equals(1));
    expect(manager1.managed, isNot(equals(manager2.managed)));

    // Cleanup
    manager1.dispose();
    manager2.dispose();
  });

  test('Managers shall attach track on TrackingCreated', () async {
    // Arrange
    final stream = harness.server().getStream('\$et-TrackingCreated');
    final deviceRepo = harness.get<DeviceRepository>();
    await deviceRepo.readyAsync();
    final trackingRepo = harness.get<TrackingRepository>();
    await trackingRepo.readyAsync();
    final manager = TrackingPositionManager(trackingRepo, consume: 1)..build();

    // Act - add source before manager has consumed first TrackingCreated event
    final tracking = await _createTracking(trackingRepo, stream, subscription);
    final device = await _addTrackingSource(
      trackingRepo,
      tracking,
      await _createDevice(deviceRepo),
    );

    // Assert
    await expectLater(
      manager.asStream(),
      emitsInOrder([
        isA<TrackingCreated>(),
        isA<TrackingSourceChanged>(),
      ]),
    );

    // Assert
    expect(trackingRepo.count, equals(1));
    expect(manager.managed.length, equals(1));
    expect(manager.managed, contains(tracking));
    expect(manager.sources.keys, contains(device));
    expect(manager.sources[device]?.length, equals(1));
    expect(manager.sources[device], contains(tracking));

    // Cleanup
    manager.dispose();
  });

  test('Managers shall attach track on TrackingSourceAdded', () async {
    // Arrange
    final stream = harness.server().getStream('\$et-TrackingCreated');
    final deviceRepo = harness.get<DeviceRepository>();
    await deviceRepo.readyAsync();
    final trackingRepo = harness.get<TrackingRepository>();
    await trackingRepo.readyAsync();

    // Act - add empty tracking object
    final tracking = await _createTracking(trackingRepo, stream, subscription);
    final manager = TrackingPositionManager(trackingRepo, consume: 1)..build();
    await expectLater(manager.asStream().first, completion(isA<TrackingCreated>()));

    // Act - create device
    final device = await _createDevice(deviceRepo);

    // Act - add source after manager has consumed TrackingCreated
    _addTrackingSource(
      trackingRepo,
      tracking,
      device,
    );

    // Assert - events
    await expectLater(
      manager.asStream(),
      emitsInOrder([
        isA<TrackingSourceAdded>(),
        isA<TrackingSourceChanged>(),
      ]),
    );

    // Assert - states
    expect(trackingRepo.count, equals(1));
    expect(manager.managed.length, equals(1));
    expect(manager.managed, contains(tracking));
    expect(manager.sources.keys, contains(device));
    expect(manager.sources[device]?.length, equals(1));
    expect(manager.sources[device], contains(tracking));
    expect(
      trackingRepo.get(tracking).asEntityArray('tracks')?.elementAt('1')?.data['status'],
      contains('attached'),
    );

    // Cleanup
    manager.dispose();
  });

  test('Managers shall detach track on TrackingSourceRemoved', () async {
    // Arrange
    final stream = harness.server().getStream('\$et-TrackingCreated');
    final deviceRepo = harness.get<DeviceRepository>();
    await deviceRepo.readyAsync();
    final trackingRepo = harness.get<TrackingRepository>();
    await trackingRepo.readyAsync();

    // Act - add empty tracking object
    final tracking = await _createTracking(trackingRepo, stream, subscription);
    final manager = TrackingPositionManager(trackingRepo, consume: 1)..build();
    await expectLater(manager.asStream().first, completion(isA<TrackingCreated>()));

    // Act - create device
    final device = await _createDevice(deviceRepo);

    // Act - add source after manager has consumed TrackingCreated
    _addTrackingSource(
      trackingRepo,
      tracking,
      device,
    );
    await expectLater(
      manager.asStream(),
      emitsInOrder([
        isA<TrackingSourceAdded>(),
        isA<TrackingSourceChanged>(),
      ]),
    );

    // Act - remove source after manager has consumed TrackingSourceAdded
    _removeTrackingSource(
      trackingRepo,
      tracking,
      '1',
    );
    await expectLater(
      manager.asStream(),
      emitsInOrder([
        isA<TrackingSourceRemoved>(),
      ]),
    );

    // Assert - states
    expect(trackingRepo.count, equals(1));
    expect(manager.managed.length, equals(1));
    expect(manager.managed, contains(tracking));
    expect(manager.sources.keys, contains(device));
    expect(manager.sources[device]?.length, equals(1));
    expect(manager.sources[device], contains(tracking));
    expect(
      trackingRepo.get(tracking).asEntityArray('tracks')?.elementAt('1')?.data['status'],
      contains('attached'),
    );
  });
}

Future<String> _createDevice(DeviceRepository repo) async {
  final uuid = Uuid().v4();
  await repo.execute(CreateDevice(createDevice(uuid)));
  return uuid;
}

FutureOr<String> _createTracking(TrackingRepository repo, TestStream stream, String subscription) async {
  final uuid = Uuid().v4();
  final events = await repo.execute(CreateTracking(createTracking(uuid)));
  stream.append(subscription, [
    TestStream.fromDomainEvent(events.first),
  ]);
  return uuid;
}

FutureOr<String> _addTrackingSource(TrackingRepository repo, String uuid, String device) async {
  await repo.execute(AddSourceToTracking(uuid, createTrack(uuid: device)));
  return device;
}

FutureOr<String> _removeTrackingSource(TrackingRepository repo, String uuid, String id) async {
  await repo.execute(RemoveSourceFromTracking(uuid, createTrack(id: id, uuid: null, type: null)));
  return id;
}
