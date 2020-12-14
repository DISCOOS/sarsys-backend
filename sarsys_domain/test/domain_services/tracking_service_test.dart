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
    ..withLogger(debug: false)
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
    expect(repository.count(), equals(0), reason: 'Repository should be empty');
  });

  test('Each tracking instance shall only be owned by one service', () async {
    // Arrange
    final stream = harness.server().getStream('\$et-TrackingCreated');
    final repo = harness.get<TrackingRepository>();
    await repo.readyAsync();
    final devices = harness.get<DeviceRepository>();
    await devices.readyAsync();
    final tuuid1 = _createTracking(repo, stream, subscription);
    final tuuid2 = _createTracking(repo, stream, subscription);
    await expectLater(
        repo.store.asStream(),
        emitsInOrder([
          isA<TrackingCreated>(),
          isA<TrackingCreated>(),
        ]));

    // Act - service 1
    final service1 = TrackingService(repo, devices: devices, consume: 1, snapshot: false);
    final service2 = TrackingService(repo, devices: devices, consume: 1, snapshot: false);
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
            isA<TrackingStatusChanged>() /* none -> ready */,
            isA<TrackingStatusChanged>() /* none -> ready */,
          ]
        ]));

    // Assert - states
    expect(repo.count(), equals(2));
    expect(service1.managed.length, equals(1));
    expect(service2.managed.length, equals(1));
    expect(service1.managed, isNot(equals(service2.managed)));
    expect(repo.get(await tuuid1).data.elementAt('status'), equals('ready'));
    expect(repo.get(await tuuid2).data.elementAt('status'), equals('ready'));

    // Cleanup
    await service1.dispose();
    await service2.dispose();
  });

  test('Tracking services shall attach track on TrackingCreated', () async {
    // Arrange
    final stream = harness.server().getStream('\$et-TrackingCreated');
    final devices = harness.get<DeviceRepository>();
    await devices.readyAsync();
    final repo = harness.get<TrackingRepository>();
    await repo.readyAsync();

    // Act - add source before service has consumed first TrackingCreated event
    final tuuid = await _createTracking(repo, stream, subscription);
    final duuid = await _addTrackingSource(
      repo,
      tuuid,
      await _createDevice(devices),
    );
    final service = TrackingService(repo, devices: devices, consume: 1, snapshot: false)..build();
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
      repo,
      service,
      tuuid: tuuid,
      duuid: duuid,
      attached: true,
      status: 'tracking',
    );

    // Cleanup
    await service.dispose();
  });

  test('Tracking services shall attach track on TrackingSourceAdded', () async {
    // Arrange
    final stream = harness.server().getStream('\$et-TrackingCreated');
    final devices = harness.get<DeviceRepository>();
    await devices.readyAsync();
    final repo = harness.get<TrackingRepository>();
    await repo.readyAsync();

    // Act - add empty tracking object
    final tuuid = await _createTracking(repo, stream, subscription);
    final service = TrackingService(repo, devices: devices, consume: 1, snapshot: false)..build();
    await expectLater(service.asStream(), emits(isA<TrackingCreated>()));

    // Act - create device and add source after service has consumed TrackingCreated
    final duuid = await _createDevice(devices);
    await _addTrackingSource(
      repo,
      tuuid,
      duuid,
    );

    // Assert - events
    await expectLater(
      service.asStream(),
      emitsInOrder([
        isA<TrackingSourceAdded>() /* source -> added */,
        isA<TrackingTrackAdded>() /* track -> added */,
        isA<TrackingStatusChanged>() /* tracking -> paused */,
      ]),
    );

    // Assert - states
    _assertStates(
      repo,
      service,
      tuuid: tuuid,
      duuid: duuid,
      attached: true,
      status: 'tracking',
    );

    // Cleanup
    await service.dispose();
  });

  test('Tracking service aggregates position on DevicePositionChanged when device is trackable', () async {
    // Arrange
    final stream = harness.server().getStream('\$et-TrackingCreated');
    final devices = harness.get<DeviceRepository>();
    await devices.readyAsync();
    final repo = harness.get<TrackingRepository>();
    await repo.readyAsync();

    // Act - add empty tracking object
    final tuuid = await _createTracking(repo, stream, subscription);
    final service = TrackingService(repo, devices: devices, consume: 1, snapshot: false)..build();
    await expectLater(service.asStream(), emits(isA<TrackingCreated>()));

    // Act - add device 1 and update position
    final duuid1 = await _createDevice(devices);
    await _addTrackingSource(
      repo,
      tuuid,
      duuid1,
    );
    await expectLater(
      service.asStream(),
      emitsInOrder([
        isA<TrackingSourceAdded>() /* device 1 source -> added */,
        isA<TrackingTrackAdded>() /* device 1 track -> added */,
        isA<TrackingStatusChanged>() /* status -> tracking   */,
      ]),
    );
    final events = <DomainEvent>[];
    service.asStream().listen((e) => events.add(e));
    await _updateDevicePosition(
      devices,
      duuid1,
      createPosition(lon: 4.0, lat: 8.0, acc: 25.0),
    );
    await expectLater(
      service.asStream(),
      emitsInOrder([
        isA<DevicePositionChanged>() /* position 1 -> changed */,
        isA<TrackingTrackChanged>() /* position 1 -> added   */,
        isA<TrackingPositionChanged>() /* positions aggregated */,
      ]),
    );

    // Act - add device 2 and update position
    final duuid2 = await _createDevice(devices);
    await _addTrackingSource(
      repo,
      tuuid,
      duuid2,
    );
    await expectLater(
      service.asStream(),
      emitsInOrder([
        isA<TrackingSourceAdded>() /* device 1 source -> added */,
        isA<TrackingTrackAdded>() /* device 2 -> added   */,
      ]),
    );
    await _updateDevicePosition(
      devices,
      duuid2,
      createPosition(lon: 6.0, lat: 12.0, acc: 15.0),
    );
    await expectLater(
      service.asStream(),
      emitsInOrder([
        isA<DevicePositionChanged>() /* position 2 -> changed */,
        isA<TrackingTrackChanged>() /*  position 2 -> added   */,
        isA<TrackingPositionChanged>() /* positions aggregated */,
      ]),
    );

    // Assert aggregation
    final tracking = repo.get(tuuid);
    expect(tracking.elementAt('position/geometry/coordinates/0'), 5.0, reason: 'Should aggregate to 5.0');
    expect(tracking.elementAt('position/geometry/coordinates/1'), 10.0, reason: 'Should aggregate to 10.0');
    expect(tracking.elementAt('position/properties/accuracy'), 20.0, reason: 'Should aggregate to 20.0');

    // Cleanup
    await service.dispose();
  });

  test('Tracking service does not aggregates position on DevicePositionChanged when device is not trackable', () async {
    // Arrange
    final stream = harness.server().getStream('\$et-TrackingCreated');
    final devices = harness.get<DeviceRepository>();
    await devices.readyAsync();
    final repo = harness.get<TrackingRepository>();
    await repo.readyAsync();

    // Act - add empty tracking object
    final tuuid = await _createTracking(repo, stream, subscription);
    final service = TrackingService(repo, devices: devices, consume: 1, snapshot: false)..build();
    await expectLater(service.asStream(), emits(isA<TrackingCreated>()));

    // Act - create device, add source and update device position with two positions
    final duuid = await _createDevice(devices, trackable: false);
    _addTrackingSource(
      repo,
      tuuid,
      duuid,
    );
    await expectLater(
      service.asStream(),
      emitsInOrder([
        isA<TrackingSourceAdded>() /* device -> added source   */,
        isA<TrackingTrackAdded>() /* device -> added track  */,
        isA<TrackingStatusChanged>() /* status > tracking  */,
      ]),
    );
    _updateDevicePosition(
      devices,
      duuid,
      createPosition(lat: 3.0, lon: 3.0, acc: 3.0),
    );
    await expectLater(
      service.asStream(),
      emits(isA<DevicePositionChanged>() /* position 1 -> changed */),
    );
    _updateDevicePosition(
      devices,
      duuid,
      createPosition(lat: 6.0, lon: 6.0, acc: 6.0),
    );
    await expectLater(
      service.asStream(),
      emits(isA<DevicePositionChanged>() /* position 2 -> changed */),
    );

    // Assert
    _assertStates(
      repo,
      service,
      duuid: duuid,
      tuuid: tuuid,
      attached: true,
      status: 'tracking',
    );

    // Assert aggregation
    final tracking = repo.get(tuuid);
    expect(tracking.elementAt('position'), isNull, reason: 'Should not aggregate positions');

    // Cleanup
    await service.dispose();
  });

  test('Tracking services shall detach track on TrackingSourceRemoved', () async {
    // Arrange
    final stream = harness.server().getStream('\$et-TrackingCreated');
    final devices = harness.get<DeviceRepository>();
    await devices.readyAsync();
    final repo = harness.get<TrackingRepository>();
    await repo.readyAsync();

    // Act - add empty tracking object
    final tuuid = await _createTracking(repo, stream, subscription);
    final service = TrackingService(repo, devices: devices, consume: 1, snapshot: false)..build();
    await expectLater(
      service.asStream(),
      emitsInOrder([
        isA<TrackingCreated>(),
        isA<TrackingStatusChanged>() /* none -> ready */,
      ]),
    );

    // Act - create device and add source after service has consumed TrackingCreated
    final duuid = await _createDevice(devices);
    _addTrackingSource(
      repo,
      tuuid,
      duuid,
    );
    await expectLater(
      service.asStream(),
      emitsInOrder([
        isA<TrackingSourceAdded>(),
        isA<TrackingTrackAdded>(),
        isA<TrackingStatusChanged>() /*  -> tracking */,
      ]),
    );

    final seen = [];
    service.asStream().listen((event) {
      seen.add(event);
    });

    // Act - remove source after service has consumed TrackingSourceAdded
    await _removeTrackingSource(
      repo,
      tuuid,
      duuid,
    );

    await expectLater(
      service.asStream(),
      emitsInOrder([
        isA<TrackingSourceRemoved>(),
        isA<TrackingTrackChanged>() /* attached -> detached */,
        isA<TrackingStatusChanged>() /* tracking -> ready */,
      ]),
    );

    // Assert - states
    _assertStates(
      repo,
      service,
      tuuid: tuuid,
      duuid: duuid,
      attached: false,
      status: 'ready',
    );

    await service.dispose();
  });

  test('Tracking services should remove tracking on TrackingDeleted', () async {
    // Arrange
    final stream = harness.server().getStream('\$et-TrackingCreated');
    final devices = harness.get<DeviceRepository>();
    await devices.readyAsync();
    final repo = harness.get<TrackingRepository>();
    await repo.readyAsync();

    // Act - add source before service has consumed first TrackingCreated event
    final tuuid = await _createTracking(repo, stream, subscription);
    await _addTrackingSource(
      repo,
      tuuid,
      await _createDevice(devices),
    );
    final service = TrackingService(repo, devices: devices, consume: 1, snapshot: false)..build();
    await expectLater(
      service.asStream(),
      emitsInOrder([
        isA<TrackingCreated>(),
        isA<TrackingTrackAdded>(),
        isA<TrackingStatusChanged>() /* none -> tracking */,
      ]),
    );

    _deleteTracking(repo, stream, subscription, tuuid);
    await expectLater(
      service.asStream(),
      emitsInOrder([
        isA<TrackingDeleted>(),
      ]),
    );

    // Assert - states
    _assertStates(
      repo,
      service,
      trackCount: 0,
      trackingCount: 0,
    );

    // Cleanup
    await service.dispose();
  }, timeout: Timeout.factor(100));
}

