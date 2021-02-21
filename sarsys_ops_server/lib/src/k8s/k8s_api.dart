import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:sarsys_ops_server/sarsys_ops_server.dart';
import 'package:stack_trace/stack_trace.dart';

class K8sApi {
  K8sApi({
    HttpClient client,
    String serviceAccountPath = '/var/run/secrets/kubernetes.io/serviceaccount',
  })  : _client = client,
        serviceAccountPath = serviceAccountPath;

  String serviceAccountPath;
  final logger = Logger('$K8sApi');

  File get tokenFile => File('$serviceAccountPath/token');
  File get certFile => File('$serviceAccountPath/ca.crt');
  File get namespaceFile => File('$serviceAccountPath/namespace');
  Directory get serviceAccountDir => Directory(serviceAccountPath);
  bool get isAuthorized => tokenFile.existsSync() && certFile.existsSync();
  String get namespace => Platform.environment['POD_NAMESPACE']?.isNotEmpty == true
      ? Platform.environment['POD_NAMESPACE']
      : (namespaceFile.existsSync() ? namespaceFile.readAsStringSync() : 'default');

  HttpClient get client {
    if (certFile.existsSync()) {
      SecurityContext.defaultContext.setClientAuthorities('$serviceAccountPath/ca.crt');
    }
    return _client ??= HttpClient(
      context: SecurityContext.defaultContext,
    )..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }

  set client(HttpClient client) => _client = client;
  HttpClient _client;

  String get token {
    if (tokenFile.existsSync()) {
      return tokenFile.readAsStringSync();
    }
    return null;
  }

  String get apiHost => 'kubernetes.default.svc';

  int get apiPort {
    return int.parse(Platform.environment['KUBERNETES_SERVICE_PORT_HTTPS'] ?? '443');
  }

  Future<bool> checkApi() async {
    var ok = false;
    try {
      _check(
        'checkApi',
        certFile.existsSync(),
        ifOK: () => 'CERT: Found',
        ifNotOK: () => 'CERT: Not found',
      );

      _check(
        'checkApi',
        tokenFile.existsSync(),
        ifOK: () => 'TOKEN: Found',
        ifNotOK: () => 'TOKEN: Not found',
      );

      final response = await getUri('/api');
      ok = null != await toContent(response);
      _fine('checkApi', ['Got content: $ok']);
    } on Exception catch (error, stackTrace) {
      _severe('checkApi', error, stackTrace, [
        'namespace: $namespace',
        'isAuthorized: $isAuthorized',
      ]);
    }
    _info(
      'checkApi',
      ['API Metrics...${ok ? 'OK' : 'FAILED'}'],
    );

    return ok;
  }

  Future<bool> checkMetricsApi() async {
    var ok = false;

    try {
      _check(
        'checkApi',
        certFile.existsSync(),
        ifOK: () => 'CERT: Found',
        ifNotOK: () => 'CERT: Not found',
      );

      _check(
        'checkApi',
        tokenFile.existsSync(),
        ifOK: () => 'TOKEN: Found',
        ifNotOK: () => 'TOKEN: Not found',
      );

      final response = await getUri('/apis/metrics.k8s.io/v1beta1');
      ok = null != await toContent(response);
      _info('checkMetricsApi', ['Got content: $ok']);
    } on Exception catch (error, stackTrace) {
      _severe('checkMetricsApi', error, stackTrace, [
        'namespace: $namespace',
        'isAuthorized: $isAuthorized',
      ]);
    }
    _info(
      'checkMetricsApi',
      ['API Metrics...${ok ? 'OK' : 'FAILED'}'],
    );

    return ok;
  }

  Uri toPodUri(
    Map<String, dynamic> pod, {
    String uri,
    int port = 80,
    String deployment,
    String scheme = 'http',
    String deploymentLabel = 'module',
  }) {
    deployment ??= pod.elementAt<String>('metadata/labels/$deploymentLabel');
    if (deployment == null) {
      throw Exception('Pod does not contain deployment label with key '
          '$deploymentLabel: ${pod.mapAt('metadata/labels')}');
    }
    // Base Url is given by pattern 'pod-name.deployment-name.my-namespace.svc.cluster.local'
    final baseUrl = '$scheme://${pod.elementAt('metadata/name')}.'
        '${deployment}.${pod.elementAt('metadata/namespace')}.svc.cluster.local:$port';
    _fine('toPodUri', [
      'Base url is $baseUrl',
      'namespace: $namespace',
      'isAuthorized: $isAuthorized',
    ]);
    if (uri == null || uri.isEmpty) {
      return Uri.parse(baseUrl);
    }
    return Uri.parse(uri.startsWith('/') ? '$baseUrl$uri' : '$baseUrl/$uri');
  }

