import 'dart:async';

import 'package:uuid/uuid.dart';
import 'package:test/test.dart';

import 'harness.dart';

Future main() async {
  final harness = SarSysHttpHarness()
    ..withEventStoreMock()
    ..install(restartForEachTest: true);

  test("POST /api/trackings/{uuid}/sources returns status code 201 with empty body", () async {
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
    final source = createSource(uuid: Uuid().v4());
    expectResponse(await harness.agent.post("/api/trackings/$uuid/sources", body: source), 201, body: null);
  });

  test("GET /api/trackings/{uuid}/sources returns status code 200", () async {
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
    final source1 = createSource(uuid: Uuid().v4());
    expectResponse(await harness.agent.post("/api/trackings/$uuid/sources", body: source1), 201, body: null);
    final source2 = createSource(uuid: Uuid().v4());
    expectResponse(await harness.agent.post("/api/trackings/$uuid/sources", body: source2), 201, body: null);
    final response = expectResponse(await harness.agent.get("/api/trackings/$uuid/sources"), 200);
    final actual = await response.body.decode();
    expect(actual['total'], equals(2));
    expect(actual['entries'].length, equals(2));
  });

  test("GET /api/trackings/{uuid}/sources/{uuid} returns status code 200", () async {
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
    final source1 = createSource(uuid: Uuid().v4());
    expectResponse(await harness.agent.post("/api/trackings/$uuid/sources", body: source1), 201, body: null);
    final response1 = expectResponse(await harness.agent.get("/api/trackings/$uuid/sources/${source1['uuid']}"), 200);
    final actual1 = await response1.body.decode();
    expect(actual1['data'], equals(source1));
    final source2 = createSource(uuid: Uuid().v4());
    expectResponse(await harness.agent.post("/api/trackings/$uuid/sources", body: source2), 201, body: null);
    final response2 = expectResponse(await harness.agent.get("/api/trackings/$uuid/sources/${source2['uuid']}"), 200);
    final actual2 = await response2.body.decode();
    expect(actual2['data'], equals(source2));
  });

  test("DELETE /api/trackings/{uuid}/sources/{uuid} returns status code 204", () async {
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
    final source = createSource(uuid: Uuid().v4());
    expectResponse(await harness.agent.post("/api/trackings/$uuid/sources", body: source), 201, body: null);
    expectResponse(await harness.agent.delete("/api/trackings/$uuid/sources/${source['uuid']}"), 204);
  });
}

Map<String, Object> _createData(String uuid) => createTracking(uuid);
