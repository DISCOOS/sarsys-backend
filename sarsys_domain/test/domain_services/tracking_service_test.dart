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

  test('Each tracking instance shall only be owned by one service', () async {
    // Arrange
    final stream = harness.server().getStream('\$et-TrackingCreated');
    final repo = harness.get<TrackingRepository>();
    await repo.readyAsync();
    final tuuid1 = _createTracking(repo, stream, subscription);
    final tuuid2 = _createTracking(repo, stream, subscription);
    await expectLater(
        repo.store.asStream(),
        emitsInOrder([
          isA<TrackingCreated>(),
          isA<TrackingCreated>(),
        ]));

    // Act - service 1
    final service1 = TrackingService(repo, consume: 1, snapshot: false);
    final service2 = TrackingService(repo, consume: 1, snapshot: false);
    service1.build();
    service2.build();

    final group = StreamZip([service1.asStream(), service2.asStream()]);

    // Assert - events
    await expectLater(
        group,
        emitsInOrder([
          [
            isA<TrackingCreated>(),
            isA<TrackingCreated>(),
          ],
          [
            isA<TrackingStatusChanged>() /* none -> created */,
            isA<TrackingStatusChanged>() /* none -> created */,
          ]
        ]));

    // Assert - states
    expect(repo.count, equals(2));
    expect(service1.managed.length, equals(1));
    expect(service2.managed.length, equals(1));
    expect(service1.managed, isNot(equals(service2.managed)));
    expect(repo.get(await tuuid1).data.elementAt('status'), equals('paused'));
    expect(repo.get(await tuuid2).data.elementAt('status'), equals('paused'));

    // Cleanup
    await service1.dispose();
    await service2.dispose();
  });

  test('Tracking services shall attach track on TrackingCreated', () async {
    // Arrange
    final stream = harness.server().getStream('\$et-TrackingCreated');
    final deviceRepo = harness.get<DeviceRepository>();
    await deviceRepo.readyAsync();
    final trackingRepo = harness.get<TrackingRepository>();
    await trackingRepo.readyAsync();

    // Act - add source before service has consumed first TrackingCreated event
    final tuuid = await _createTracking(trackingRepo, stream, subscription);
    final duuid = await _addTrackingSource(
      trackingRepo,
      tuuid,
      await _createDevice(deviceRepo),
    );
    final service = TrackingService(trackingRepo, consume: 1, snapshot: false)..build();
    await expectLater(
      service.asStream(),
      emitsInOrder([
        isA<TrackingCreated>(),
        isA<TrackingTrackAdded>(),
        isA<TrackingStatusChanged>() /* none -> tracking */,
      ]),
    );

    // Assert - states
    _assertStates(
      trackingRepo,
      service,
      tuuid,
      duuid,
      'tracking',
      true,
    );

    // Cleanup
    await service.dispose();
  });

  test('Tracking services shall attach track on TrackingSourceAdded', () async {
    // Arrange
    final stream = harness.server().getStream('\$et-TrackingCreated');
    final deviceRepo = harness.get<DeviceRepository>();
    await deviceRepo.readyAsync();
    final trackingRepo = harness.get<TrackingRepository>();
    await trackingRepo.readyAsync();

    // Act - add empty tracking object
    final tuuid = await _createTracking(trackingRepo, stream, subscription);
    final service = TrackingService(trackingRepo, consume: 1, snapshot: false)..build();
    await expectLater(service.asStream(), emits(isA<TrackingCreated>()));

    // Act - create device and add source after service has consumed TrackingCreated
    final duuid = await _createDevice(deviceRepo);
    _addTrackingSource(
      trackingRepo,
      tuuid,
      duuid,
    );

    // Assert - events
    await expectLater(
      service.asStream(),
      emitsInOrder([
        isA<TrackingSourceAdded>(),
        isA<TrackingTrackAdded>(),
        isA<TrackingStatusChanged>() /* tracking -> paused */,
      ]),
    );

    // Assert - states
    _assertStates(
      trackingRepo,
      service,
      tuuid,
      duuid,
      'tracking',
      true,
    );

    // Cleanup
    await service.dispose();
  });

  test('Tracking service aggregates position on DevicePositionChanged', () async {
    // Arrange
    final stream = harness.server().getStream('\$et-TrackingCreated');
    final deviceRepo = harness.get<DeviceRepository>();
    await deviceRepo.readyAsync();
    final trackingRepo = harness.get<TrackingRepository>();
    await trackingRepo.readyAsync();

    // Act - add empty tracking object
    final tuuid = await _createTracking(trackingRepo, stream, subscription);
    final service = TrackingService(trackingRepo, consume: 1, snapshot: false)..build();
    await expectLater(service.asStream(), emits(isA<TrackingCreated>()));

    // Act - create device, add source and update device position with two positions
    final duuid = await _createDevice(deviceRepo);
    await _addTrackingSource(
      trackingRepo,
      tuuid,
      duuid,
    );
    await _updateDevicePosition(
      deviceRepo,
      duuid,
      createPosition(),
    );
    await _updateDevicePosition(
      deviceRepo,
      duuid,
      createPosition(lat: 3.0, lon: 3.0, acc: 3.0),
    );

    // Assert
    await expectLater(
      service.asStream(),
      emitsInOrder([
        isA<DevicePositionChanged>() /* position 1 -> changed */,
        isA<TrackingTrackChanged>() /*  position 1 -> added   */,
        isA<DevicePositionChanged>() /* position 2 -> changed */,
        isA<TrackingTrackChanged>() /*  position 2 -> added   */,
        isA<TrackingInformationUpdated>() /* positions aggregated */,
      ]),
    );

    _assertStates(
      trackingRepo,
      service,
      tuuid,
      duuid,
      'tracking',
      true,
    );

    // Cleanup
    await service.dispose();
  });

  test('Tracking services shall detach track on TrackingSourceRemoved', () async {
    // Arrange
    final stream = harness.server().getStream('\$et-TrackingCreated');
    final deviceRepo = harness.get<DeviceRepository>();
    await deviceRepo.readyAsync();
    final trackingRepo = harness.get<TrackingRepository>();
    await trackingRepo.readyAsync();

    // Act - add empty tracking object
    final tuuid = await _createTracking(trackingRepo, stream, subscription);
    final service = TrackingService(trackingRepo, consume: 1, snapshot: false)..build();
    await expectLater(
      service.asStream(),
      emitsInOrder([
        isA<TrackingCreated>(),
        isA<TrackingStatusChanged>() /* none -> created */,
      ]),
    );

    // Act - create device and add source after service has consumed TrackingCreated
    final duuid = await _createDevice(deviceRepo);
    _addTrackingSource(
      trackingRepo,
      tuuid,
      duuid,
    );
    await expectLater(
      service.asStream(),
      emitsInOrder([
        isA<TrackingSourceAdded>(),
        isA<TrackingTrackAdded>(),
        isA<TrackingStatusChanged>() /* paused -> tracking */,
      ]),
    );

    // Act - remove source after service has consumed TrackingSourceAdded
    _removeTrackingSource(
      trackingRepo,
      tuuid,
      duuid,
    );
    await expectLater(
      service.asStream(),
      emitsInOrder([
        isA<TrackingSourceRemoved>(),
        isA<TrackingTrackChanged>() /* attached -> detached */,
        isA<TrackingStatusChanged>() /* tracking -> paused */,
      ]),
    );

    // Assert - states
    _assertStates(
      trackingRepo,
      service,
      tuuid,
      duuid,
      'paused',
      false,
    );

    await service.dispose();
  });
}

