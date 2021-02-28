import 'dart:convert';
import 'dart:io';

import 'package:aqueduct_test/aqueduct_test.dart';
import 'package:event_source_test/event_source_test.dart';
import 'package:hive/hive.dart';
import 'package:path/path.dart' as p;
import 'package:mockito/mockito.dart';
import 'package:sarsys_domain/sarsys_domain.dart';
import 'package:sarsys_core/sarsys_core.dart';

import 'package:sarsys_ops_server/sarsys_ops_channel.dart';
import 'package:sarsys_ops_server/sarsys_ops_server.dart';
import 'package:sarsys_ops_server/src/config.dart';
import 'package:sarsys_tracking_server/sarsys_tracking_server.dart';
import 'package:sarsys_tracking_server_test/sarsys_tracking_server_test.dart';

class SarSysOpsHarness extends TestHarness<SarSysOpsServerChannel> {
  static const testDataPath = 'test/.hive';
  static const sub = SarSysTrackingHarness.sub;
  static const group = SarSysTrackingHarness.group;
  static const trackingInstance0 = 'sarsys-tracking-server-0';

  final EventStoreMockServer _eventStoreMockServer = EventStoreMockServer(
    'discoos',
    'test',
    4000,
  );

  SarSysTrackingServer get trackingServer => _trackingHarness?.server;
  EventStoreMockServer get eventStoreServer => _trackingHarness?.eventStoreMockServer;
  SarSysTrackingServiceClient get trackingClient => _trackingHarness?.grpcClient;
  SarSysTrackingHarness _trackingHarness;

  /// Get mocked [K8sApi]
  K8sApi get k8sMockApi => _k8sMockApi;
  _K8sMockApi _k8sMockApi;

  String get namespace => _namespace;
  String _namespace;
  List<String> get instances => _instances;
  List<String> _instances;

  SarSysOpsHarness withSnapshots({
    int threshold = 100,
    int keep = 10,
    bool automatic = true,
  }) {
    assert(_trackingHarness != null, 'withTrackingServer() is not called');
    _trackingHarness.withSnapshots(
      keep: keep,
      automatic: automatic,
      threshold: threshold,
    );
    return this;
  }

  SarSysOpsHarness withTrackingServer({
    bool debug = false,
    int grpcPort = 8083,
    int healthPort = 8084,
    String namespace = 'sarsys',
    List<String> instances = const [trackingInstance0],
  }) {
    _trackingHarness = SarSysTrackingHarness()
      ..withTenant()
      ..withPrefix()
      ..withServerPorts(
        grpcPort: grpcPort,
        healthPort: healthPort,
      )
      ..withEventStoreMock(_eventStoreMockServer)
      ..withLogger(debug: debug)
      ..withGrpcClient(port: grpcPort);

    _namespace = namespace;
    _instances = instances;
    _context['DATA_PATH'] ??= testDataPath;

    _k8sMockApi = _K8sMockApi(
      'localhost',
      grpcPort,
      // Module is required for metrics lookup
      'sarsys-tracking-server',
      // K8sApi.namespace fetches from
      // env, which is null during testing
      _namespace,
      // Mocked pods
      instances,
      // Mocked nodes
      ['node-1'],
      // Path to mocked service account
      p.join(_context['DATA_PATH'] as String, 'serviceaccount'),
    );
    _context.addAll({
      'K8S_API': _k8sMockApi,
      'TRACKING_SERVER_GRPC_PORT': _trackingHarness.grpcPort,
      'TRACKING_SERVER_HEALTH_PORT': _trackingHarness.healthPort,
    });
    return this;
  }

  SarSysOpsHarness withLogger({bool debug = false}) {
    if (debug) {
      Logger.root.level = Level.FINE;
    }
    return this;
  }

  final Map<String, dynamic> _context = {};
  SarSysOpsHarness withContext({
    String podName = 'bar',
    String apiSpecPath,
    String dataPath = testDataPath,
  }) {
    _context.addAll({
      if (podName != null) 'POD_NAME': podName,
      if (dataPath != null) 'DATA_PATH': dataPath,
      if (apiSpecPath != null) 'API_SPEC_PATH': apiSpecPath,
    });
    return this;
  }

  @override
  void install({
    String file = 'config.src.yaml',
    bool restartForEachTest = false,
  }) {
    options.configurationFilePath = file;
    _trackingHarness?.install(
      config: SarSysOpsConfig(file).tracking,
    );
    super.install(
      restartForEachTest: restartForEachTest,
    );
  }

