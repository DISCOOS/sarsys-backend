import 'dart:async';
import 'dart:io';

import 'package:event_source/event_source.dart';
import 'package:sarsys_ops_cli/sarsys_ops_cli.dart';

import 'core.dart';

class StatusCommand extends BaseCommand {
  StatusCommand() {
    addSubcommand(StatusAllCommand());
    addSubcommand(StatusModuleCommand());
  }

  @override
  final name = 'status';

  @override
  final description = 'status is used to get information about backend modules';
}

class StatusAllCommand extends BaseCommand {
  StatusAllCommand() {
    argParser
      ..addFlag(
        'verbose',
        abbr: 'v',
        help: 'Verbose output',
      );
  }

  @override
  final name = 'all';

  @override
  final description = 'all is used to get information about all backend modules';

  @override
  FutureOr<String> run() async {
    final verbose = argResults['verbose'] as bool;
    writeln(highlight('> Ops control pane'), stdout);
    final token = await AuthUtils.getToken(this);
    writeln('  Alive: ${await isOK(client, '/ops/api/healthz/alive')}', stdout);
    writeln('  Ready: ${await isOK(client, '/ops/api/healthz/ready')}', stdout);

    final statuses = await get(
      client,
      '/ops/api/system/status',
      (map) => _toStatuses(map, verbose: verbose),
      token: token,
      format: (result) => result,
    );

    writeln(highlight('> Status all ${verbose ? '--verbose' : ''}'), stdout);
    writeln(statuses, stdout);

    return buffer.toString();
  }
}

class StatusModuleCommand extends BaseCommand {
  StatusModuleCommand() {
    argParser
      ..addOption(
        'module',
        abbr: 'm',
        help: 'Module name',
      )
      ..addFlag(
        'verbose',
        abbr: 'v',
        help: 'Verbose output',
      );
  }

  @override
  final name = 'module';

  @override
  final description = 'module is used to get information about given backend module';

  @override
  FutureOr<String> run() async {
    final module = argResults['module'];
    if (module == null) {
      usageException(red(' Module name is missing'));
      return writeln(red(' Module name is missing'), stderr);
    } else {
      final verbose = argResults['verbose'] as bool;
      writeln(highlight('> Status $module ${verbose ? '--verbose' : ''}'), stdout);
      final token = await AuthUtils.getToken(this);

      final statuses = await get(
        client,
        '/ops/api/system/status/$module',
        (map) {
          final buffer = StringBuffer();
          _toStatus(buffer, map, verbose: verbose);
          return buffer.toString();
        },
        token: token,
        format: (result) => result,
      );
      writeln(statuses, stdout);
    }

    return buffer.toString();
  }
}

String _toStatuses(List items, {bool verbose = false}) {
  final buffer = StringBuffer();
  for (var module in items.map((item) => Map.from(item))) {
    buffer.writeln('  Module ${green(module.elementAt('name'))}');
    _toStatus(buffer, module, indent: 4, verbose: verbose);
  }
  return buffer.toString();
}

void _toStatus(StringBuffer buffer, Map module, {int indent = 2, bool verbose = false}) {
  final spaces = List.filled(indent, ' ').join();
  final instances = module.listAt('instances');
  buffer.writeln('${spaces}Instances: ${green(instances.length)}');
  for (var instance in instances.map((item) => Map.from(item))) {
    final alive = instance.elementAt<bool>('status/health/alive');
    final ready = instance.elementAt<bool>('status/health/ready');
    if (verbose) {
      buffer.writeln(gray('${spaces}--------------------------------------------'));
      buffer.writeln('${spaces}Name: ${green(instance.elementAt('name'))}');
      buffer.writeln('${spaces}API');
      buffer.writeln('${spaces}  Alive: ${green(alive)}');
      buffer.writeln('${spaces}  Ready: ${green(alive)}');
      buffer.writeln('${spaces}Deployment');
      final conditions = instance.listAt('status/conditions');
      for (var condition in conditions.map((item) => Map.from(item))) {
        final status = condition.elementAt<String>('status');
        final acceptable = 'true' == status.toLowerCase();
        buffer.writeln('${spaces}  ${condition['type']}: ${acceptable ? green(status) : red(status)}');
      }
    } else {
      final down = !alive || !ready;
      final api = '${alive ? '1' : '0'}/${alive ? '1' : '0'}';
      buffer.writeln('${spaces}${green(instance.elementAt('name'))} API Alive/Ready: ${down ? red(api) : green(api)}');
    }
  }
}
