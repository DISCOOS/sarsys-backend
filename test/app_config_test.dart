import 'harness/app.dart';

Future main() async {
  final harness = Harness()..install();

  test("GET /api/client.html returns status code 200", () async {
    expectResponse(await harness.agent.get("/api/client.html"), 200);
  });

  test("GET /api/healthz returns status code 200 Status OK", () async {
    expectResponse(await harness.agent.get("/api/healthz"), 200, body: "Status OK");
  });

  test("GET /app-config/:id returns 200 GET /api/app-config/:id", () async {
    expectResponse(await harness.agent.get("/api/app-config/1"), 200, body: 'GET /api/app-config/1');
  });
}