  @override
  Future beforeStart() async {
    await _deleteTestData();
    _configureContext(application);
  }

  Future _deleteTestData() async {
    await Hive.deleteFromDisk();
    final dataPath = Directory((_context['DATA_PATH'] ?? testDataPath) as String);
    if (dataPath.existsSync()) {
      dataPath.deleteSync(recursive: true);
    }
  }

  void _configureContext(Application application) {
    application.options.context.addAll(_context);
    if (_context.containsKey('DATA_PATH')) {
      final dataDir = Directory(_context['DATA_PATH'] as String);
      if (!dataDir.existsSync()) {
        dataDir.createSync(recursive: true);
      }
      final serviceAccountDir = Directory(p.join(dataDir.path, 'serviceaccount'));
      if (!serviceAccountDir.existsSync()) {
        serviceAccountDir.createSync(recursive: true);
      }
      final serviceAccountNsFile = File(p.join(serviceAccountDir.path, 'namespace'));
      if (!serviceAccountNsFile.existsSync()) {
        serviceAccountNsFile.createSync(recursive: true);
      }
      serviceAccountNsFile.writeAsStringSync(_namespace);
    }
  }

  @override
  Future stop() async {
    await _deleteTestData();
    assert(
      SecureRouter.getContexts().isEmpty,
      'Contexts should be empty',
    );
    return super.stop();
  }
}

class _K8sMockApi extends K8sApi {
  _K8sMockApi(
    this.host,
    this.port,
    String module,
    String namespace,
    List<String> pods,
    List<String> nodes,
    String serviceAccountPath,
  ) : super(
          client: _K8sMockClient(
            namespace,
            pods: pods,
            nodes: nodes,
            module: module,
          ),
          serviceAccountPath: serviceAccountPath,
        );

  final String host;
  final int port;

  @override
  Uri toPodUri(
    Map<String, dynamic> pod, {
    String uri,
    int port = 80,
    String deployment,
    String scheme = 'http',
    String deploymentLabel = 'module',
  }) {
    return Uri.parse('http://$host:$port');
  }
}

/// [HttpClient] mock for [K8sApi]
class _K8sMockClient extends Fake implements HttpClient {
  _K8sMockClient(
    this.namespace, {
    @required this.module,
    @required this.pods,
    @required this.nodes,
  });

  final String module;
  final String namespace;
  final List<String> pods;
  final List<String> nodes;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    // API server?
    if (!url.path.startsWith('/apis')) {
      // checkApi?
      if (url.path.endsWith('/api')) {
        return _K8sMockGetClientRequest(url);
      }

      // getNodeList?
      if (url.path.endsWith('/api/v1/nodes')) {
        if (url.query.startsWith('labelSelector=')) {
          final labels = Uri.decodeQueryComponent(url.query.split('?labelSelector=').last).split(',');
          return _K8sMockGetNodeListClientRequest(url, 'GET', nodes, labels);
        }
        return _K8sMockGetNodeListClientRequest(url, 'GET', nodes, []);
      }

      // getNode?
      if (url.path.startsWith('/api/v1/nodes/')) {
        final name = url.pathSegments.last;
        if (pods.contains(name)) {
          return _K8sMockGetNodeClientRequest(url, 'GET', name);
        }
      }

      // getPodList?
      if (url.path.endsWith('/api/v1/namespaces/$namespace/pods')) {
        if (url.query.startsWith('labelSelector=')) {
          final labels = Uri.decodeQueryComponent(url.query.split('?labelSelector=').last).split(',');
          return _K8sMockGetPodListClientRequest(url, 'GET', module, namespace, pods, labels);
        }
        return _K8sMockGetPodListClientRequest(url, 'GET', module, namespace, pods, []);
      }

      // getPod?
      if (url.path.startsWith('/api/v1/namespaces/$namespace/pods/')) {
        final name = url.pathSegments.last;
        if (pods.contains(name)) {
          return _K8sMockGetPodClientRequest(url, 'GET', module, namespace, name);
        }
      }
    } else {
      // checkMetricsApi?
      if (url.path.endsWith('/apis/metrics.k8s.io/v1beta1')) {
        return _K8sMockGetClientRequest(url);
      }

      // getNodeMetricsList?
      if (url.path.endsWith('/apis/metrics.k8s.io/v1beta1/nodes')) {
        if (url.query.startsWith('labelSelector=')) {
          final labels = Uri.decodeQueryComponent(url.query.split('?labelSelector=').last).split(',');
          return _K8sMockGetNodeMetricsListClientRequest(url, 'GET', nodes, labels);
        }
        return _K8sMockGetNodeMetricsListClientRequest(url, 'GET', nodes, []);
      }

      // getNodeMetrics?
      if (url.path.startsWith('/apis/metrics.k8s.io/v1beta1/nodes/')) {
        final name = url.pathSegments.last;
        if (pods.contains(name)) {
          return _K8sMockGetNodeMetricsClientRequest(url, 'GET', name);
        }
      }

      // getPodMetricsList?
      if (url.path.endsWith('/apis/metrics.k8s.io/v1beta1/namespaces/$namespace/pods')) {
        if (url.query.startsWith('labelSelector=')) {
          final labels = Uri.decodeQueryComponent(url.query.split('?labelSelector=').last).split(',');
          return _K8sMockGetPodMetricsListClientRequest(url, 'GET', module, namespace, pods, labels);
        }
        return _K8sMockGetPodMetricsListClientRequest(url, 'GET', module, namespace, pods, []);
      }

      // getPodMetrics?
      if (url.path.startsWith('/apis/metrics.k8s.io/v1beta1/namespaces/$namespace/pods/')) {
        final name = url.pathSegments.last;
        if (pods.contains(name)) {
          return _K8sMockGetPodMetricsClientRequest(url, 'GET', module, namespace, name);
        }
      }
    }

