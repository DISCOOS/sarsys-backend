import 'package:sarsys_ops_server/sarsys_ops_server.dart';
import 'package:sarsys_ops_server/src/config.dart';
import 'package:sarsys_ops_server/src/controllers/status_base_controller.dart';

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
  @Operation.get('name')
  Future<Response> getByName(
    @Bind.path('name') String name, {
    @Bind.query('expand') String expand,
  }) =>
      super.getByName(name, expand: expand);

  @override
  Future<Map<String, dynamic>> doGetByName(String name, String expand) async {
    final pods = await k8s.getPodList(
      k8s.namespace,
      labels: [
        'module=$name',
      ],
      metrics: shouldExpand(expand, 'metrics'),
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
        if (pod.hasPath('metrics')) 'metrics': _toPodMetrics(name, pod),
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

  Map<String, dynamic> _toPodMetrics(String name, Map<String, dynamic> pod) {
    final metrics = Map<String, dynamic>.from(pod['metrics'])
      ..removeWhere((key, _) => const [
            'kind',
            'metadata',
            'apiVersion',
            'containers',
          ].contains(key));

    return metrics
      ..putIfAbsent(
        'usage',
        () => _toPodUsage(name, pod),
      )
      ..putIfAbsent(
        'limits',
        () => _toPodLimits(name, pod),
      )
      ..putIfAbsent(
        'requests',
        () => _toPodRequests(name, pod),
      );
  }

  Map<String, dynamic> _toPodUsage(
    String name,
    Map<String, dynamic> pod,
  ) {
    return pod
            .listAt<Map>(
              'metrics/containers',
              defaultList: [],
            )
            .where((c) => c['name'] == name)
            .map((c) => Map<String, dynamic>.from(c['usage']))
            .firstOrNull ??
        <String, dynamic>{};
  }

  Map<String, dynamic> _toPodLimits(
    String name,
    Map<String, dynamic> pod,
  ) {
    return pod
            .listAt<Map>(
              'spec/containers',
              defaultList: [],
            )
            .where((c) => c['name'] == name)
            .map((c) => c.mapAt<String, dynamic>('resources/limits'))
            .firstOrNull ??
        <String, dynamic>{};
  }

  Map<String, dynamic> _toPodRequests(
    String name,
    Map<String, dynamic> pod,
  ) {
    return pod
            .listAt<Map>(
              'spec/containers',
              defaultList: [],
            )
            .where((c) => c['name'] == name)
            .map((c) => c.mapAt<String, dynamic>('resources/requests'))
            .firstOrNull ??
        <String, dynamic>{};
  }

  //////////////////////////////////
  // Documentation
  //////////////////////////////////

  @override
  APISchemaObject documentStatusType(APIDocumentContext context) => documentModuleStatus();
}
