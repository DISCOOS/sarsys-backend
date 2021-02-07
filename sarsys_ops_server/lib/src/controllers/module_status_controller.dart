import 'package:sarsys_ops_server/sarsys_ops_server.dart';
import 'package:sarsys_ops_server/src/config.dart';
import 'package:sarsys_ops_server/src/controllers/status_base_controller.dart';

class ModuleStatusController extends StatusBaseController {
  ModuleStatusController(SarSysOpsConfig config)
      : super('Module', config, [
          'sarsys-app-server',
          'sarsys-tracking-server',
        ]);

  final K8sApi k8s = K8sApi();
  final HttpClient client = HttpClient();

  @override
  @Operation.get()
  Future<Response> getAll() {
    return super.getAll();
  }

  @override
  Future<Map<String, dynamic>> doGetByName(String name) async {
    final pods = await k8s.getPodsFromNs(
      k8s.namespace,
      labels: [
        'module=$name',
      ],
    );
    return {
      'name': name,
      'instances': await _toInstanceStatus(pods),
    };
  }

  Future<List<Map<String, dynamic>>> _toInstanceStatus(List<Map<String, dynamic>> pods) async {
    final instances = <Map<String, dynamic>>[];
    for (var pod in pods) {
      instances.add({
        'name': pod.elementAt('metadata/name'),
        'status': _toPodStatus(pod),
        'health': await _toInstanceHealth(pod)
      });
    }
    return instances.toList();
  }

  Future<Map<String, dynamic>> _toInstanceHealth(Map<String, dynamic> pod) async {
    return {
      'alive': await _isOK(pod, '/api/healthz/alive'),
      'ready': await _isOK(pod, '/api/healthz/ready'),
    };
  }

  Future<bool> _isOK(Map<String, dynamic> pod, String uri) async {
    try {
      final url = k8s.toPodUri(pod, uri: uri);
      final response = await k8s.getUrl(
        url,
        authenticate: false,
      );
      return response.statusCode == HttpStatus.ok;
    } on Exception {
      return false;
    }
  }

  Map<String, dynamic> _toPodStatus(Map<String, dynamic> pod) {
    final conditions = pod.listAt(
      'status/conditions',
      defaultList: [],
    ).map((c) => Map<String, dynamic>.from(c));

    if (conditions.isEmpty) {
      return {
        'type': 'unknown',
        'acceptable': false,
        'reason': 'EMPTY_LIST',
        'message': 'no conditions found',
      };
    }
    return conditions.lastWhere(
      (c) => 'true' == c.elementAt<String>('status', defaultValue: 'False').toLowerCase(),
      orElse: () => conditions.first,
    );
  }

  //////////////////////////////////
  // Documentation
  //////////////////////////////////

  @override
  APISchemaObject documentStatusType(APIDocumentContext context) => documentModuleStatus();
}
