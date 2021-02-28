import 'package:sarsys_domain/sarsys_domain.dart';
import 'package:uuid/uuid.dart';
import 'package:test/test.dart';

import 'package:sarsys_app_server_test/sarsys_app_server_test.dart';

Future main() async {
  final harness = SarSysAppHarness()
    ..withEventStoreMock()
    ..install(restartForEachTest: true);

  test("POST /api/trackings/ returns status code 201 with empty body", () async {
    final uuid = Uuid().v4();
    final body = createTracking(uuid);
    expectResponse(
      await harness.agent.post(
        "/api/trackings",
        headers: createAuthn(createAuthnAdmin()),
        body: body,
      ),
      201,
      body: null,
    );
  });

  test("GET /api/trackings/{uuid} returns status code 200", () async {
    final uuid = Uuid().v4();
    final body = createTracking(uuid);
    expectResponse(
        await harness.agent.post(
          "/api/trackings",
          headers: createAuthn(createAuthnAdmin()),
          body: body,
        ),
        201,
        body: null);
    final response = expectResponse(
      await harness.agent.get(
        "/api/trackings/$uuid",
        headers: createAuthn(createAuthnPersonnel()),
      ),
      200,
    );
    final actual = await response.body.decode();
    expect(actual['data'], equals(body));
  });

  test("PATCH /api/trackings/{uuid} add sources to empty list and returns status code 200", () async {
    // Arrange
    final uuid = Uuid().v4();
    final body = createTracking(
      uuid,
    );
    expectResponse(
      await harness.agent.post(
        "/api/trackings",
        headers: createAuthn(
          createAuthnAdmin(),
        ),
        body: body,
      ),
      201,
      body: null,
    );

    // Act - force replace patch
    final sources2 = [
      createSource(uuid: 's1'),
      createSource(uuid: 's2'),
      createSource(uuid: 's3'),
      createSource(uuid: 's4'),
      createSource(uuid: 's5'),
      createSource(uuid: 's6'),
      createSource(uuid: 's7'),
    ];
    body['status'] = enumName(TrackingStatus.tracking);
    body['sources'] = sources2;

    // Assert
    final response = expectResponse(
      await harness.agent.execute(
        'PATCH',
        "/api/trackings/$uuid",
        headers: createAuthn(
          createAuthnPersonnel(),
        ),
        body: body,
      ),
      200,
    );
    final actual = await response.body.decode();
    expect(actual['data'], equals(body));
  });

  test("PATCH /api/trackings/{uuid} replace sources and returns status code 200", () async {
    // Arrange
    final uuid = Uuid().v4();
    final sources1 = [
      createSource(uuid: 's1'),
      createSource(uuid: 's2'),
    ];
    final body = createTracking(
      uuid,
      sources: sources1,
    );
    expectResponse(
      await harness.agent.post(
        "/api/trackings",
        headers: createAuthn(
          createAuthnAdmin(),
        ),
        body: body,
      ),
      201,
      body: null,
    );

    // Act - force replace patch
    final sources2 = [
      createSource(uuid: 's2'),
    ];
    body['status'] = enumName(TrackingStatus.tracking);
    body['sources'] = sources2;

    // Assert
    final response = expectResponse(
      await harness.agent.execute(
        'PATCH',
        "/api/trackings/$uuid",
        headers: createAuthn(
          createAuthnPersonnel(),
        ),
        body: body,
      ),
      200,
    );
    final actual = await response.body.decode();
    expect(actual['data'], equals(body));
  });

  test("PATCH /api/trackings/{uuid} remove, add and returns status code 200", () async {
    // Arrange
    final uuid = Uuid().v4();
    final sources1 = [
      createSource(uuid: 's1'),
      createSource(uuid: 's2'),
    ];
    final body = createTracking(
      uuid,
      sources: sources1,
    );
    expectResponse(
      await harness.agent.post(
        "/api/trackings",
        headers: createAuthn(
          createAuthnAdmin(),
        ),
        body: body,
      ),
      201,
      body: null,
    );

    // Act - force remove and add patches
    final sources2 = [
      createSource(uuid: 's2'),
      createSource(uuid: 's3'),
    ];
    body['status'] = enumName(TrackingStatus.tracking);
    body['sources'] = sources2;

    // Assert
    final response = expectResponse(
      await harness.agent.execute(
        'PATCH',
        "/api/trackings/$uuid",
        headers: createAuthn(
          createAuthnPersonnel(),
        ),
        body: body,
      ),
      200,
    );
    final actual = await response.body.decode();
    expect(actual['data'], equals(body));
  });

  test("PATCH /api/trackings/{uuid} with same source ids should return code 200", () async {
    // Arrange
    final uuid = Uuid().v4();
    final sources1 = [
      createSource(uuid: 's1', type: 'device'),
      createSource(uuid: 's2', type: 'device'),
    ];
    final body = createTracking(
      uuid,
      sources: sources1,
    );
    expectResponse(
      await harness.agent.post(
        "/api/trackings",
        headers: createAuthn(
          createAuthnAdmin(),
        ),
        body: body,
      ),
      201,
      body: null,
    );

    // Act - force update patches
    final sources2 = [
      createSource(uuid: 's1', type: 'trackable'),
      createSource(uuid: 's2', type: 'trackable'),
    ];
    body['status'] = enumName(TrackingStatus.tracking);
    body['sources'] = sources2;

    // Assert
    final response = expectResponse(
      await harness.agent.execute(
        'PATCH',
        "/api/trackings/$uuid",
        headers: createAuthn(
          createAuthnPersonnel(),
        ),
        body: body,
      ),
      200,
    );
    final actual = await response.body.decode();
    expect(actual['data'], equals(body));
  });

  test("DELETE /api/trackings/{uuid} returns status code 204", () async {
    final uuid = Uuid().v4();
    final body = createTracking(uuid);
    expectResponse(
      await harness.agent.post(
        "/api/trackings",
        headers: createAuthn(createAuthnAdmin()),
        body: body,
      ),
      201,
      body: null,
    );
    expectResponse(
      await harness.agent.delete(
        "/api/trackings/$uuid",
        headers: createAuthn(createAuthnAdmin()),
      ),
      204,
    );
  });

  test("GET /api/trackings returns status code 200 with offset=1 and limit=2", () async {
    await harness.channel.manager.get<TrackingRepository>().readyAsync();
    await harness.agent.post(
      "/api/trackings",
      headers: createAuthn(createAuthnAdmin()),
      body: createTracking(Uuid().v4()),
    );
    await harness.agent.post(
      "/api/trackings",
      headers: createAuthn(createAuthnAdmin()),
      body: createTracking(Uuid().v4()),
    );
    await harness.agent.post(
      "/api/trackings",
      headers: createAuthn(createAuthnAdmin()),
      body: createTracking(Uuid().v4()),
    );
    await harness.agent.post(
      "/api/trackings",
      headers: createAuthn(createAuthnAdmin()),
      body: createTracking(Uuid().v4()),
    );
    final response = expectResponse(
        await harness.agent.get(
          "/api/trackings?offset=1&limit=2",
          headers: createAuthn(createAuthnPersonnel()),
        ),
        200);
    final actual = await response.body.decode();
    expect(actual['total'], equals(4));
    expect(actual['offset'], equals(1));
    expect(actual['limit'], equals(2));
    expect(actual['entries'].length, equals(2));
  });
}