    return _K8sMockClientRequest(
      url,
      'GET',
      _K8sMockClientResponse.notFound(),
    );
  }
}

class _K8sMockClientRequest extends Fake implements HttpClientRequest {
  _K8sMockClientRequest(this.uri, this.method, this.response);

  @override
  final Uri uri;

  @override
  final String method;

  final _K8sMockClientResponse response;

  @override
  Future<HttpClientResponse> close() async {
    return response;
  }

  static String toModule(String name) {
    final parts = name.split('-');
    if (int.tryParse(parts.last) != null) {
      return parts.sublist(0, parts.length - 1).join('-');
    }
    return name;
  }

  static bool isLabelMatch(List<String> labelSelectors, String name) {
    if (labelSelectors.isEmpty) {
      return true;
    }
    final module = toModule(name);
    return labelSelectors.any(
      (selector) => selector.endsWith(module),
    );
  }
}

Map<String, dynamic> _nodeTemplate(String name) => {
      'kind': 'Node',
      'apiVersion': 'v1',
      'metadata': {
        'name': '$name',
        'selfLink': '/api/v1/nodes/$name',
        'labels': {
          'kubernetes.io/arch': 'amd64',
          'kubernetes.io/hostname': '$name',
        },
        'annotations': {}
      },
      'spec': {},
      'status': {
        'capacity': {
          'cpu': '2',
          'ephemeral-storage': '82535812Ki',
          'hugepages-1Gi': '0',
          'hugepages-2Mi': '0',
          'memory': '4041652Ki',
          'pods': '110'
        },
        'allocatable': {
          'cpu': '2',
          'ephemeral-storage': '76065004214',
          'hugepages-1Gi': '0',
          'hugepages-2Mi': '0',
          'memory': '3110Mi',
          'pods': '110'
        },
        'conditions': [
          {
            'type': 'NetworkUnavailable',
            'status': 'False',
            'lastHeartbeatTime': '2021-01-28T12:16:00Z',
            'lastTransitionTime': '2021-01-28T12:16:00Z',
            'reason': 'CiliumIsUp',
            'message': 'Cilium is running on this node'
          },
          {
            'type': 'MemoryPressure',
            'status': 'False',
            'lastHeartbeatTime': '2021-02-21T14:46:14Z',
            'lastTransitionTime': '2020-12-17T21:27:25Z',
            'reason': 'KubeletHasSufficientMemory',
            'message': 'kubelet has sufficient memory available'
          },
          {
            'type': 'DiskPressure',
            'status': 'False',
            'lastHeartbeatTime': '2021-02-21T14:46:14Z',
            'lastTransitionTime': '2020-12-17T21:27:25Z',
            'reason': 'KubeletHasNoDiskPressure',
            'message': 'kubelet has no disk pressure'
          },
          {
            'type': 'PIDPressure',
            'status': 'False',
            'lastHeartbeatTime': '2021-02-21T14:46:14Z',
            'lastTransitionTime': '2020-12-17T21:27:25Z',
            'reason': 'KubeletHasSufficientPID',
            'message': 'kubelet has sufficient PID available'
          },
          {
            'type': 'Ready',
            'status': 'True',
            'lastHeartbeatTime': '2021-02-21T14:46:14Z',
            'lastTransitionTime': '2020-12-17T21:27:36Z',
            'reason': 'KubeletReady',
            'message': 'kubelet is posting ready status'
          }
        ],
        'addresses': [
          {'type': 'Hostname', 'address': 'k8s-4-3vd2w'},
          {'type': 'InternalIP', 'address': '10.131.108.28'},
          {'type': 'ExternalIP', 'address': '178.62.90.162'}
        ],
        'daemonEndpoints': {
          'kubeletEndpoint': {'Port': 10250}
        },
        'nodeInfo': {
          'machineID': '4c30d01c76e44af4a8d9112027ef0890',
          'systemUUID': '4c30d01c-76e4-4af4-a8d9-112027ef0890',
          'bootID': 'be65ad81-1450-4c0c-9486-2f532fe212b8',
          'kernelVersion': '4.19.0-0.bpo.6-amd64',
          'osImage': 'Debian GNU/Linux 10 (buster)',
          'containerRuntimeVersion': 'docker://18.9.2',
          'kubeletVersion': 'v1.16.13',
          'kubeProxyVersion': 'v1.16.13',
          'operatingSystem': 'linux',
          'architecture': 'amd64'
        },
        'images': [
          {
            'names': [
              'discoos/sarsys_tracking_server@sha256:ee1cd9d15e3c3b6d513a495a1673b3e4025197a0e44dde7be6a72ed2f64168ca',
              'discoos/sarsys_tracking_server:latest'
            ],
            'sizeBytes': 710756527
          },
        ],
        'volumesInUse': [],
        'volumesAttached': []
      }
    };

