import 'package:sarsys_app_server/sarsys_app_server.dart';

class AppConfigController extends ResourceController {
  @Operation.get('id')
  Future<Response> get(@Bind.path('id') String id) async {
    // GET /app-config/:id
    return Response.ok("GET /${request.path.segments.join('/')}");
  }
}
