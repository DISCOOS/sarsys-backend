import 'package:sarsys_ops_server/sarsys_ops_server.dart';
import 'package:sarsys_ops_server/src/controllers/status_controller.dart';

class SystemStatusController extends StatusController {
  SystemStatusController(SarSysConfig config) : super('System', config);

  final k8s = K8sApi();

  @override
  Future<Response> doGetAll() async {
    final pods = await k8s.getPodNamesFromNs(
      k8s.namespace,
    );
    return Response.ok(pods);
  }

  @override
  Future<Response> doGetByName(String name) {
    // TODO: implement doGetByName
    throw UnimplementedError();
  }

  @override
  APISchemaObject documentStatusType(APIDocumentContext context) => APISchemaObject.object({
        'name': APISchemaObject.string()..description = 'Server name',
        'status': context.schema['ServerStatus'],
      });
}