Map<String, dynamic> _nodeMetricsTemplate(String name) => {
      'kind': 'NodeMetrics',
      'apiVersion': 'metrics.k8s.io/v1beta1',
      'metadata': {
        'name': '$name',
        'selfLink': '/apis/metrics.k8s.io/v1beta1/nodes/$name',
        'creationTimestamp': '2021-02-21T15:17:33Z'
      },
      'timestamp': '2021-02-21T15:17:03Z',
      'window': '30s',
      'usage': {'cpu': '465194806n', 'memory': '2228308Ki'}
    };

class _K8sMockGetNodeClientRequest extends _K8sMockClientRequest {
  _K8sMockGetNodeClientRequest(
    Uri uri,
    String method,
    String name,
  ) : super(uri, method, _K8sMockClientResponse.ok(_nodeTemplate(name)));
}

class _K8sMockGetNodeMetricsClientRequest extends _K8sMockClientRequest {
  _K8sMockGetNodeMetricsClientRequest(
    Uri uri,
    String method,
    String name,
  ) : super(uri, method, _K8sMockClientResponse.ok(_nodeMetricsTemplate(name)));
}

class _K8sMockGetNodeListClientRequest extends _K8sMockClientRequest {
  _K8sMockGetNodeListClientRequest(
    Uri uri,
    String method,
    List<String> names,
    List<String> labelSelectors,
  ) : super(
            uri,
            method,
            _K8sMockClientResponse.ok({
              'items': names
                  .where((name) => _K8sMockClientRequest.isLabelMatch(labelSelectors, name))
                  .map((name) => _nodeTemplate(name))
                  .toList(),
            }));
}

class _K8sMockGetNodeMetricsListClientRequest extends _K8sMockClientRequest {
  _K8sMockGetNodeMetricsListClientRequest(
    Uri uri,
    String method,
    List<String> names,
    List<String> labelSelectors,
  ) : super(
            uri,
            method,
            _K8sMockClientResponse.ok({
              'items': names
                  .where((name) => _K8sMockClientRequest.isLabelMatch(labelSelectors, name))
                  .map((name) => _nodeMetricsTemplate(name))
                  .toList(),
            }));
}

Map<String, dynamic> _podTemplate(String module, String ns, String name) => {
      'metadata': {
        'name': name,
        'namespace': ns,
        'labels': {'module': module}
      },
      'status': {
        'conditions': [
          {
            'type': 'Unknown',
            'status': 'Unknown',
            'reason': 'EMPTY_LIST',
            'message': 'No conditions found',
          }
        ],
      },
      'spec': {
        'containers': [
          {
            'name': '$module',
            'resources': {
              'limits': {'cpu': '500m', 'memory': '1200Mi'},
              'requests': {'cpu': '250m', 'memory': '800Mi'}
            },
          },
        ],
      },
    };

