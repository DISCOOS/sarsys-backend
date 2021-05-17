import 'dart:convert';

import 'package:sarsys_app_server/sarsys_app_server.dart';
import 'package:uuid/uuid.dart';
import 'package:test/test.dart';
import 'package:pedantic/pedantic.dart';
import 'package:collection_x/collection_x.dart';

import 'package:sarsys_app_server_test/sarsys_app_server_test.dart';

Future main() async {
  final harness = SarSysAppHarness()
    ..withEventStoreMock()
    ..install(restartForEachTest: true);

  const String appId = 'a123';
  const String accessToken = 'xyz';

  test("Should subscribe to events", () async {
    // Arrange
    final messages = [];
    final uuid = Uuid().v4();
    final channel = harness.getWebSocketChannel(appId);
    final stream = channel.stream.asBroadcastStream();
    final sub = stream.listen(messages.add);
    final data = {
      'maxCount': 50,
      'minPeriod': 1,
      'types': [
        {
          'name': 'Device',
          'events': [
            {'name': 'DevicePositionChanged'}
          ],
        }
      ],
    };

    // Act
    channel.sink.add(
      json.encode({
        'uuid': uuid,
        'data': data,
        'type': 'Subscribe',
      }),
    );
    final events = await stream.take(1).toList();

    // Assert
    expect(events.isNotEmpty, isTrue);
    expect(messages.isNotEmpty, isTrue);
    expect(messages.first, events.first);
    final message = json.decode(messages.first as String) as Map<String, dynamic>;
    expect(message.elementAt('uuid'), uuid);
    expect(message.elementAt('type'), 'Status');
    expect(message.elementAt('created'), isNotEmpty);
    expect(message.elementAt('number'), EventNumber.none.value);

    // Cleanup
    await sub.cancel();
  });

  test("Should not subscribe to unsupported events", () async {
    // Arrange
    final messages = [];
    final uuid = Uuid().v4();
    final channel = harness.getWebSocketChannel(appId);
    final stream = channel.stream.asBroadcastStream();
    final sub = stream.listen(messages.add);
    final subscribeTo = [
      {
        'name': 'UnsupportedEventName',
        'statePatches': false,
        'changedState': false,
        'previousState': false,
      }
    ];
    final data = {
      'maxCount': 50,
      'minPeriod': 1,
      'types': [
        {
          'name': 'Device',
          'events': subscribeTo,
        }
      ],
    };

    // Act
    channel.sink.add(
      json.encode({
        'uuid': uuid,
        'data': data,
        'type': 'Subscribe',
      }),
    );
    final events = await stream.take(1).toList();

    // Assert
    expect(events.isNotEmpty, isTrue);
    expect(messages.isNotEmpty, isTrue);
    expect(messages.first, events.first);
    final message = json.decode(messages.first as String) as Map<String, dynamic>;
    expect(message.elementAt('uuid'), uuid);
    expect(message.elementAt('type'), 'Error');
    expect(message.elementAt('created'), isNotEmpty);
    expect(message.elementAt('number'), EventNumber.none.value);
    expect(message.elementAt('data/code'), HttpStatus.notFound);
    expect(message.elementAt('data/events'), subscribeTo);
    expect(message.elementAt('data/reason'), 'Unsupported event types');

    // Cleanup
    await sub.cancel();
  });

  test("Should receive events with patches only", () async {
    // Arrange
    final messages = [];
    final uuid = Uuid().v4();
    final channel = harness.getWebSocketChannel(appId);
    final stream = channel.stream.asBroadcastStream();
    final sub = stream.listen(messages.add);
    final subscribeTo = [
      {
        'name': 'DeviceCreated',
        'statePatches': true,
        'changedState': false,
        'previousState': false,
      }
    ];
    final data = {
      'maxCount': 50,
      'minPeriod': 1,
      'types': [
        {
          'name': 'Device',
          'events': subscribeTo,
        }
      ],
    };
    // Act
    channel.sink.add(
      json.encode({
        'uuid': uuid,
        'data': data,
        'type': 'Subscribe',
      }),
    );
    await stream.take(1).toList();

    final duuid = Uuid().v4();
    final device = createDevice(duuid);
    unawaited(harness.agent.post("/api/devices", body: device));
    final changes = await stream.take(1).toList();

    // Assert
    final message = json.decode(changes.first as String) as Map<String, dynamic>;
    expect(message.elementAt('uuid'), isNotNull);
    expect(message.elementAt('type'), 'Changes');
    expect(message.elementAt('pending'), 0);
    expect(message.elementAt('created'), isNotEmpty);
    expect(message.elementAt('number'), EventNumber.none.value);
    expect(message.elementAt('entries/0/type'), 'Device');
    expect(message.elementAt('entries/0/event'), isA<Map>());
    expect(message.elementAt('entries/0/event/uuid'), isNotNull);
    expect(message.elementAt('entries/0/event/type'), 'DeviceCreated');
    expect(message.elementAt('entries/0/event/data'), isA<Map>());
    final patches = message.listAt<Map<String, dynamic>>('entries/0/event/data/patches');
    final remote = JsonPatch.apply(<String, dynamic>{}, patches) as Map<String, dynamic>;
    expect(remote..addAll({'uuid': duuid}), device);
    expect(message.elementAt('entries/0/event/data/changed'), isNull);
    expect(message.elementAt('entries/0/event/data/previous'), isNull);

    // Cleanup
    await sub.cancel();
  });

  test("Should receive events with changed state only", () async {
    // Arrange
    final messages = [];
    final uuid = Uuid().v4();
    final channel = harness.getWebSocketChannel(appId);
    final stream = channel.stream.asBroadcastStream();
    final sub = stream.listen(messages.add);
    final subscribeTo = [
      {
        'name': 'DeviceCreated',
        'statePatches': false,
        'changedState': true,
        'previousState': false,
      }
    ];
    final data = {
      'maxCount': 50,
      'minPeriod': 1,
      'types': [
        {
          'name': 'Device',
          'events': subscribeTo,
        }
      ],
    };
    // Act
    channel.sink.add(
      json.encode({
        'uuid': uuid,
        'data': data,
        'type': 'Subscribe',
      }),
    );
    await stream.take(1).toList();

    final duuid = Uuid().v4();
    final device = createDevice(duuid);
    unawaited(harness.agent.post("/api/devices", body: device));
    final changes = await stream.take(1).toList();

    // Assert
    final message = json.decode(changes.first as String) as Map<String, dynamic>;
    expect(message.elementAt('uuid'), isNotNull);
    expect(message.elementAt('type'), 'Changes');
    expect(message.elementAt('pending'), 0);
    expect(message.elementAt('created'), isNotEmpty);
    expect(message.elementAt('number'), EventNumber.none.value);
    expect(message.elementAt('entries/0/type'), 'Device');
    expect(message.elementAt('entries/0/event'), isA<Map>());
    expect(message.elementAt('entries/0/event/uuid'), isNotNull);
    expect(message.elementAt('entries/0/event/type'), 'DeviceCreated');
    expect(message.elementAt('entries/0/event/data'), isA<Map>());
    expect(message.elementAt('entries/0/event/data/changed'), device);
    expect(message.elementAt('entries/0/event/data/patches'), isNull);
    expect(message.elementAt('entries/0/event/data/previous'), isNull);

    // Cleanup
    await sub.cancel();
  });

  test("Should receive events with previous state only", () async {
    // Arrange
    final messages = [];
    final uuid = Uuid().v4();
    final channel = harness.getWebSocketChannel(appId);
    final stream = channel.stream.asBroadcastStream();
    final sub = stream.listen(messages.add);
    final subscribeTo = [
      {
        'name': 'DeviceCreated',
        'statePatches': false,
        'changedState': false,
        'previousState': true,
      }
    ];
    final data = {
      'maxCount': 50,
      'minPeriod': 1,
      'types': [
        {
          'name': 'Device',
          'events': subscribeTo,
        }
      ],
    };
    // Act
    channel.sink.add(
      json.encode({
        'uuid': uuid,
        'data': data,
        'type': 'Subscribe',
      }),
    );
    await stream.take(1).toList();

    final duuid = Uuid().v4();
    final device = createDevice(duuid);
    unawaited(harness.agent.post("/api/devices", body: device));
    final changes = await stream.take(1).toList();

    // Assert
    final message = json.decode(changes.first as String) as Map<String, dynamic>;
    expect(message.elementAt('uuid'), isNotNull);
    expect(message.elementAt('type'), 'Changes');
    expect(message.elementAt('pending'), 0);
    expect(message.elementAt('created'), isNotEmpty);
    expect(message.elementAt('number'), EventNumber.none.value);
    expect(message.elementAt('entries/0/type'), 'Device');
    expect(message.elementAt('entries/0/event'), isA<Map>());
    expect(message.elementAt('entries/0/event/uuid'), isNotNull);
    expect(message.elementAt('entries/0/event/type'), 'DeviceCreated');
    expect(message.elementAt('entries/0/event/data'), isA<Map>());
    expect(message.elementAt('entries/0/event/data/previous'), {});
    expect(message.elementAt('entries/0/event/data/changed'), isNull);
    expect(message.elementAt('entries/0/event/data/patches'), isNull);

    // Cleanup
    await sub.cancel();
  });

  test("Should receive all events for given type", () async {
    // Arrange
    final messages = [];
    final uuid = Uuid().v4();
    final channel = harness.getWebSocketChannel(appId);
    final stream = channel.stream.asBroadcastStream();
    final sub = stream.listen(messages.add);
    final data = {
      'maxCount': 50,
      'minPeriod': 1,
      'types': [
        {'name': 'Device'}
      ],
    };
    // Act
    channel.sink.add(
      json.encode({
        'uuid': uuid,
        'data': data,
        'type': 'Subscribe',
      }),
    );
    await stream.take(1).toList();

    final duuid = Uuid().v4();
    final device = createDevice(duuid);
    final created = harness.agent.post("/api/devices", body: device);
    final changed = Map.from(device)..addAll({'alias': 'test123'});
    unawaited(created.then(
      (value) {
        unawaited(harness.agent.execute("PATCH", "/api/devices/$duuid", body: changed));
      },
    ));
    final changes = await stream.take(2).toList();

    // Assert
    final message1 = json.decode(changes.first as String) as Map<String, dynamic>;
    expect(message1.elementAt('uuid'), isNotNull);
    expect(message1.elementAt('type'), 'Changes');
    expect(message1.elementAt('count'), 1);
    expect(message1.elementAt('pending'), 0);
    expect(message1.elementAt('created'), isNotEmpty);
    expect(message1.elementAt('number'), EventNumber.none.value);
    expect(message1.elementAt('entries/0/type'), 'Device');
    expect(message1.elementAt('entries/0/event'), isA<Map>());
    expect(message1.elementAt('entries/0/event/uuid'), isNotNull);
    expect(message1.elementAt('entries/0/event/type'), 'DeviceCreated');
    expect(message1.elementAt('entries/0/event/data'), isA<Map>());
    expect(message1.elementAt('entries/0/event/data/previous'), isNull);
    expect(message1.elementAt('entries/0/event/data/changed'), isNull);
    expect(message1.elementAt('entries/0/event/data/patches'), isNull);

    final message2 = json.decode(changes.last as String) as Map<String, dynamic>;
    expect(message2.elementAt('uuid'), isNotNull);
    expect(message2.elementAt('type'), 'Changes');
    expect(message2.elementAt('count'), 1);
    expect(message2.elementAt('pending'), 0);
    expect(message2.elementAt('created'), isNotEmpty);
    expect(message2.elementAt('number'), EventNumber.none.value);
    expect(message2.elementAt('entries/0/type'), 'Device');
    expect(message2.elementAt('entries/0/event'), isA<Map>());
    expect(message2.elementAt('entries/0/event/uuid'), isNotNull);
    expect(message2.elementAt('entries/0/event/type'), 'DeviceInformationUpdated');
    expect(message2.elementAt('entries/0/event/data'), isA<Map>());
    expect(message2.elementAt('entries/0/event/data/previous'), isNull);
    expect(message2.elementAt('entries/0/event/data/changed'), isNull);
    expect(message2.elementAt('entries/0/event/data/patches'), isNull);

    // Cleanup
    await sub.cancel();
  });

  test("Should receive events matching single filter", () async {
    // Arrange
    final messages = [];
    final uuid = Uuid().v4();
    final duuid1 = Uuid().v4();
    final duuid2 = Uuid().v4();
    final channel = harness.getWebSocketChannel(appId);
    final stream = channel.stream.asBroadcastStream();
    final sub = stream.listen(messages.add);
    final data = {
      'maxCount': 50,
      'minPeriod': 1,
      'types': [
        {
          'name': 'Device',
          'filters': [
            {'pattern': "\$.data[?(@.uuid=='$duuid2')]"}
          ],
        }
      ],
    };
    // Act
    channel.sink.add(
      json.encode({
        'uuid': uuid,
        'data': data,
        'type': 'Subscribe',
      }),
    );
    await stream.take(1).toList();

    final responses = <Future>[];
    final device1 = createDevice(duuid1);
    responses.add(harness.agent.post("/api/devices", body: device1));
    final device2 = createDevice(duuid2);
    responses.add(harness.agent.post("/api/devices", body: device2));
    final changes = await stream.take(1).toList();
    await Future.wait(responses);

    // Assert
    final message = json.decode(changes.first as String) as Map<String, dynamic>;
    expect(message.elementAt('uuid'), isNotNull);
    expect(message.elementAt('type'), 'Changes');
    expect(message.elementAt('pending'), 0);
    expect(message.elementAt('created'), isNotEmpty);
    expect(message.elementAt('number'), EventNumber.none.value);
    expect(message.elementAt('entries/0/type'), 'Device');
    expect(message.elementAt('entries/0/event'), isA<Map>());
    expect(message.elementAt('entries/0/event/uuid'), isNotNull);
    expect(message.elementAt('entries/0/event/type'), 'DeviceCreated');
    expect(message.elementAt('entries/0/event/data'), isA<Map>());
    expect(message.elementAt('entries/0/event/data/uuid'), duuid2);
    expect(message.elementAt('entries/0/event/data/changed'), isNull);
    expect(message.elementAt('entries/0/event/data/patches'), isNull);
    expect(message.elementAt('entries/0/event/data/previous'), isNull);

    // Cleanup
    await sub.cancel();
  });

  test("Should receive events matching multiple OR-ed filters", () async {
    // Arrange
    final messages = [];
    final uuid = Uuid().v4();
    const duuid1 = 'duuid1';
    const duuid2 = 'duuid2';
    const duuid3 = 'duuid3';
    const duuid4 = 'duuid4';
    final channel = harness.getWebSocketChannel(appId);
    final stream = channel.stream.asBroadcastStream();
    final sub = stream.listen(messages.add);
    final data = {
      'maxCount': 50,
      'minPeriod': 1,
      'types': [
        {
          'name': 'Device',
          'match': 'any',
          'filters': [
            {'pattern': "\$.data[?(@.uuid=='$duuid2')]"},
            {'pattern': "\$.data[?(@.uuid=='$duuid4')]"}
          ],
        }
      ],
    };
    // Act
    channel.sink.add(
      json.encode({
        'uuid': uuid,
        'data': data,
        'type': 'Subscribe',
      }),
    );
    await stream.take(1).toList();

    final responses = <Future>[];
    final device1 = createDevice(duuid1);
    responses.add(harness.agent.post("/api/devices", body: device1));
    final device2 = createDevice(duuid2);
    responses.add(harness.agent.post("/api/devices", body: device2));
    final device3 = createDevice(duuid3);
    responses.add(harness.agent.post("/api/devices", body: device3));
    final device4 = createDevice(duuid4);
    responses.add(harness.agent.post("/api/devices", body: device4));
    final changes = await stream.take(2).toList();

    // Wait for all commands to complete
    await Future.wait(responses);

    // Sort responses since order of events between aggregates is random
    final message1 = json.decode(changes.first as String) as Map<String, dynamic>;
    final message2 = json.decode(changes.last as String) as Map<String, dynamic>;
    final map = sortMapKeys({
      message1.elementAt('entries/0/event/data/uuid'): message1,
      message2.elementAt('entries/0/event/data/uuid'): message2,
    });

    // Assert device 2
    final change1 = map.values.first;
    expect(change1.elementAt('uuid'), isNotNull);
    expect(change1.elementAt('type'), 'Changes');
    expect(change1.elementAt('pending'), 0);
    expect(change1.elementAt('created'), isNotEmpty);
    expect(change1.elementAt('number'), EventNumber.none.value);
    expect(change1.elementAt('entries/0/type'), 'Device');
    expect(change1.elementAt('entries/0/event'), isA<Map>());
    expect(change1.elementAt('entries/0/event/uuid'), isNotNull);
    expect(change1.elementAt('entries/0/event/type'), 'DeviceCreated');
    expect(change1.elementAt('entries/0/event/data'), isA<Map>());
    expect(change1.elementAt('entries/0/event/data/uuid'), duuid2);
    expect(change1.elementAt('entries/0/event/data/changed'), isNull);
    expect(change1.elementAt('entries/0/event/data/patches'), isNull);
    expect(change1.elementAt('entries/0/event/data/previous'), isNull);

    // Assert device 4
    final change2 = map.values.last;
    expect(change2.elementAt('uuid'), isNotNull);
    expect(change2.elementAt('type'), 'Changes');
    expect(change2.elementAt('pending'), 0);
    expect(change2.elementAt('created'), isNotEmpty);
    expect(change2.elementAt('number'), EventNumber.none.value);
    expect(change2.elementAt('entries/0/type'), 'Device');
    expect(change2.elementAt('entries/0/event'), isA<Map>());
    expect(change2.elementAt('entries/0/event/uuid'), isNotNull);
    expect(change2.elementAt('entries/0/event/type'), 'DeviceCreated');
    expect(change2.elementAt('entries/0/event/data'), isA<Map>());
    expect(change2.elementAt('entries/0/event/data/uuid'), duuid4);
    expect(change2.elementAt('entries/0/event/data/changed'), isNull);
    expect(change2.elementAt('entries/0/event/data/patches'), isNull);
    expect(change2.elementAt('entries/0/event/data/previous'), isNull);

    // Cleanup
    await sub.cancel();
  });

  test("Should receive events matching multiple AND-ed filters", () async {
    // Arrange
    final messages = [];
    final uuid = Uuid().v4();
    const duuid1 = 'duuid1';
    const duuid2 = 'duuid2';
    const duuid3 = 'duuid3';
    const duuid4 = 'duuid4';
    final channel = harness.getWebSocketChannel(appId);
    final stream = channel.stream.asBroadcastStream();
    final sub = stream.listen(messages.add);
    final data = {
      'maxCount': 50,
      'minPeriod': 1,
      'types': [
        {
          'name': 'Device',
          'match': 'all',
          'filters': [
            {'pattern': "\$.data[?(@.alias=='alias')]"},
            {'pattern': "\$.data[?(@.number=='string')]"},
          ],
        }
      ],
    };
    // Act
    channel.sink.add(
      json.encode({
        'uuid': uuid,
        'data': data,
        'type': 'Subscribe',
      }),
    );
    await stream.take(1).toList();

    final responses = <Future>[];
    final device1 = createDevice(duuid1);
    responses.add(harness.agent.post("/api/devices", body: device1));
    final device2 = createDevice(duuid2, alias: 'alias');
    responses.add(harness.agent.post("/api/devices", body: device2));
    final device3 = createDevice(duuid3);
    responses.add(harness.agent.post("/api/devices", body: device3));
    final device4 = createDevice(duuid4, alias: 'alias');
    responses.add(harness.agent.post("/api/devices", body: device4));
    final changes = await stream.take(2).toList();

    // Wait for all commands to complete
    await Future.wait(responses);

    // Sort responses since order of events between aggregates is random
    final message1 = json.decode(changes.first as String) as Map<String, dynamic>;
    final message2 = json.decode(changes.last as String) as Map<String, dynamic>;
    final map = sortMapKeys({
      message1.elementAt('entries/0/event/data/uuid'): message1,
      message2.elementAt('entries/0/event/data/uuid'): message2,
    });

    // Assert device 2
    final change1 = map.values.first;
    expect(change1.elementAt('uuid'), isNotNull);
    expect(change1.elementAt('type'), 'Changes');
    expect(change1.elementAt('pending'), 0);
    expect(change1.elementAt('created'), isNotEmpty);
    expect(change1.elementAt('number'), EventNumber.none.value);
    expect(change1.elementAt('entries/0/type'), 'Device');
    expect(change1.elementAt('entries/0/event'), isA<Map>());
    expect(change1.elementAt('entries/0/event/uuid'), isNotNull);
    expect(change1.elementAt('entries/0/event/type'), 'DeviceCreated');
    expect(change1.elementAt('entries/0/event/data'), isA<Map>());
    expect(change1.elementAt('entries/0/event/data/uuid'), duuid2);
    expect(change1.elementAt('entries/0/event/data/changed'), isNull);
    expect(change1.elementAt('entries/0/event/data/patches'), isNull);
    expect(change1.elementAt('entries/0/event/data/previous'), isNull);

    // Assert device 4
    final change2 = map.values.last;
    expect(change2.elementAt('uuid'), isNotNull);
    expect(change2.elementAt('type'), 'Changes');
    expect(change2.elementAt('pending'), 0);
    expect(change2.elementAt('created'), isNotEmpty);
    expect(change2.elementAt('number'), EventNumber.none.value);
    expect(change2.elementAt('entries/0/type'), 'Device');
    expect(change2.elementAt('entries/0/event'), isA<Map>());
    expect(change2.elementAt('entries/0/event/uuid'), isNotNull);
    expect(change2.elementAt('entries/0/event/type'), 'DeviceCreated');
    expect(change2.elementAt('entries/0/event/data'), isA<Map>());
    expect(change2.elementAt('entries/0/event/data/uuid'), duuid4);
    expect(change2.elementAt('entries/0/event/data/changed'), isNull);
    expect(change2.elementAt('entries/0/event/data/patches'), isNull);
    expect(change2.elementAt('entries/0/event/data/previous'), isNull);

    // Cleanup
    await sub.cancel();
  });

  test("Should receive events filtered on radius", () async {
    // Arrange
    final messages = [];
    final uuid = Uuid().v4();
    const duuid1 = 'duuid1';
    const duuid2 = 'duuid2';
    final channel = harness.getWebSocketChannel(appId);
    final stream = channel.stream.asBroadcastStream();
    final sub = stream.listen(messages.add);
    final data = {
      'maxCount': 50,
      'minPeriod': 1,
      'types': [
        {
          'name': 'Device',
          'match': 'any',
          'events': [
            {'name': 'DevicePositionChanged'}
          ],
          'filters': [
            {
              'pattern': "\$.data.position.geometry[?(@.coordinates within 'circle; r=10; c=[59.0, 10.0]')]",
            }
          ],
        }
      ],
    };
    // Act
    channel.sink.add(
      json.encode({
        'uuid': uuid,
        'data': data,
        'type': 'Subscribe',
      }),
    );
    await stream.take(1).toList();

    final responses = <Future>[];
    final device1 = createDevice(duuid1);
    final device2 = createDevice(duuid2);
    await harness.agent.post("/api/devices", body: device1);
    await harness.agent.post("/api/devices", body: device2);

    responses.add(
      harness.agent.execute(
        'PATCH',
        "/api/devices/$duuid1/position",
        body: createPosition(lat: 59.0, lon: 10.01),
      ),
    );
    responses.add(
      harness.agent.execute(
        'PATCH',
        "/api/devices/$duuid2/position",
        body: createPosition(lat: 59.01, lon: 10.0),
      ),
    );

    final changes = await stream.take(2).toList();

    // Wait for all commands to complete
    await Future.wait(responses);

    // Sort responses since order of events between aggregates is random
    final message1 = json.decode(changes[0] as String) as Map<String, dynamic>;
    final message2 = json.decode(changes[1] as String) as Map<String, dynamic>;
    final map = sortMapKeys({
      message1.elementAt('entries/0/event/data/uuid'): message1,
      message2.elementAt('entries/0/event/data/uuid'): message2,
    });

    // Assert device 1
    final change1 = map.values.first;
    expect(change1.elementAt('uuid'), isNotNull);
    expect(change1.elementAt('type'), 'Changes');
    expect(change1.elementAt('pending'), 0);
    expect(change1.elementAt('created'), isNotEmpty);
    expect(change1.elementAt('number'), EventNumber.none.value);
    expect(change1.elementAt('entries/0/type'), 'Device');
    expect(change1.elementAt('entries/0/event'), isA<Map>());
    expect(change1.elementAt('entries/0/event/uuid'), isNotNull);
    expect(change1.elementAt('entries/0/event/type'), 'DevicePositionChanged');
    expect(change1.elementAt('entries/0/event/data'), isA<Map>());
    expect(change1.elementAt('entries/0/event/data/uuid'), duuid1);
    expect(change1.elementAt('entries/0/event/data/changed'), isNull);
    expect(change1.elementAt('entries/0/event/data/patches'), isNull);
    expect(change1.elementAt('entries/0/event/data/previous'), isNull);

    // Assert device 2
    final change2 = map.values.last;
    expect(change2.elementAt('uuid'), isNotNull);
    expect(change2.elementAt('type'), 'Changes');
    expect(change2.elementAt('pending'), 0);
    expect(change2.elementAt('created'), isNotEmpty);
    expect(change2.elementAt('number'), EventNumber.none.value);
    expect(change2.elementAt('entries/0/type'), 'Device');
    expect(change2.elementAt('entries/0/event'), isA<Map>());
    expect(change2.elementAt('entries/0/event/uuid'), isNotNull);
    expect(change2.elementAt('entries/0/event/type'), 'DevicePositionChanged');
    expect(change2.elementAt('entries/0/event/data'), isA<Map>());
    expect(change2.elementAt('entries/0/event/data/uuid'), duuid2);
    expect(change2.elementAt('entries/0/event/data/changed'), isNull);
    expect(change2.elementAt('entries/0/event/data/patches'), isNull);
    expect(change2.elementAt('entries/0/event/data/previous'), isNull);

    // Cleanup
    await sub.cancel();
  });
}
