import 'dart:async';

import 'package:uuid/uuid.dart';
import 'package:test/test.dart';

import 'package:collection_x/collection_x.dart';
import 'package:sarsys_domain/sarsys_domain.dart';
import 'package:sarsys_app_server_test/sarsys_app_server_test.dart';

Future main() async {
  final harness = SarSysAppHarness()
    ..withEventStoreMock()
    ..install(restartForEachTest: true);

  test("GET /api/trackings/{uuid}/tracks returns status code 200", () async {
    final p1 = createPosition(lat: 1.0);
    final p2 = createPosition(lon: 1.0);
    final positions = [p1, p2];
    final actual = await _prepareGetAll(harness, positions: positions);
    expect(actual['total'], equals(2));
    expect(actual['entries'].length, equals(2));
    expect(actual.listAt('entries/0/data/positions'), isNull);
    expect(actual.listAt('entries/1/data/positions'), isNull);
  });

  test("GET /api/trackings/{uuid}/tracks?expand=positions returns status code 200", () async {
    final p1 = createPosition(lat: 1.0);
    final p2 = createPosition(lon: 1.0);
    final positions = [p1, p2];
    final actual = await _prepareGetAll(harness, positions: positions, extend: 'positions');
    expect(actual['total'], equals(2));
    expect(actual['entries'].length, equals(2));
    expect(actual.listAt('entries/0/positions'), hasLength(positions.length));
    expect(actual.listAt('entries/1/positions'), hasLength(positions.length));
  });

  test("GET /api/trackings/{uuid}/tracks?expand=positions&option=truncate:1:p returns status code 200", () async {
    final p1 = createPosition(lat: 1.0);
    final p2 = createPosition(lon: 1.0);
    final positions = [p1, p2];
    final actual = await _prepareGetAll(
      harness,
      positions: positions,
      extend: 'positions',
      option: 'truncate:1:p',
    );
    expect(actual['total'], equals(2));
    expect(actual['entries'].length, equals(2));
    expect(actual.listAt('entries/0/positions'), hasLength(1));
    expect(actual.listAt('entries/1/positions'), hasLength(1));
  });

  test("GET /api/trackings/{uuid}/tracks?expand=positions&option=truncate:1:m returns status code 200", () async {
    final p1 = createPosition(lat: 1.0);
    final p2 = createPosition(lon: 1.0);
    final positions = [p1, p2];
    final actual = await _prepareGetAll(
      harness,
      positions: positions,
      extend: 'positions',
      option: 'truncate:1:m',
    );
    expect(actual['total'], equals(2));
    expect(actual['entries'].length, equals(2));
    expect(actual.listAt('entries/0/positions'), hasLength(2));
    expect(actual.listAt('entries/1/positions'), hasLength(2));
  });

  test("GET /api/trackings/{uuid}/tracks?expand=positions&option=truncate:1:h returns status code 200", () async {
    final p1 = createPosition(lat: 1.0);
    final p2 = createPosition(lon: 1.0);
    final positions = [p1, p2];
    final actual = await _prepareGetAll(
      harness,
      positions: positions,
      extend: 'positions',
      option: 'truncate:1:h',
    );
    expect(actual['total'], equals(2));
    expect(actual['entries'].length, equals(2));
    expect(actual.listAt('entries/0/positions'), hasLength(2));
    expect(actual.listAt('entries/1/positions'), hasLength(2));
  });

  test("GET /api/trackings/{uuid}/tracks/{id} returns status code 200", () async {
    final repo = harness.channel.manager.get<TrackingRepository>();
    await repo.readyAsync();
    final uuid = Uuid().v4();
    final tracking = _createData(uuid);
    expectResponse(
      await harness.agent.post(
        "/api/trackings",
        headers: createAuthn(createAuthnAdmin()),
        body: tracking,
      ),
      201,
      body: null,
    );
    final p1 = createPosition(lat: 1.0);
    final p2 = createPosition(lon: 1.0);
    final positions = [p1, p2];
    final track1 = createTrack(id: '1', positions: positions);
    await _addTrackingTrack(repo, uuid, track1);
    final response1 = expectResponse(await harness.agent.get("/api/trackings/$uuid/tracks/1"), 200);
    final actual1 = Map<String, dynamic>.from(await response1.body.decode());
    expect(actual1['data'], equals(track1..remove('positions')));
    final track2 = createTrack(id: '2', positions: positions);
    await _addTrackingTrack(repo, uuid, track2);
    final response2 = expectResponse(await harness.agent.get("/api/trackings/$uuid/tracks/2"), 200);
    final actual2 = Map<String, dynamic>.from(await response2.body.decode());
    expect(actual2['data'], equals(track2..remove('positions')));
  });

  test("GET /api/trackings/{uuid}/tracks/{id}?expand=positions returns status code 200", () async {
    final repo = harness.channel.manager.get<TrackingRepository>();
    await repo.readyAsync();
    final uuid = Uuid().v4();
    final tracking = _createData(uuid);
    expectResponse(
      await harness.agent.post(
        "/api/trackings",
        headers: createAuthn(createAuthnAdmin()),
        body: tracking,
      ),
      201,
      body: null,
    );
    final p1 = createPosition(lat: 1.0);
    final p2 = createPosition(lon: 1.0);
    final positions = [p1, p2];
    final track1 = createTrack(id: '1', positions: positions);
    await _addTrackingTrack(repo, uuid, track1);
    final response1 = expectResponse(await harness.agent.get("/api/trackings/$uuid/tracks/1?expand=positions"), 200);
    final actual1 = Map<String, dynamic>.from(await response1.body.decode());
    expect(actual1['data'], equals(track1));
    expect(actual1.listAt('data/positions'), hasLength(2));
    final track2 = createTrack(id: '2', positions: positions);
    await _addTrackingTrack(repo, uuid, track2);
    final response2 = expectResponse(await harness.agent.get("/api/trackings/$uuid/tracks/2?expand=positions"), 200);
    final actual2 = Map<String, dynamic>.from(await response2.body.decode());
    expect(actual2['data'], equals(track2));
    expect(actual2.listAt('data/positions'), hasLength(2));
  });
}

Future<Map<String, dynamic>> _prepareGetAll(
  SarSysAppHarness harness, {
  String extend,
  String option,
  List<Map<String, dynamic>> positions = const [],
}) async {
  final repo = harness.channel.manager.get<TrackingRepository>();
  await repo.readyAsync();
  final uuid = Uuid().v4();
  final tracking = _createData(uuid);
  expectResponse(
    await harness.agent.post(
      "/api/trackings",
      headers: createAuthn(
        createAuthnAdmin(),
      ),
      body: tracking,
    ),
    201,
    body: null,
  );
  final track1 = createTrack(
    id: '1',
    positions: positions,
  );
  await _addTrackingTrack(repo, uuid, track1);
  final track2 = createTrack(
    id: '2',
    positions: positions,
  );
  await _addTrackingTrack(repo, uuid, track2);
  final response = expectResponse(
    await harness.agent.get(
      "/api/trackings/$uuid/tracks${extend == null ? '' : '?expand=$extend${option == null ? '' : '&option=$option'}'}",
    ),
    200,
  );
  final actual = Map<String, dynamic>.from(await response.body.decode());
  return actual;
}

Map<String, Object> _createData(String uuid) => createTracking(uuid);

FutureOr<Map<String, dynamic>> _addTrackingTrack(
  TrackingRepository repo,
  String uuid,
  Map<String, dynamic> track,
) async {
  await repo.execute(AddTrackToTracking(uuid, track));
  return track;
}