  Future<Map<String, dynamic>> getPod(
    String ns,
    String name,
  ) async {
    final args = [
      'namespace: $ns',
      'name: $name',
      'isAuthorized: $isAuthorized',
    ];
    return getFromUri<Map<String, dynamic>>(
      'getPod',
      '/api/v1/namespaces/$ns/pods/$name',
      args: args,
    );
  }

  Future<List<Map<String, dynamic>>> getPodList(
    String ns, {
    String name,
    bool metrics = false,
    List<String> labels = const [],
  }) async {
    final labelSelector = labels?.join(',');
    final query = labels.isEmpty ? '' : '?labelSelector=${Uri.encodeQueryComponent(labelSelector)}';
    final args = [
      'namespace: $ns',
      if (name != null) 'name: $name',
      'metrics: $metrics',
      'isAuthorized: $isAuthorized',
      'labelSelector: $labelSelector',
    ];
    final pods = await getListFromUri<Map<String, dynamic>>(
      'getPodList',
      '/api/v1/namespaces/$ns/pods$query',
      name: name,
      args: args,
    );
    if (metrics) {
      for (var pod in pods) {
        pod['metrics'] = await getPodMetrics(
          ns,
          toPodName(pod),
        );
      }
    }
    return pods;
  }

  Future<List<Map<String, dynamic>>> getNodeList({
    String name,
    bool metrics = false,
    List<String> labels = const [],
  }) async {
    final labelSelector = labels?.join(',');
    final query = labels.isEmpty ? '' : '?labelSelector=${Uri.encodeQueryComponent(labelSelector)}';
    final args = [
      if (name != null) 'name: $name',
      'metrics: $metrics',
      'isAuthorized: $isAuthorized',
      'labelSelector: $labelSelector',
    ];
    final nodes = await getListFromUri<Map<String, dynamic>>(
      'getNodeList',
      '/api/v1/nodes$query',
      name: name,
      args: args,
    );
    if (metrics) {
      for (var node in nodes) {
        node['metrics'] = await getNodeMetrics(
          toNodeName(node),
        );
      }
    }
    return nodes;
  }

  Future<List<Map<String, dynamic>>> getNodeMetricsList({
    String name,
    List<String> labels = const [],
  }) {
    final labelSelector = labels?.join(',');
    final query = labels.isEmpty ? '' : '?labelSelector=${Uri.encodeQueryComponent(labelSelector)}';
    final args = [
      if (name != null) 'name: $name',
      'isAuthorized: $isAuthorized',
      'labelSelector: $labelSelector',
    ];
    return getListFromUri<Map<String, dynamic>>(
      'getNodeMetricsList',
      '/apis/metrics.k8s.io/v1beta1/nodes$query',
      name: name,
      args: args,
    );
  }

  Future<Map<String, dynamic>> getNodeMetrics(String name) async {
    final args = [
      'name: $name',
      'isAuthorized: $isAuthorized',
    ];
    return getFromUri<Map<String, dynamic>>(
      'getNodeMetrics',
      '/apis/metrics.k8s.io/v1beta1/nodes/$name',
      args: args,
    );
  }

  Future<List<Map<String, dynamic>>> getPodMetricsList(
    String ns, {
    String name,
    List<String> labels = const [],
  }) {
    final labelSelector = labels?.join(',');
    final query = labels.isEmpty ? '' : '?labelSelector=${Uri.encodeQueryComponent(labelSelector)}';
    final args = [
      if (name != null) 'name: $name',
      'isAuthorized: $isAuthorized',
      'labelSelector: $labelSelector',
    ];
    return getListFromUri<Map<String, dynamic>>(
      'getPodMetricsList',
      '/apis/metrics.k8s.io/v1beta1/namespaces/$ns/pods$query',
      name: name,
      args: args,
    );
  }

