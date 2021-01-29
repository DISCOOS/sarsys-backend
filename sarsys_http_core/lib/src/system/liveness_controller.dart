import 'package:aqueduct/aqueduct.dart';
import 'package:sarsys_http_core/sarsys_http_core.dart';

class LivenessController extends ReadinessController {
  LivenessController() : super(() => true);

  @override
  List<String> documentOperationTags(APIDocumentContext context, Operation operation) {
    return ['System'];
  }
}
