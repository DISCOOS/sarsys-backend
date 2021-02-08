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
  String get namespace =>
      Platform.environment['POD_NAMESPACE'] ??
      (namespaceFile.existsSync() ? namespaceFile.readAsStringSync() : 'default');

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

  Future<bool> check() async {
    var ok = false;
    logger.info('CERT: ${certFile.existsSync() ? 'Found' : 'Not found'}');
    logger.info('TOKEN: ${tokenFile.existsSync() ? 'Found' : 'Not found'}');
    logger.info('Check...');

    try {
      final response = await getUri('/api');
      logger.info('${response.statusCode} ${response.reasonPhrase}');
      final json = await toContent(response);
      ok = json != null;
      logger.info('Has content: $ok');
    } on Exception catch (error, stackTrace) {
      logger.severe(
        '${Context.toMethod('check', [
          'namespace: $namespace',
          'isAuthorized: $isAuthorized',
        ])}',
        error,
        stackTrace ?? Trace.current(1),
      );
    }
    logger.info('Check...done');

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
    logger.fine(
      '${Context.toMethod('toPodUri', [
        'Base url is $baseUrl',
        'namespace: $namespace',
        'isAuthorized: $isAuthorized',
      ])}',
    );
    if (uri == null || uri.isEmpty) {
      return Uri.parse(baseUrl);
    }
    return Uri.parse(uri.startsWith('/') ? '$baseUrl$uri' : '$baseUrl/$uri');
  }

  Future<List<Map<String, dynamic>>> getPodsFromNs(
    String ns, {
    List<String> labels = const [],
  }) async {
    final pods = <Map<String, dynamic>>[];

    final labelSelector = labels?.join(',');
    final query = labels.isEmpty ? '' : '?labelSelector=${Uri.encodeQueryComponent(labelSelector)}';
    logger.fine(
      '${Context.toMethod('getPodsFromNs', [
        'namespace: $ns',
        'isAuthorized: $isAuthorized',
        'labelSelector: $labelSelector',
      ])}...',
    );
    try {
      final uri = '/api/v1/namespaces/$ns/pods$query';
      final response = await getUri(uri);
      logger.info('$uri ${response.statusCode} ${response.reasonPhrase}');
      final json = Map<String, dynamic>.from(
        await toContent(response, defaultValue: {}),
      );
      logger.fine('$uri Has content ${json.runtimeType}');
      final items = json.listAt('items');
      if (items != null) {
        pods.addAll(
          List<Map<String, dynamic>>.from(items),
        );
      }
      logger.fine(
        '${Context.toMethod('getPodsFromNs', ['result: $pods'])}',
      );
    } catch (error, stackTrace) {
      logger.severe(
        '${Context.toMethod('getPodsFromNs', [
          'namespace: $ns',
          'isAuthorized: $isAuthorized',
          'labelSelector: $labelSelector',
        ])}',
        error,
        stackTrace ?? Trace.current(1),
      );
    }
    logger.fine(
      '${Context.toMethod('getPodsFromNs')}...done',
    );
    return pods;
  }

  String toPodName(Map<String, dynamic> pod) => pod.elementAt<String>('metadata/name');

  Future<List<String>> getPodNamesFromNs(
    String ns, {
    List<String> labels = const [],
  }) async {
    final pods = <String>[];

    final labelSelector = labels?.join(',');
    final query = labels.isEmpty ? '' : '?labelSelector=${Uri.encodeQueryComponent(labelSelector)}';
    logger.fine(
      '${Context.toMethod('getPodNamesFromNs', [
        'namespace: $ns',
        'labelSelector: $labelSelector',
      ])}...',
    );
    try {
      final uri = '/api/v1/namespaces/$ns/pods$query';
      final response = await getUri(uri);
      logger.info('$uri ${response.statusCode} ${response.reasonPhrase}');
      final json = Map<String, dynamic>.from(
        await toContent(response, defaultValue: {}),
      );
      logger.fine('Has content ${json.runtimeType}');
      final items = json.listAt('items');
      if (items != null) {
        pods.addAll(
          items.map(toPodName),
        );
      }
    } catch (error, stackTrace) {
      logger.severe(
        '${Context.toMethod('getPodNamesFromNs', [
          'namespace: $ns',
          'isAuthorized: $isAuthorized',
          'labelSelector: $labelSelector',
        ])}',
        error,
        stackTrace ?? Trace.current(1),
      );
    }
    logger.fine(
      '${Context.toMethod('getPodNamesFromNs', ['result: $pods'])}...done',
    );
    return pods;
  }

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
    logger.fine('request: ${request.method} ${request.uri}');
    if (isAuthorized && authenticate) {
      request.headers.add('Authorization', 'Bearer $token');
    }
    return request.close();
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