Map<String, dynamic> _podMetricsTemplate(String module, String ns, String name) => {
      'kind': 'PodMetrics',
      'apiVersion': 'metrics.k8s.io/v1beta1',
      'metadata': {
        'name': '$name',
        'namespace': '$ns',
        'selfLink': '/apis/metrics.k8s.io/v1beta1/namespaces/sarsys/pods/$name',
        'creationTimestamp': '2021-02-21T15:19:31Z'
      },
      'timestamp': '2021-02-21T15:18:56Z',
      'window': '30s',
      'containers': [
        {
          'name': '$module',
          'usage': {'cpu': '26541495n', 'memory': '917832Ki'}
        }
      ]
    };

class _K8sMockGetPodClientRequest extends _K8sMockClientRequest {
  _K8sMockGetPodClientRequest(
    Uri uri,
    String method,
    String module,
    String ns,
    String name,
  ) : super(uri, method, _K8sMockClientResponse.ok(_podTemplate(module, ns, name)));
}

class _K8sMockGetPodMetricsClientRequest extends _K8sMockClientRequest {
  _K8sMockGetPodMetricsClientRequest(
    Uri uri,
    String method,
    String module,
    String ns,
    String name,
  ) : super(uri, method, _K8sMockClientResponse.ok(_podMetricsTemplate(module, ns, name)));
}

class _K8sMockGetPodListClientRequest extends _K8sMockClientRequest {
  _K8sMockGetPodListClientRequest(
    Uri uri,
    String method,
    String module,
    String ns,
    List<String> names,
    List<String> labelSelectors,
  ) : super(
            uri,
            method,
            _K8sMockClientResponse.ok({
              'items': names
                  .where((name) => _K8sMockClientRequest.isLabelMatch(labelSelectors, name))
                  .map((name) => _podTemplate(module, ns, name))
                  .toList(),
            }));
}

class _K8sMockGetPodMetricsListClientRequest extends _K8sMockClientRequest {
  _K8sMockGetPodMetricsListClientRequest(
    Uri uri,
    String method,
    String module,
    String ns,
    List<String> names,
    List<String> labelSelectors,
  ) : super(
            uri,
            method,
            _K8sMockClientResponse.ok({
              'items': names
                  .where((name) => _K8sMockClientRequest.isLabelMatch(labelSelectors, name))
                  .map((name) => _podMetricsTemplate(module, ns, name))
                  .toList(),
            }));
}

class _K8sMockGetClientRequest extends _K8sMockClientRequest {
  _K8sMockGetClientRequest(Uri uri) : super(uri, 'GET', _K8sMockClientResponse.ok([]));
}

class _K8sMockClientResponse extends Fake implements HttpClientResponse {
  _K8sMockClientResponse(
    this.statusCode,
    this.reasonPhrase, [
    this.content,
  ]);

  final content;

  @override
  final int statusCode;

  @override
  final String reasonPhrase;

  factory _K8sMockClientResponse.ok(dynamic content) => _K8sMockClientResponse(
        HttpStatus.ok,
        'OK',
        content,
      );

  factory _K8sMockClientResponse.notFound() => _K8sMockClientResponse(
        HttpStatus.notFound,
        'Not found',
      );

  @override
  Stream<String> transform<String>(StreamTransformer<List<int>, String> streamTransformer) {
    return streamTransformer.bind(this);
  }

  @override
  StreamSubscription<List<int>> listen(void Function(List<int> event) onData,
      {Function onError, void Function() onDone, bool cancelOnError}) {
    try {
      return _controller.stream.listen(
        onData,
        onDone: onDone,
        cancelOnError: cancelOnError,
      );
    } finally {
      if (content != null) {
        final json = jsonEncode(content);
        _controller.add(
          utf8.encode(json),
        );
      }
      _controller.close();
    }
  }

  final StreamController<List<int>> _controller = StreamController();
}

FutureOr<String> createDevice(DeviceRepository repo) async {
  final uuid = Uuid().v4();
  await repo.execute(CreateDevice({
    'uuid': '$uuid',
  }));
  return uuid;
}

FutureOr<String> createTracking(TrackingRepository repo, TestStream stream, String subscription) async {
  final uuid = Uuid().v4();
  final events = await repo.execute(CreateTracking({
    'uuid': '$uuid',
  }));
  stream.append(subscription, [
    TestStream.fromDomainEvent(events.first),
  ]);
  return uuid;
}
