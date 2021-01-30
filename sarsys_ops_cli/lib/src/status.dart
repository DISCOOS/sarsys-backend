import 'dart:async';
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
    return buffer.toString();
  }

  Future<String> _isOK(HttpClient client, String url) async {
    final tic = DateTime.now();
    final buffer = StringBuffer();
    final request = await client.get('sarsys.app', 80, url);
    final response = await request.close();
    final reason = '${response.reasonPhrase} in ';
    if (HttpStatus.ok == response.statusCode) {
      buffer.write(green('Yes'));
    } else {
      buffer.write(red('No'));
    }
    buffer.write(gray(' ($reason${DateTime.now().difference(tic).inMilliseconds} ms)'));
    return buffer.toString();
  }
}
