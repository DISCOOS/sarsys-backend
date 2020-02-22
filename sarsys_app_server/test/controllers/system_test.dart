import 'harness.dart';

Future main() async {
  final harness = SarSysHarness()
    ..withEventStoreMock()
    ..install();

  test("GET /api/client.html returns status code 200", () async {
    expectResponse(await harness.agent.get("/api/client.html"), 200);
  });

  test("GET /api/healthz returns status code 200 Status OK", () async {
    expectResponse(await harness.agent.get("/api/healthz"), 200, body: "Status OK");
  });
}
