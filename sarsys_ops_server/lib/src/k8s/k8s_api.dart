import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:sarsys_ops_server/sarsys_ops_server.dart';
import 'package:stack_trace/stack_trace.dart';

class K8sApi {
  static const _serviceAccountPath = '/var/run/secrets/kubernetes.io/serviceaccount';
  final logger = Logger('$K8sApi');
  final tokenFile = File('$_serviceAccountPath/token');
  final certFile = File('$_serviceAccountPath/ca.crt');
  final serviceAccountDir = Directory(_serviceAccountPath);
  String get namespace => Platform.environment['POD_NAMESPACE'];
  bool get isReady => tokenFile.existsSync() && certFile.existsSync();

  HttpClient get client {
    if (certFile.existsSync()) {
      SecurityContext.defaultContext.setClientAuthorities('$_serviceAccountPath/ca.crt');
    }
    return _client ??= HttpClient(
      context: SecurityContext.defaultContext,
    )..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }

  HttpClient _client;

  String get token {
    if (tokenFile.existsSync()) {
      return tokenFile.readAsStringSync();
    }
    return null;
  }

  String get apiHost => 'kubernetes.default.svc';

  int get apiPort {
    return int.parse(Platform.environment['KUBERNETES_SERVICE_PORT_HTTPS']);
  }

  Future<bool> check() async {
    var ok = false;
    logger.info('K8S api: CERT: ${certFile.existsSync() ? 'Found' : 'Not found'}');
    logger.info('K8S api: TOKEN: ${tokenFile.existsSync() ? 'Found' : 'Not found'}');

    if (isReady) {
      logger.info('K8S api: Check...');

      try {
        final response = await get('/api');
        logger.info('K8S api: ${response.statusCode} ${response.reasonPhrase}');
        final json = await toContent(response);
        ok = json != null;
        logger.info('K8S api: Has content: $ok');
      } on Exception catch (error, stackTrace) {
        logger.severe(
          'K8S api: error: $error',
          error,
          stackTrace ?? Trace.current(1),
        );
      }
      logger.info('K8S api: Check...done');
    }
    return ok;
  }

  Future<List<String>> getPodNamesFromNs(String ns) async {
    final pods = <String>[];

    if (isReady) {
      logger.fine(
        'K8S api: ${Context.toMethod('getPodNamesFromNs', ['namespace: $ns'])}...',
      );
      try {
        final response = await get('/api/v1/namespaces/$ns/pods');
        logger.info('K8S api: ${response.statusCode} ${response.reasonPhrase}');
        final json = Map<String, dynamic>.from(await toContent(response));
        logger.fine('K8S api: $json');
        final items = json.mapAt<String, Map<String, Map<String, dynamic>>>('items')?.values;
        if (items != null) {
          pods.addAll(
            items.map((pod) => pod['metadata'].elementAt<String>('name')),
          );
        }
        logger.fine('K8S api: pods: $pods');
      } on Exception catch (error, stackTrace) {
        logger.severe(
          'K8S api: ${Context.toMethod('getPodNamesFromNs', [
            'namespace: $ns',
            'error: $error',
          ])}',
          error,
          stackTrace ?? Trace.current(1),
        );
      }
      logger.fine(
        'K8S api: ${Context.toMethod('getPodNamesFromNs', ['namespace: $ns'])}...done',
      );
    }
    return pods;
  }

  Future<HttpClientResponse> get(String uri) async {
    final url = Uri.parse('https://$apiHost:$apiPort$uri');
    final request = await client.getUrl(url);
    logger.fine('K8S api: request: ${request.method} ${request.uri}');
    request.headers.add('Authorization', 'Bearer $token');
    return request.close();
  }

  static Future<dynamic> toContent(HttpClientResponse response) async {
    final completer = Completer<String>();
    final contents = StringBuffer();
    response.transform(utf8.decoder).listen(
          contents.write,
          onDone: () => completer.complete(contents.toString()),
        );
    final json = await completer.future;
    return jsonDecode(json);
  }
}
