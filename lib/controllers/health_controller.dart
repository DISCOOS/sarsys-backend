import 'package:sarsys_app_server/sarsys_app_server.dart';

class HealthController extends ResourceController {
  @Operation.get()
  Future<Response> check() async {
    return Response.ok("Status OK");
  }
}
