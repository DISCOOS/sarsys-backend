import 'dart:async';

import 'package:async/async.dart';
import 'package:event_source/event_source.dart';
import 'package:sarsys_domain/sarsys_domain.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

import 'harness.dart';

Future main() async {
  const subscription = '\$et-TrackingCreated';
  const group = 'TrackingService';

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
    _createTracking(repo, stream, subscription);
    _createTracking(repo, stream, subscription);
    await expectLater(
        repo.store.asStream(),
        emitsInOrder([
          isA<TrackingCreated>(),
          isA<TrackingCreated>(),
        ]));

    // Act - manager 1
    final manager1 = TrackingService(repo, consume: 1);
    final manager2 = TrackingService(repo, consume: 1);
    manager1.build();
    manager2.build();

    final group = StreamZip([manager1.asStream(), manager2.asStream()]);

    // Assert - events
    await expectLater(
        group,
        emitsInOrder([
          [
            isA<TrackingCreated>(),
            isA<TrackingCreated>(),
          ],
          [
            isA<TrackingStatusChanged>(),
            isA<TrackingStatusChanged>(),
          ]
        ]));

    // Assert - states0
    expect(repo.count, equals(2));
    expect(manager1.managed.length, equals(1));
    expect(manager2.managed.length, equals(1));
    expect(manager1.managed, isNot(equals(manager2.managed)));

    // Cleanup
    await manager1.dispose();
    await manager2.dispose();
  });

  test('Managers shall attach track on TrackingCreated', () async {
    // Arrange
    final stream = harness.server().getStream('\$et-TrackingCreated');
    final deviceRepo = harness.get<DeviceRepository>();
    await deviceRepo.readyAsync();
    final trackingRepo = harness.get<TrackingRepository>();
    await trackingRepo.readyAsync();
    final manager = TrackingService(trackingRepo, consume: 1);

    // Act - add source before manager has consumed first TrackingCreated event
    final tracking = await _createTracking(trackingRepo, stream, subscription);
    final device = await _addTrackingSource(
      trackingRepo,
      tracking,
      await _createDevice(deviceRepo),
    );
    manager.build();

    // Assert
    await expectLater(
      manager.asStream(),
      emitsInOrder([
        isA<TrackingCreated>(),
        isA<TrackingTrackAdded>(),
        isA<TrackingStatusChanged>(),
      ]),
    );

    // Assert
    expect(trackingRepo.count, equals(1));
    expect(manager.managed.length, equals(1));
    expect(manager.managed, contains(tracking));
    expect(manager.sources.keys, equals({device}));
    expect(manager.sources[device]?.length, equals(1));
    expect(manager.sources[device], equals({tracking}));
    expect(
      trackingRepo.get(tracking).asEntityArray('tracks')?.elementAt('1')?.data['status'],
      contains('attached'),
    );

    // Cleanup
    await manager.dispose();
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
    final manager = TrackingService(trackingRepo, consume: 1);
    await manager.build();
    await expectLater(manager.asStream(), emits(isA<TrackingCreated>()));

    // Act - create device and add source after manager has consumed TrackingCreated
    final device = await _createDevice(deviceRepo);
    _addTrackingSource(
      trackingRepo,
      tracking,
      device,
    );

    // Assert - events
    await expectLater(
      manager.asStream(),
      emitsInOrder([
        isA<TrackingStatusChanged>(),
        isA<TrackingSourceAdded>(),
        isA<TrackingTrackAdded>(),
      ]),
    );

    // Assert - states
    expect(trackingRepo.count, equals(1));
    expect(manager.managed.length, equals(1));
    expect(manager.managed, contains(tracking));
    expect(manager.sources.keys, equals({device}));
    expect(manager.sources[device]?.length, equals(1));
    expect(manager.sources[device], equals({tracking}));
    expect(
      trackingRepo.get(tracking).asEntityArray('tracks')?.elementAt('1')?.data['status'],
      contains('attached'),
    );

    // Cleanup
    await manager.dispose();
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
    final manager = TrackingService(trackingRepo, consume: 1);
    await manager.build();
    await expectLater(manager.asStream(), emits(isA<TrackingCreated>()));

    // Act - create device and add source after manager has consumed TrackingCreated
    final device = await _createDevice(deviceRepo);
    _addTrackingSource(
      trackingRepo,
      tracking,
      device,
    );
    await expectLater(
      manager.asStream(),
      emitsInOrder([
        isA<TrackingStatusChanged>(),
        isA<TrackingSourceAdded>(),
        isA<TrackingTrackAdded>(),
      ]),
    );

    // Act - remove source after manager has consumed TrackingSourceAdded
    _removeTrackingSource(
      trackingRepo,
      tracking,
      device,
    );
    await expectLater(
      manager.asStream(),
      emitsInOrder([
        isA<TrackingTrackChanged>(),
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
      contains('detached'),
    );

    await manager.dispose();
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
  await repo.execute(AddSourceToTracking(uuid, createSource(uuid: device)));
  return device;
}

FutureOr<String> _removeTrackingSource(TrackingRepository repo, String tuuid, String suuid) async {
  await repo.execute(RemoveSourceFromTracking(tuuid, createSource(uuid: suuid)));
  return suuid;
}