void _assertStates(
  TrackingRepository trackingRepo,
  TrackingService service,
  String tuuid,
  String duuid,
  String status,
  bool attached, {
  int trackCount = 1,
  int trackingCount = 1,
}) {
  final tracking = trackingRepo.get(tuuid);
  final tracks = tracking.asEntityArray('tracks');
  expect(trackingRepo.count, equals(trackingCount));
  expect(service.managed.length, equals(trackingCount));
  expect(service.managed, contains(tuuid));
  expect(service.sources.keys, equals({duuid}));
  expect(service.sources[duuid]?.length, equals(1));
  expect(service.sources[duuid], equals({tuuid}));
  expect(tracks.length, equals(trackCount));
  expect(tracks['1']?.data['status'], contains(attached ? 'attached' : 'detached'));
  expect(tracking.data.elementAt('status'), equals(status));
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

FutureOr _updateDevicePosition(DeviceRepository repo, String uuid, Map<String, dynamic> position) async {
  await repo.execute(UpdateDevicePosition(createDevice(uuid, position: position)));
}

FutureOr<String> _removeTrackingSource(TrackingRepository repo, String tuuid, String suuid) async {
  await repo.execute(RemoveSourceFromTracking(tuuid, createSource(uuid: suuid)));
  return suuid;
}
