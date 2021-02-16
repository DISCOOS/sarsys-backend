import 'package:aqueduct/aqueduct.dart';
import 'package:sarsys_core/sarsys_core.dart';

import 'readiness_controller.dart';

class LivenessController extends ReadinessController {
  LivenessController() : super(() => true);

  @override
  List<String> documentOperationTags(APIDocumentContext context, Operation operation) {
    return ['System'];
  }
}
