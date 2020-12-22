import 'package:aqueduct/aqueduct.dart';
import 'package:event_source/event_source.dart';
import 'package:sarsys_http_core/sarsys_http_core.dart';

class LivenessController extends ResourceController {
  LivenessController();

  @Operation.get()
  Future<Response> check() async {
    return Response.ok('Status OK');
  }

  @override
  List<String> documentOperationTags(APIDocumentContext context, Operation operation) {
    return ['System'];
  }
}
