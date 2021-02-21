import 'package:sarsys_ops_server/sarsys_ops_server.dart';
import 'package:sarsys_ops_server/src/config.dart';
import 'package:sarsys_ops_server/src/controllers/status_base_controller.dart';

import 'utils.dart';

class ModuleStatusController extends StatusBaseController {
  ModuleStatusController(this.k8s, SarSysOpsConfig config)
      : ports = {
          'sarsys-app-server': config.app.port,
          'sarsys-tracking-server': config.tracking.healthPort,
        },
        super(
          'Module',
          config,
          [
            'sarsys-app-server',
            'sarsys-tracking-server',
          ],
          options: ['metrics'],
          tag: 'System service',
        );

  final K8sApi k8s;
  final Map<String, int> ports;
  final HttpClient client = HttpClient();

  @override
  @Operation.get()
  Future<Response> getAll({
    @Bind.query('expand') String expand,
  }) {
    return super.getAll(expand: expand);
  }

  @override
  @Operation.get('type')
  Future<Response> getByType(
    @Bind.path('type') String type, {
    @Bind.query('expand') String expand,
  }) =>
      super.getByType(type, expand: expand);

  @override
  Future<Map<String, dynamic>> doGetByType(String type, String expand) async {
    final pods = await k8s.getPodList(
      k8s.namespace,
      labels: [
        'module=$type',
      ],
      metrics: shouldExpand(expand, 'metrics'),
    );
    return {
      'name': type,
      'instances': await _toInstanceListStatus(
        type,
        pods,
      ),
    };
  }

  @override
  @Operation.get('type', 'name')
  Future<Response> getByTypeAndName(
    @Bind.path('type') String type,
    @Bind.path('name') String name, {
    @Bind.query('expand') String expand,
  }) =>
      super.getByTypeAndName(type, name, expand: expand);

  @override
  Future<Map<String, dynamic>> doGetByTypeAndName(String type, String name, String expand) async {
    final pods = await k8s.getPodList(
      k8s.namespace,
      name: name,
      labels: [
        'module=$type',
      ],
      metrics: shouldExpand(expand, 'metrics'),
    );
    return pods.isEmpty ? null : await _toInstanceStatus(type, pods.first);
  }

  Future<List<Map<String, dynamic>>> _toInstanceListStatus(String type, List<Map<String, dynamic>> pods) async {
    final instances = <Map<String, dynamic>>[];
    for (var pod in pods) {
      instances.add(await _toInstanceStatus(type, pod));
    }
    return instances.toList();
  }

  Future<Map<String, dynamic>> _toInstanceStatus(String type, Map<String, dynamic> pod) async {
    return {
      'name': pod.elementAt('metadata/name'),
      'status': await _toPodStatus(type, pod),
      if (pod.hasPath('metrics')) 'metrics': toPodMetrics(type, pod),
    };
  }

  Future<Map<String, dynamic>> _toInstanceHealth(String type, Map<String, dynamic> pod) async {
    return {
      'alive': await _isOK(type, pod, '/api/healthz/alive'),
      'ready': await _isOK(type, pod, '/api/healthz/ready'),
    };
  }

  Future<bool> _isOK(String type, Map<String, dynamic> pod, String uri) async {
    final url = k8s.toPodUri(
      pod,
      uri: uri,
      deployment: type,
      port: ports[type],
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

  Future<Map<String, dynamic>> _toPodStatus(String type, Map<String, dynamic> pod) async {
    final conditions = pod.listAt(
      'status/conditions',
      defaultList: [],
    ).map((c) => Map<String, dynamic>.from(c));

    return {
      'health': await _toInstanceHealth(
        type,
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