void _assertStates(
  TrackingRepository trackingRepo,
  TrackingService service, {
  String duuid,
  String tuuid,
  String status,
  bool attached,
  int trackCount = 1,
  int trackingCount = 1,
}) {
  final tracking = trackingRepo.get(tuuid, createNew: false);
  final tracks = tracking?.asEntityArray('tracks');
  expect(trackingRepo.count(), equals(trackingCount));
  expect(service.managed.length, equals(trackingCount));
  expect(service.managed, trackingCount == 0 ? isEmpty : contains(tuuid));
  if (trackCount == 0) {
    expect(service.sources, isEmpty);
    expect(tracks, isNull);
  } else {
    expect(service.sources.keys, equals({duuid}));
    expect(service.sources[duuid]?.length, equals(1));
    expect(service.sources[duuid], equals({tuuid}));
    expect(tracks.length, equals(trackCount));
  }
  if (status?.isNotEmpty == true) {
    expect(tracks['0']?.data['status'], contains(attached ? 'attached' : 'detached'));
    expect(tracking.elementAt('status'), equals(status));
  }
}

Future<String> _createDevice(DeviceRepository repo, {bool trackable = true}) async {
  final uuid = Uuid().v4();
  await repo.execute(CreateDevice(createDevice(uuid, trackable: trackable)));
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
  await repo.execute(UpdateDevicePosition({'uuid': uuid, 'position': position}));
}

FutureOr<String> _removeTrackingSource(TrackingRepository repo, String tuuid, String suuid) async {
  await repo.execute(RemoveSourceFromTracking(tuuid, createSource(uuid: suuid)));
  return suuid;
}

FutureOr<String> _deleteTracking(TrackingRepository repo, TestStream stream, String subscription, String uuid) async {
  final events = await repo.execute(DeleteTracking(createTracking(uuid)));
  stream.append(subscription, [
    TestStream.fromDomainEvent(events.first),
  ]);
  return uuid;
}
