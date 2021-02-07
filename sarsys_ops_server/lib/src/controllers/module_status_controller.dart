import 'package:sarsys_ops_server/sarsys_ops_server.dart';
import 'package:sarsys_ops_server/src/config.dart';
import 'package:sarsys_ops_server/src/controllers/status_base_controller.dart';

class ModuleStatusController extends StatusBaseController {
  ModuleStatusController(SarSysOpsConfig config)
      : ports = {
          'sarsys-app-server': config.app.port,
          'sarsys-tracking-server': config.tracking.healthPort,
        },
        super('Module', config, [
          'sarsys-app-server',
          'sarsys-tracking-server',
        ]);

  final K8sApi k8s = K8sApi();
  final Map<String, int> ports;
  final HttpClient client = HttpClient();

  @override
  @Operation.get()
  Future<Response> getAll() {
    return super.getAll();
  }

  @override
  @Operation.get('name')
  Future<Response> getByName(@Bind.path('name') String name) => super.getByName(name);

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
      'instances': await _toInstanceStatus(
        name,
        pods,
      ),
    };
  }

  Future<List<Map<String, dynamic>>> _toInstanceStatus(String name, List<Map<String, dynamic>> pods) async {
    final instances = <Map<String, dynamic>>[];
    for (var pod in pods) {
      instances.add({
        'name': pod.elementAt('metadata/name'),
        'status': await _toPodStatus(name, pod),
      });
    }
    return instances.toList();
  }

  Future<Map<String, dynamic>> _toInstanceHealth(String name, Map<String, dynamic> pod) async {
    return {
      'alive': await _isOK(name, pod, '/api/healthz/alive'),
      'ready': await _isOK(name, pod, '/api/healthz/ready'),
    };
  }

  Future<bool> _isOK(String name, Map<String, dynamic> pod, String uri) async {
    final url = k8s.toPodUri(
      pod,
      uri: uri,
      deployment: name,
      port: ports[name],
    );
    try {
      final response = await k8s.getUrl(
        url,
        authenticate: false,
      );
      logger.fine('GET $url responded with ${response.statusCode} ${response.reasonPhrase}');
      return response.statusCode == HttpStatus.ok;
    } on Exception catch (e) {
      logger.warning('GET $url failed with $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> _toPodStatus(String name, Map<String, dynamic> pod) async {
    final conditions = pod.listAt(
      'status/conditions',
      defaultList: [],
    ).map((c) => Map<String, dynamic>.from(c));

    return {
      'health': await _toInstanceHealth(
        name,
        pod,
      ),
      'conditions': conditions.isNotEmpty
          ? conditions.toList()
          : [
              {
                'type': 'Unknown',
                'status': 'Unknown',
                'reason': 'EMPTY_LIST',
                'message': 'No conditions found',
              }
            ]
    };
  }

  //////////////////////////////////
  // Documentation
  //////////////////////////////////

  @override
  APISchemaObject documentStatusType(APIDocumentContext context) => documentModuleStatus();
}
