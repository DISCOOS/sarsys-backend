import 'dart:async';
import 'dart:convert';
import 'dart:io';

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
    writeln('  Alive: ${await _isOK(client, '/ops/api/healthz/alive')}', stdout);
    writeln('  Ready: ${await _isOK(client, '/ops/api/healthz/ready')}', stdout);

    writeln(highlight('> System'), stdout);
    writeln('  Alive: ${await _isOK(client, '/ops/api/system/status', failure: 'Failure')}', stdout);

    return buffer.toString();
  }

  Future<dynamic> _get(HttpClient client, String url) async {
    final tic = DateTime.now();
    final buffer = StringBuffer();
    final request = await client.get('sarsys.app', 80, url);
    final response = await request.close();
    final result = '${response.statusCode} ${response.reasonPhrase} in ';
    writeln(gray('  GET $url: ($result${DateTime.now().difference(tic).inMilliseconds} ms)'), stdout);
    return buffer.toString();
  }

  Future<String> _isOK(
    HttpClient client,
    String url, {
    String access = 'Yes',
    String failure = 'No',
  }) async {
    final tic = DateTime.now();
    final buffer = StringBuffer();
    final request = await client.get('sarsys.app', 80, url);
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
