import 'package:aqueduct/aqueduct.dart';
import 'package:event_source/event_source.dart';
import 'package:sarsys_http_core/sarsys_http_core.dart';

class ReadinessController extends ResourceController {
  ReadinessController(this.manager);
  final RepositoryManager manager;

  @Operation.get()
  Future<Response> check() async {
    return manager.isReady ? Response.ok('Status OK') : serviceUnavailable(body: 'Status Not ready');
  }

  @override
  List<String> documentOperationTags(APIDocumentContext context, Operation operation) {
    return ['System'];
  }
}
