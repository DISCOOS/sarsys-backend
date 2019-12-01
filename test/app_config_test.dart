import 'harness/app.dart';

Future main() async {
  final harness = Harness()..install();

  test("GET /app-config/:id returns 200 GET /app-config/:id", () async {
    expectResponse(await harness.agent.get("/app-config/1"), 200, body: 'GET /app-config/1');
  });
}
