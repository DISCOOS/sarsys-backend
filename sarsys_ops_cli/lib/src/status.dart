import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:sarsys_ops_cli/sarsys_ops_cli.dart';

import 'core.dart';

class StatusCommand extends BaseCommand {
  StatusCommand();

  @override
  final name = 'status';

  @override
  final description = 'status is used to get information about backend modules';

  @override
  FutureOr<String> run() async {
    final client = HttpClient();
    writeln(highlight('> Ops control pane'), stdout);
    final token = await AuthUtils.getToken(this);
    writeln('  Alive: ${await _isOK(client, '/ops/api/healthz/alive')}', stdout);
    writeln('  Ready: ${await _isOK(client, '/ops/api/healthz/ready')}', stdout);

    writeln(highlight('> System'), stdout);
    writeln(
      '  Pods: ${await _get(
        client,
        '/ops/api/system/status',
        (pods) => '$pods',
        token: token,
      )}',
      stdout,
    );

    return buffer.toString();
  }

  Future<String> _get(
    HttpClient client,
    String url,
    String Function(dynamic) map, {
    String token,
  }) async {
    final tic = DateTime.now();
    final buffer = StringBuffer();
    final request = await client.get('sarsys.app', 80, url);
    if (token != null) {
      request.headers.add('Authorization', 'Bearer $token');
    }
    final response = await request.close();
    final result = '${response.statusCode} ${response.reasonPhrase} in ';
    if (HttpStatus.ok == response.statusCode) {
      buffer.write(green(map(await toContent(response))));
    } else {
      buffer.write(red('Failure'));
    }
    buffer.write(gray(' ($result${DateTime.now().difference(tic).inMilliseconds} ms)'));
    return buffer.toString();
  }

  Future<String> _isOK(
    HttpClient client,
    String url, {
    String access = 'Yes',
    String failure = 'No',
    String token,
  }) async {
    final tic = DateTime.now();
    final buffer = StringBuffer();
    final request = await client.get('sarsys.app', 80, url);
    if (token != null) {
      request.headers.add('Authorization', 'Bearer $token');
    }
    final response = await request.close();
    final reason = '${response.statusCode} ${response.reasonPhrase} in ';
    if (HttpStatus.ok == response.statusCode) {
      buffer.write(green('$access'));
    } else {
      buffer.write(red('$failure'));
    }
    buffer.write(gray(' ($reason${DateTime.now().difference(tic).inMilliseconds} ms)'));
    return buffer.toString();
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