  Future<Map<String, dynamic>> getPodMetrics(String ns, String name) async {
    final args = [
      'namespace: $ns',
      'name: $name',
      'isAuthorized: $isAuthorized',
    ];
    return getFromUri<Map<String, dynamic>>(
      'getPodMetrics',
      '/apis/metrics.k8s.io/v1beta1/namespaces/$ns/pods/$name',
      args: args,
    );
  }

  String toPodName(Map<String, dynamic> pod) => pod.elementAt<String>('metadata/name');
  String toNodeName(Map<String, dynamic> node) => node.elementAt<String>('metadata/name');

  Future<HttpClientResponse> getUri(String uri) async {
    final url = Uri.parse('https://$apiHost:$apiPort$uri');
    return getUrl(
      url,
      authenticate: true,
    );
  }

  Future<HttpClientResponse> getUrl(
    Uri url, {
    bool authenticate = true,
  }) async {
    final request = await client.getUrl(url);
    _fine('getUrl', ['${request.method} ${request.uri} > REQUESTED']);
    if (isAuthorized && authenticate) {
      request.headers.add('Authorization', 'Bearer $token');
    }
    final response = await request.close();
    if (response.statusCode < 400) {
      _fine(
        'getUrl',
        ['${request.method} ${request.uri} ${response.statusCode} ${response.reasonPhrase}'],
      );
    } else {
      _warning(
        'getUrl',
        ['${request.method} ${request.uri} ${response.statusCode} ${response.reasonPhrase}'],
      );
    }
    return response;
  }

  Future<T> getFromUri<T>(
    String method,
    String uri, {
    String name,
    List<String> args = const [],
    T Function(Map<String, dynamic>) map,
  }) async {
    map ??= (item) => item as T;
    try {
      _fine(method, args);
      final response = await getUri(uri);
      final content = Map<String, dynamic>.from(await toContent(
        response,
        defaultValue: {},
      ));
      _finer(method, [...args, 'result: $content']);
      return map(content);
    } catch (error, stackTrace) {
      _severe(method, error, stackTrace, args);
      rethrow;
    }
  }

  Future<List<T>> getListFromUri<T>(
    String method,
    String uri, {
    String name,
    List<String> args = const [],
    T Function(Map<String, dynamic>) map,
  }) async {
    final items = <T>[];
    map ??= (item) => item as T;
    try {
      _fine(method, args);
      final response = await getUri(uri);
      final json = Map<String, dynamic>.from(
        await toContent(response, defaultValue: {}),
      );
      final found = json.listAt<Map<String, dynamic>>('items');
      _fine(method, ['$uri found ${found.length} items', ...args]);
      if (found != null) {
        items.addAll(
          found.where((item) => name == null || item.elementAt('metadata/name') == name).map(map),
        );
      }
      _finer(method, [...args, 'result: $items']);
      return items;
    } catch (error, stackTrace) {
      _severe(method, error, stackTrace, args);
      rethrow;
    }
  }

  void _check(
    String method,
    bool isOK, {
    @required String Function() ifOK,
    @required String Function() ifNotOK,
    List<String> args = const [],
  }) {
    if (isOK) {
      _info(method, [ifOK(), ...args]);
    } else {
      _warning(method, [ifNotOK(), ...args]);
    }
  }

  void _info(String method, [List<String> args]) {
    logger.info(Context.toMethod(method, args));
  }

  void _warning(String method, [List<String> args]) {
    logger.warning(Context.toMethod(method, args));
  }

  void _fine(String method, [List<String> args]) {
    logger.fine(Context.toMethod(method, args));
  }

  void _finer(String method, [List<String> args]) {
    logger.finer(Context.toMethod(method, args));
  }

  void _severe(String method, Object error, StackTrace stackTrace, [List<String> args]) {
    logger.severe(
      Context.toMethod(method, args),
      error,
      Trace.from(stackTrace ?? Trace.current(1)),
    );
  }

  static Future toContent(HttpClientResponse response, {dynamic defaultValue}) async {
    final completer = Completer<String>();
    final contents = StringBuffer();
    if (response.statusCode < 300) {
      response.transform(utf8.decoder).listen(
            contents.write,
            onDone: () => completer.complete(contents.toString()),
          );
      final json = await completer.future;
      return jsonDecode(json);
    }
    return defaultValue;
  }
}
