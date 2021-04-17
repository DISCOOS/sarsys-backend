import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:collection_x/collection_x.dart';
import 'package:sarsys_ops_cli/sarsys_ops_cli.dart';
import 'package:strings/strings.dart';

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
  final description = 'is used to get information about backend modules';
}

class StatusAllCommand extends BaseCommand {
  StatusAllCommand();

  @override
  final name = 'all';

  @override
  final description = 'is used to get information about all backend modules';

  @override
  FutureOr<String> onJson() async {
    final token = await AuthUtils.getToken(this);
    return get(
      client,
      '/ops/api/system/status?expand=metrics',
      (meta) => jsonEncode(meta),
      token: token,
      format: (result) => result,
    );
  }

  @override
  Future onPrint() async {
    final verbose = globalResults['verbose'] as bool;
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
      ..allowsAnything;
  }

  final String module;

  @override
  final String name;

  @override
  String get description => 'is used to get information about given backend module';

  @override
  FutureOr<String> onJson() async {
    final token = await AuthUtils.getToken(this);
    final instance = argResults['instance'] as String;
    final uri = instance == null
        ? '/ops/api/system/status/$module?expand=metrics'
        : '/ops/api/system/status/$module/$instance?expand=metrics';
    return get(
      client,
      uri,
      (meta) => jsonEncode(meta),
      token: token,
      format: (result) => result,
    );
  }

  @override
  Future onPrint() async {
    final verbose = globalResults['verbose'] as bool;
    final instance = argResults['instance'] as String;
    writeln(highlight('> Status ${capitalize(name)} ${verbose ? '(verbose)' : ''}'), stdout);
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
            (map as Map).elementAt('name'),
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
  }
}

String _toModuleListStatus(List items, {bool verbose = false}) {
  final buffer = StringBuffer();
  for (var module in items.map((item) => Map.from(item))) {
    final instances = module.listAt<Map<String, dynamic>>('instances');
    _toModuleStatus(
      buffer,
      module.elementAt('name'),
      instances,
      indent: 2,
      verbose: verbose,
    );
  }
  return buffer.toString();
}

void _toModuleStatus(
  StringBuffer buffer,
  String module,
  List<Map<String, dynamic>> instances, {
  int indent = 2,
  bool verbose = false,
}) {
  final spaces = fill(2);
  buffer.writeln(gray('${spaces}--------------------------------------------'));
  buffer.writeln(
    '${spaces}Module: ${green(module)} '
    '${gray('(${instances.length} instances)')}',
  );
  buffer.writeln(gray('${spaces}--------------------------------------------'));
  for (var instance in instances.map((item) => Map<String, dynamic>.from(item))) {
    _toInstanceStatus(
      buffer,
      instance,
      indent: indent,
      verbose: verbose,
    );
  }
  buffer.writeln();
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
        '${green(metrics.jointAt(['usage/cpu', 'requests/cpu', 'limits/cpu'], separator: '/'))}'
        ' ${gray('(use/req/max)')}',
      );
      buffer.writeln(
        '${spaces}   Memory: '
        '${green(metrics.jointAt(['usage/memory', 'requests/memory', 'limits/memory'], separator: '/'))}'
        ' ${gray('(use/req/max)')}',
      );
    }
    buffer.writeln(gray('${spaces}--------------------------------------------'));
  } else {
    final down = !alive || !ready;
    final api = '${alive ? '1' : '0'}/${alive ? '1' : '0'}';
    buffer.writeln(
      '${spaces}${green(instance.elementAt('name'))} '
      'API: ${down ? red(api) : green(api)} ${gray('(Alive/Ready)')}',
    );
  }
}
