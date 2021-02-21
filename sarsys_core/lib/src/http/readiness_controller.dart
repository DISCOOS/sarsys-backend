import 'package:aqueduct/aqueduct.dart';
import 'package:sarsys_core/sarsys_core.dart';

class ReadinessController extends ResourceController {
  ReadinessController(this.onCheck);
  final bool Function() onCheck;

  @override
  Logger get logger => Logger('$runtimeType');

  @Operation.get()
  Future<Response> check() async {
    return onCheck() ? Response.ok('Status OK') : serviceUnavailable(body: 'Status Not ready');
  }

  @override
  List<String> documentOperationTags(APIDocumentContext context, Operation operation) {
    return ['System'];
  }
}
