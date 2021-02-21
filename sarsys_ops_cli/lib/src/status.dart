import 'dart:async';
import 'dart:io';

import 'package:event_source/event_source.dart';
import 'package:sarsys_ops_cli/sarsys_ops_cli.dart';

import 'core.dart';

class StatusCommand extends BaseCommand {
  StatusCommand() {
    addSubcommand(StatusAllCommand());
    addSubcommand(StatusModuleStatusCommand('app', 'sarsys-app-server'));
    addSubcommand(StatusModuleStatusCommand('tracking', 'sarsys-tracking-server'));
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
      '/ops/api/system/status?expand=metrics',
      (map) => _toModuleListStatus(map, verbose: verbose),
      token: token,
      format: (result) => result,
    );

    writeln(highlight('> Status all ${verbose ? '--verbose' : ''}'), stdout);
    writeln(statuses, stdout);

    return buffer.toString();
  }
}

class StatusModuleStatusCommand extends BaseCommand {
  StatusModuleStatusCommand(this.name, this.module) {
    argParser
      ..addOption(
        'instance',
        abbr: 'i',
        help: 'Instance name',
      )
      ..addFlag(
        'verbose',
        abbr: 'v',
        help: 'Verbose output',
      )
      ..allowsAnything;
  }

  final String module;

  @override
  final String name;

  @override
  String get description => '$name is used to get information about given backend module';

  @override
  FutureOr<String> run() async {
    final instance = argResults['instance'];
    final verbose = argResults['verbose'] as bool;
    writeln(highlight('> Status App ${verbose ? '(verbose)' : ''}'), stdout);
    final token = await AuthUtils.getToken(this);
    final uri = instance == null
        ? '/ops/api/system/status/$module?expand=metrics'
        : '/ops/api/system/status/$module/$instance?expand=metrics';
    final statuses = await get(
      client,
      uri,
      (map) {
        final buffer = StringBuffer();
        if (instance == null) {
          _toModuleStatus(
            buffer,
            (map as Map).listAt('instances'),
            verbose: verbose,
          );
        } else {
          _toInstanceStatus(
            buffer,
            Map<String, dynamic>.from(map),
            verbose: verbose,
          );
        }
        return buffer.toString();
      },
      token: token,
      format: (result) => result,
    );
    writeln(statuses, stdout);

    return buffer.toString();
  }
}

String _toModuleListStatus(List items, {bool verbose = false}) {
  final buffer = StringBuffer();
  final spaces = fill(2);
  for (var module in items.map((item) => Map.from(item))) {
    final instances = module.listAt<Map<String, dynamic>>('instances');
    buffer.writeln(
      '${spaces}Module: ${green(module.elementAt('name'))} '
      '${gray('(${instances.length} instances)')}',
    );
    _toModuleStatus(buffer, instances, indent: 4, verbose: verbose);
  }
  return buffer.toString();
}

void _toModuleStatus(
  StringBuffer buffer,
  List<Map<String, dynamic>> instances, {
  int indent = 2,
  bool verbose = false,
}) {
  for (var instance in instances.map((item) => Map.from(item))) {
    _toInstanceStatus(
      buffer,
      instance,
      indent: indent,
      verbose: verbose,
    );
  }
}

void _toInstanceStatus(
  StringBuffer buffer,
  Map<String, dynamic> instance, {
  int indent = 2,
  bool verbose = false,
}) {
  final spaces = List.filled(indent, ' ').join();
  final alive = instance.elementAt<bool>('status/health/alive');
  final ready = instance.elementAt<bool>('status/health/ready');
  if (verbose) {
    buffer.writeln(gray('${spaces}--------------------------------------------'));
    buffer.writeln('${spaces}Name: ${green(instance.elementAt('name'))}');
    buffer.writeln('${spaces}API');
    buffer.writeln('${spaces}  Alive: ${green(alive)}');
    buffer.writeln('${spaces}  Ready: ${green(ready)}');
    buffer.writeln('${spaces}Deployment');
    final conditions = instance.listAt('status/conditions', defaultList: []);
    for (var condition in conditions.map((item) => Map.from(item))) {
      final status = condition.elementAt<String>('status');
      final acceptable = 'true' == status.toLowerCase();
      buffer.writeln(
        '${spaces}  ${condition['type']}: '
        '${acceptable ? green(status) : red(status)} '
        '${condition.hasPath('message') ? gray('(${condition.elementAt<String>('message')})') : ''}',
      );
    }
    final metrics = instance.mapAt('metrics');
    if (metrics != null) {
      buffer.writeln('${spaces}Metrics');
      buffer.writeln(
        '${spaces}   CPU: '
        '${metrics.jointAt(['usage/cpu', 'requests/cpu', 'limits/cpu'], separator: '/')}'
        ' ${gray('(usage/request/limit)')}',
      );
      buffer.writeln(
        '${spaces}   MEM: '
        '${metrics.jointAt(['usage/memory', 'requests/memory', 'limits/memory'], separator: '/')}'
        ' ${gray('(usage/request/limit)')}',
      );
    }
  } else {
    final down = !alive || !ready;
    final api = '${alive ? '1' : '0'}/${alive ? '1' : '0'}';
    buffer.writeln(
      '${spaces}${green(instance.elementAt('name'))} '
      'API: ${down ? red(api) : green(api)} ${gray('(Alive/Ready)')}',
    );
  }
}
