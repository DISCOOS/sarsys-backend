import 'dart:convert';
import 'dart:io';

import 'package:aqueduct_test/aqueduct_test.dart';
import 'package:event_source_test/event_source_test.dart';
import 'package:grpc/grpc.dart';
import 'package:hive/hive.dart';
import 'package:path/path.dart' as p;
import 'package:mockito/mockito.dart';
import 'package:sarsys_domain/sarsys_domain.dart';
import 'package:sarsys_http_core/sarsys_http_core.dart';

import 'package:sarsys_ops_server/sarsys_ops_channel.dart';
import 'package:sarsys_ops_server/sarsys_ops_server.dart';
import 'package:sarsys_ops_server/src/config.dart';
import 'package:sarsys_tracking_server/sarsys_tracking_server.dart';
import 'package:test/test.dart';

class SarSysOpsHarness extends TestHarness<SarSysOpsServerChannel> {
  static const testDataPath = 'test/.hive';
  static const sub = _SarSysTrackingHarness.sub;
  static const group = _SarSysTrackingHarness.group;
  static const trackingInstance0 = 'sarsys-tracking-server-0';

  SarSysTrackingServer get trackingServer => _trackingHarness?.server;
  EventStoreMockServer get esServer => _trackingHarness?.eventStoreMockServer;
  SarSysTrackingServiceClient get trackingClient => _trackingHarness?.grpcClient;
  _SarSysTrackingHarness _trackingHarness;

  HttpClient get k8sMockClient => _k8sMockClient;
  HttpClient _k8sMockClient;

  String get namespace => _namespace;
  String _namespace;

  SarSysOpsHarness withK8sMockClient({
    String namespace = 'sarsys',
    List<String> instances = const [trackingInstance0],
  }) {
    _namespace = namespace;
    _k8sMockClient = _K8sMockClient(
      // K8sApi.namespace fetches from
      // env, which is null during testing
      _namespace,
      // Default
      instances,
    );
    _context['DATA_PATH'] ??= testDataPath;
    return this;
  }

  SarSysOpsHarness withTrackingServer({
    bool debug = false,
    int grpcPort = 8083,
    int healthPort = 8084,
  }) {
    _trackingHarness = _SarSysTrackingHarness()
      ..withTenant()
      ..withPrefix()
      ..withServerPorts(
        grpcPort: grpcPort,
        healthPort: healthPort,
      )
      ..withEventStoreMock()
      ..withLogger(debug: debug)
      ..withGrpcClient(port: grpcPort);
    _context.addAll({
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
      SarSysOpsConfig(file).tracking,
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
        serviceAccountNsFile.writeAsString(_namespace);
      }
    }
  }

  @override
  Future afterStart() async {
    if (_k8sMockClient != null) {
      channel.k8s
        ..client = _k8sMockClient
        ..serviceAccountPath = p.join(
          _context['DATA_PATH'] as String,
          'serviceaccount',
        );
    }
  }

  @override
  Future stop() async {
    await _deleteTestData();
    assert(channel.router.getContexts().isEmpty, 'Contexts should be empty');
    return super.stop();
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

class _SarSysTrackingHarness {
  static const sub = '\$et-TrackingCreated';
  static const group = 'TrackingService';

  SarSysTrackingServer server;
  HttpClient httpClient = HttpClient();
  EventStoreMockServer eventStoreMockServer;

  String _tenant;
  String get tenant => _tenant;
  _SarSysTrackingHarness withTenant({String tenant = 'discoos'}) {
    _tenant = tenant;
    return this;
  }

  String _prefix;
  String get prefix => _prefix;
  _SarSysTrackingHarness withPrefix({String prefix = 'test'}) {
    _prefix = prefix;
    return this;
  }

  int get healthPort => _healthPort;
  int _healthPort = 8082;

  int get grpcPort => _grpcPort;
  int _grpcPort = 8083;

  _SarSysTrackingHarness withServerPorts({
    int healthPort = 8082,
    int grpcPort = 8083,
  }) {
    assert(_grpcChannel == null, 'withGrpc is already configured');
    _grpcPort = grpcPort;
    _healthPort = healthPort;
    return this;
  }

  bool _startup = false;
  _SarSysTrackingHarness withStartupOnBuild() {
    _startup = true;
    return this;
  }

  ClientChannel get grpcChannel => _grpcChannel;
  ClientChannel _grpcChannel;
  SarSysTrackingServiceClient get grpcClient => _grpcClient;
  SarSysTrackingServiceClient _grpcClient;
  _SarSysTrackingHarness withGrpcClient({int port = 8083}) {
    _grpcChannel = ClientChannel(
      '127.0.0.1',
      port: _grpcPort = port,
      options: const ChannelOptions(
        credentials: ChannelCredentials.insecure(),
      ),
    );
    _grpcClient = SarSysTrackingServiceClient(
      grpcChannel,
      options: CallOptions(
        timeout: const Duration(
          seconds: 30,
        ),
      ),
    );
    return this;
  }

  _SarSysTrackingHarness withLogger({bool debug = false}) {
    if (debug) {
      Logger.root.level = Level.FINE;
    }
    return this;
  }

  EventStoreMockServer withEventStoreMock() => eventStoreMockServer = EventStoreMockServer(
        _tenant,
        _prefix,
        4000,
      );

  void install(SarSysTrackingConfig config) {
    config.grpcPort = _grpcPort;
    config.healthPort = _healthPort;
    config.prefix = _prefix;
    config.tenant = _tenant;
    config.startup = _startup;
    config.logging.stdout = false;

    setUpAll(
      () async => await eventStoreMockServer.open(),
    );

    setUp(() async {
      assert(server == null);
      assert(eventStoreMockServer != null, 'Forgot to call withEventStoreMock()?');

      // Define required projections, streams and subscriptions
      eventStoreMockServer
        ..withProjection('\$by_category')
        ..withProjection('\$by_event_type')
        ..withStream(typeOf<Device>().toColonCase())
        ..withStream(typeOf<Tracking>().toColonCase())
        ..withStream(sub, useInstanceStreams: false, useCanonicalName: false)
        ..withSubscription(sub, group: group);

      server = SarSysTrackingServer();
      await server.start(
        config,
      );
      // Assert that all repos have a stream
      final missing = <String>[];
      for (var repo in server.manager.repos) {
        if (!eventStoreMockServer.hasStream(repo.aggregateType.toColonCase())) {
          missing.add(repo.aggregateType.toString());
        }
      }
      if (missing.isNotEmpty) {
        throw 'Following streams are not defined: \n\n'
            '   $missing\n\n'
            '>> Add missing stream(s) to SarSysHarness.onSetUp()';
      }
      return server.manager.readyAsync();
    });

    tearDown(() async {
      await server?.stop();
      server = null;
      eventStoreMockServer?.clear();
      return await Hive.deleteFromDisk();
    });

    tearDownAll(
      () => eventStoreMockServer.close(),
    );
  }
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
