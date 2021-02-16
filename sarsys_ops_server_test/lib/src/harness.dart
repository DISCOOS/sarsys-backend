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

  SarSysTrackingServer get trackingServer => _trackingHarness?.server;
  EventStoreMockServer get esServer => _trackingHarness?.eventStoreMockServer;
  SarSysTrackingServiceClient get trackingClient => _trackingHarness?.grpcClient;
  SarSysTrackingHarness _trackingHarness;

  /// Get mocked [K8sApi]
  K8sApi get k8sMockApi => _k8sMockApi;
  _K8sMockApi _k8sMockApi;

  String get namespace => _namespace;
  String _namespace;
  List<String> get instances => _instances;
  List<String> _instances;

  SarSysOpsHarness withModules({
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
      ..withEventStoreMock()
      ..withLogger(debug: debug)
      ..withGrpcClient(port: grpcPort);

    _namespace = namespace;
    _instances = instances;
    _context['DATA_PATH'] ??= testDataPath;

    _k8sMockApi = _K8sMockApi(
      'localhost',
      grpcPort,
      // K8sApi.namespace fetches from
      // env, which is null during testing
      _namespace,
      // Mocked instances
      instances,
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
    assert(channel.router.getContexts().isEmpty, 'Contexts should be empty');
    return super.stop();
  }
}

class _K8sMockApi extends K8sApi {
  _K8sMockApi(
    this.host,
    this.port,
    String namespace,
    List<String> names,
    String serviceAccountPath,
  ) : super(
          client: _K8sMockClient(namespace, names),
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
    this.namespace,
    this.names,
  );

  final String namespace;
  final List<String> names;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    if (url.path.endsWith('/api')) {
      return _K8sMockGetApiClientRequest(url);
    } else if (url.path.endsWith('/api/v1/namespaces/$namespace/pods') && url.query.isEmpty) {
      return _K8sMockGetPodsFromNsClientRequest(
        url,
        'GET',
        namespace,
        names,
        [],
      );
    } else if (url.path.endsWith('/api/v1/namespaces/$namespace/pods') && url.query.startsWith('labelSelector=')) {
      final labels = Uri.decodeQueryComponent(url.query.split('?labelSelector=').last).split(',');
      return _K8sMockGetPodsFromNsClientRequest(
        url,
        'GET',
        namespace,
        names,
        labels,
      );
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
}

class _K8sMockGetPodsFromNsClientRequest extends _K8sMockClientRequest {
  _K8sMockGetPodsFromNsClientRequest(
    Uri uri,
    String method,
    String namespace,
    List<String> names,
    List<String> labelSelectors,
  ) : super(
            uri,
            method,
            _K8sMockClientResponse.ok({
              'items': names
                  .where((name) => isLabelMatch(labelSelectors, name))
                  .map((name) => {
                        'metadata': {
                          'name': name,
                          'namespace': namespace,
                          'labels': {'module': _toModule(name)}
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
                      })
                  .toList(),
            }));

  static String _toModule(String name) {
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
    final module = _toModule(name);
    return labelSelectors.any(
      (selector) => selector.endsWith(module),
    );
  }
}

class _K8sMockGetApiClientRequest extends _K8sMockClientRequest {
  _K8sMockGetApiClientRequest(Uri uri) : super(uri, 'GET', _K8sMockClientResponse.ok([]));
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
