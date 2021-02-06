import 'package:sarsys_ops_server/sarsys_ops_server.dart';
import 'package:sarsys_ops_server/src/config.dart';
import 'package:sarsys_ops_server/src/controllers/status_base_controller.dart';

class SystemStatusController extends StatusBaseController {
  SystemStatusController(SarSysOpsConfig config) : super('System', config);

  final k8s = K8sApi();

  @override
  @Operation.get()
  Future<Response> getAll() {
    return super.getAll();
  }

  @override
  Future<Response> doGetAll() async {
    final pods = await k8s.getPodNamesFromNs(
      k8s.namespace,
    );
    return Response.ok(pods);
  }

  @override
  APISchemaObject documentStatusType(APIDocumentContext context) => APISchemaObject.object({
        'name': APISchemaObject.string()..description = 'Server name',
        'status': context.schema['ServerStatus'],
      });
}
