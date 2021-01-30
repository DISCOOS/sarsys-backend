import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:sarsys_ops_server/sarsys_ops_server.dart';
import 'package:stack_trace/stack_trace.dart';

// ignore: camel_case_types
class K8sApi {
  static const _serviceAccountPath = '/var/run/secrets/kubernetes.io/serviceaccount';
  final logger = Logger('$K8sApi');
  final tokenFile = File('$_serviceAccountPath/token');
  final certFile = File('$_serviceAccountPath/ca.crt');
  final serviceAccountDir = Directory(_serviceAccountPath);

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

    if (tokenFile.existsSync() && certFile.existsSync()) {
      logger.info('K8S api: checking...');
      final token = tokenFile.readAsStringSync();
      final url = Uri.parse('https://$apiHost:$apiPort/api');
      final request = await client.getUrl(url);
      logger.info('K8S api: request: ${request.method} ${request.uri}');
      try {
        request.headers.add('Authorization', 'Bearer $token');
        final response = await request.close();
        logger.info('K8S api: ${response.statusCode} ${response.reasonPhrase}');
        final json = await toBody(response);
        ok = json != null;
        logger.info('K8S api: content: $ok');
      } on Exception catch (error, stackTrace) {
        logger.severe(
          'K8S api: error: $error',
          error,
          stackTrace ?? Trace.current(1),
        );
      }
      logger.info('K8S api: checking...done');
    }
    return ok;
  }

  static Future<dynamic> toBody(HttpClientResponse response) async {
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
