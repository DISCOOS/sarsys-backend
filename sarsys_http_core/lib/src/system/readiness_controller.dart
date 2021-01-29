import 'package:aqueduct/aqueduct.dart';
import 'package:event_source/event_source.dart';
import 'package:sarsys_http_core/sarsys_http_core.dart';

class ReadinessController extends ResourceController {
  ReadinessController(this.onCheck);
  final bool Function() onCheck;

  @Operation.get()
  Future<Response> check() async {
    return onCheck() ? Response.ok('Status OK') : serviceUnavailable(body: 'Status Not ready');
  }

  @override
  List<String> documentOperationTags(APIDocumentContext context, Operation operation) {
    return ['System'];
  }
}
