import 'package:uuid/uuid.dart';
import 'package:test/test.dart';
import 'package:collection_x/collection_x.dart';

import 'package:sarsys_app_server_test/sarsys_app_server_test.dart';

Future main() async {
  final harness = SarSysAppHarness()
    ..withEventStoreMock()
    ..install(restartForEachTest: true);

  test("OPTIONS /api/devices/search returns status code 204 with header 'x-search-options'", () async {
    final response = expectResponse(
      await harness.agent.execute('OPTIONS', "/api/devices/search"),
      204,
      body: null,
    );
    expect(response.headers.value('x-search-options'), 'max-radius=100;');
  });

  test("GET /api/devices/search returns 200 for single pattern", () async {
    final uuid1 = Uuid().v4();
    final uuid2 = Uuid().v4();
    final uuid3 = Uuid().v4();
    final device1 = createDevice(uuid1);
    final device2 = createDevice(uuid2);
    final device3 = createDevice(uuid3);
    expectResponse(await harness.agent.post("/api/devices", body: device1), 201, body: null);
    expectResponse(await harness.agent.post("/api/devices", body: device2), 201, body: null);
    expectResponse(await harness.agent.post("/api/devices", body: device3), 201, body: null);
    final query = "\$.data[?(@.uuid=='$uuid2')]";
    final response = expectResponse(await harness.agent.get("/api/devices/search?pattern=$query"), 200);
    final actual = Map.from(await response.body.decode());
    expect(actual.elementAt('total'), 1);
    expect(actual.mapAt('entries/0/data'), device2);
  });

  test("GET /api/devices/search returns matches for OR-ed patterns", () async {
    final uuid1 = Uuid().v4();
    final uuid2 = Uuid().v4();
    final uuid3 = Uuid().v4();
    final device1 = createDevice(uuid1);
    final device2 = createDevice(uuid2);
    final device3 = createDevice(uuid3);
    expectResponse(await harness.agent.post("/api/devices", body: device1), 201, body: null);
    expectResponse(await harness.agent.post("/api/devices", body: device2), 201, body: null);
    expectResponse(await harness.agent.post("/api/devices", body: device3), 201, body: null);
    final query1 = "\$.data[?(@.uuid=='$uuid1')]";
    final query2 = "\$.data[?(@.uuid=='$uuid2')]";
    final response = expectResponse(
      await harness.agent.get("/api/devices/search?pattern=$query1&pattern=$query2&match=any"),
      200,
    );
    final actual = Map.from(await response.body.decode());
    expect(actual.elementAt('total'), 2);
    expect(actual.mapAt('entries/0/data'), device1);
    expect(actual.mapAt('entries/1/data'), device2);
  });

  test("GET /api/devices/search returns no matches for OR-ed patterns", () async {
    final uuid1 = Uuid().v4();
    final uuid2 = Uuid().v4();
    final uuid3 = Uuid().v4();
    final device1 = createDevice(uuid1);
    final device2 = createDevice(uuid2);
    final device3 = createDevice(uuid3);
    expectResponse(await harness.agent.post("/api/devices", body: device1), 201, body: null);
    expectResponse(await harness.agent.post("/api/devices", body: device2), 201, body: null);
    expectResponse(await harness.agent.post("/api/devices", body: device3), 201, body: null);
    const query1 = "\$.data[?(@.uuid=='devicex')]";
    const query2 = "\$.data[?(@.uuid=='devicey')]";
    final response = expectResponse(
      await harness.agent.get("/api/devices/search?pattern=$query1&pattern=$query2&match=any"),
      200,
    );
    final actual = Map.from(await response.body.decode());
    expect(actual.elementAt('total'), 0);
  });

  test("GET /api/devices/search returns matches for AND-ed patterns", () async {
    final uuid1 = Uuid().v4();
    final uuid2 = Uuid().v4();
    final uuid3 = Uuid().v4();
    final device1 = createDevice(uuid1);
    final device2 = createDevice(uuid2);
    final device3 = createDevice(uuid3, alias: 'alias');
    expectResponse(await harness.agent.post("/api/devices", body: device1), 201, body: null);
    expectResponse(await harness.agent.post("/api/devices", body: device2), 201, body: null);
    expectResponse(await harness.agent.post("/api/devices", body: device3), 201, body: null);
    const query1 = "\$.data[?(@.alias=='alias')]";
    const query2 = "\$.data[?(@.number=='string')]";
    final response = expectResponse(
      await harness.agent.get("/api/devices/search?pattern=$query1&pattern=$query2&match=all"),
      200,
    );
    final actual = Map.from(await response.body.decode());
    expect(actual.elementAt('total'), 1);
    expect(actual.mapAt('entries/0/data'), device3);
  });

  test("GET /api/devices/search returns no matches for AND-ed patterns", () async {
    final uuid1 = Uuid().v4();
    final uuid2 = Uuid().v4();
    final uuid3 = Uuid().v4();
    final device1 = createDevice(uuid1);
    final device2 = createDevice(uuid2);
    final device3 = createDevice(uuid3);
    expectResponse(await harness.agent.post("/api/devices", body: device1), 201, body: null);
    expectResponse(await harness.agent.post("/api/devices", body: device2), 201, body: null);
    expectResponse(await harness.agent.post("/api/devices", body: device3), 201, body: null);
    final query1 = "\$.data[?(@.uuid=='$uuid1')]";
    final query2 = "\$.data[?(@.uuid=='$uuid2')]";
    final response = expectResponse(
      await harness.agent.get("/api/devices/search?pattern=$query1&pattern=$query2&match=all"),
      200,
    );
    final actual = Map.from(await response.body.decode());
    expect(actual.elementAt('total'), 0);
  });
}
