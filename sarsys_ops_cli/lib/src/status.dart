import 'dart:async';
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
    writeln(highlight('> Ops control pane'), stdout);
    final token = await AuthUtils.getToken(this);
    writeln('  Alive: ${await isOK(client, '/ops/api/healthz/alive')}', stdout);
    writeln('  Ready: ${await isOK(client, '/ops/api/healthz/ready')}', stdout);

    writeln(highlight('> System'), stdout);
    writeln(
      '  Pods: ${await get(
        client,
        '/ops/api/system/status',
        (pods) => '$pods',
        token: token,
      )}',
      stdout,
    );

    return buffer.toString();
  }
}
