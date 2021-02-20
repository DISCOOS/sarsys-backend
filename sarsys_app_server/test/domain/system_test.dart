import 'package:sarsys_app_server_test/sarsys_app_server_test.dart';

Future main() async {
  final harness = SarSysAppHarness()
    ..withEventStoreMock()
    ..install();

  test("GET /api/client.html returns status code 200", () async {
    expectResponse(await harness.agent.get("/api/client.html"), 200);
  });

  test("GET /api/healthz/alive returns status code 200 Status OK", () async {
    expectResponse(await harness.agent.get("/api/healthz/alive"), 200, body: "Status OK");
  });

  test("GET /api/healthz/ready returns status code 200 Status OK", () async {
    expectResponse(await harness.agent.get("/api/healthz/ready"), 200, body: "Status OK");
  });
}
