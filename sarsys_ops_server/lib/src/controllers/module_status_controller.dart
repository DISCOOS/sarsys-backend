import 'package:sarsys_ops_server/sarsys_ops_server.dart';
import 'package:sarsys_ops_server/src/config.dart';
import 'package:sarsys_ops_server/src/controllers/status_base_controller.dart';

class ModuleStatusController extends StatusBaseController {
  ModuleStatusController(SarSysOpsConfig config)
      : super('Module', config, [
          'sarsys-app-server',
          'sarsys-tracking-server',
          'sarsys-tracking-server',
        ]);

  final k8s = K8sApi();

  @override
  @Operation.get()
  Future<Response> getAll() {
    return super.getAll();
  }

  @override
  Future<Map<String, dynamic>> doGetByName(String name) async {
    final instances = await k8s.getPodNamesFromNs(
      k8s.namespace,
      labels: [
        'module=$name',
      ],
    );
    return {
      'name': name,
      'instances': instances.map(
        (instance) => {
          'name': instance,
          'health': {
            'alive': 'N/A',
            'ready': 'N/A',
          }
        },
      ),
    };
  }

  @override
  APISchemaObject documentStatusType(APIDocumentContext context) => documentModuleStatus();
}
