import 'package:sarsys_app_server/app_server.dart';

class HealthController extends ResourceController {
  @Operation.get()
  Future<Response> check() async {
    return Response.ok("Status OK");
  }

  @override
  List<String> documentOperationTags(APIDocumentContext context, Operation operation) {
    return ['System'];
  }
}
