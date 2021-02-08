import 'dart:async';
import 'dart:io';

import 'package:event_source/event_source.dart';
import 'package:sarsys_ops_cli/sarsys_ops_cli.dart';

import 'core.dart';

class TrackingCommand extends BaseCommand {
  TrackingCommand() {
    addSubcommand(TrackingStatusCommand());
    addSubcommand(TrackingAddCommand());
    addSubcommand(TrackingRemoveCommand());
    addSubcommand(TrackingStartCommand());
    addSubcommand(TrackingStopCommand());
  }

  @override
  final name = 'tracking';

  @override
  final description = 'tracking is used to manage tracking module';
}

class TrackingStatusCommand extends BaseCommand {
  TrackingStatusCommand() {
    argParser
      ..addFlag(
        'verbose',
        abbr: 'v',
        help: 'Verbose output',
      );
  }

  @override
  final name = 'status';

  @override
  final description = 'status is used to check tracking status';

  @override
  FutureOr<String> run() async {
    final verbose = argResults['verbose'] as bool;
    writeln(highlight('> Tracking status'), stdout);
    final token = await AuthUtils.getToken(this);
    final statuses = await get(
      client,
      '/ops/api/services/tracking',
      (map) => _toStatuses([map], verbose: verbose),
      token: token,
      format: (result) => result,
    );

    writeln(highlight('> Status all ${verbose ? '--verbose' : ''}'), stdout);
    writeln(statuses, stdout);

    return buffer.toString();
  }
}

class TrackingAddCommand extends BaseCommand {
  TrackingAddCommand() {
    argParser
      ..addOption(
        'server',
        abbr: 's',
        help: 'Server name',
      )
      ..addMultiOption(
        'uuids',
        abbr: 'u',
        help: 'List of tracking object uuids',
      );
  }

  @override
  final name = 'add';

  @override
  final description = 'add is used to add tracking objects to given server';

  @override
  FutureOr<String> run() async {
    writeln(highlight('> Tracking add'), stdout);
    final name = argResults['server'] as String;
    if (name == null) {
      usageException(red(' Server name is missing'));
      return writeln(red(' Server name is missing'), stderr);
    }
    final uuids = argResults['uuids'] as List<String>;
    if (uuids.isEmpty) {
      usageException(red(' Tracking uuids are missing'));
      return writeln(red(' Tracking uuids are missing'), stderr);
    }
    final token = await AuthUtils.getToken(this);
    writeln(
      '  json: ${await post(
        client,
        '/ops/api/services/tracking',
        {
          'action': 'add_trackings',
          'uuids': uuids,
        },
        (pods) => '$pods',
        token: token,
      )}',
      stdout,
    );
    return buffer.toString();
  }
}

class TrackingRemoveCommand extends BaseCommand {
  TrackingRemoveCommand() {
    argParser
      ..addOption(
        'server',
        abbr: 's',
        help: 'Server name',
      )
      ..addMultiOption(
        'uuids',
        abbr: 'u',
        help: 'List of tracking object uuids',
      );
  }

  @override
  final name = 'remove';

  @override
  final description = 'remove is used to remove tracking objects from given server';

  @override
  FutureOr<String> run() async {
    writeln(highlight('> Tracking remove'), stdout);
    final name = argResults['server'] as String;
    if (name == null) {
      usageException(red(' Server name is missing'));
      return writeln(red(' Server name is missing'), stderr);
    }
    final uuids = argResults['uuids'] as List<String>;
    if (uuids.isEmpty) {
      usageException(red(' Tracking uuids are missing'));
      return writeln(red(' Tracking uuids are missing'), stderr);
    }
    final token = await AuthUtils.getToken(this);
    writeln(
      '  json: ${await post(
        client,
        '/ops/api/services/tracking',
        {
          'action': 'remove_trackings',
          'uuids': uuids,
        },
        (pods) => '$pods',
        token: token,
      )}',
      stdout,
    );

    return buffer.toString();
  }
}

class TrackingStartCommand extends BaseCommand {
  TrackingStartCommand() {
    argParser
      ..addOption(
        'server',
        abbr: 's',
        help: 'Server name',
      );
  }

  @override
  final name = 'start';

  @override
  final description = 'start is used to start tracking service in given server';

  @override
  FutureOr<String> run() async {
    writeln(highlight('> Tracking remove'), stdout);
    final token = await AuthUtils.getToken(this);
    final name = argResults['server'] as String;
    if (name == null) {
      usageException(red(' Server name is missing'));
      return writeln(red(' Server name is missing'), stderr);
    }
    writeln(
      '  json: ${await post(
        client,
        '/ops/api/services/tracking',
        {
          'action': 'start',
        },
        (pods) => '$pods',
        token: token,
      )}',
      stdout,
    );

    return buffer.toString();
  }
}

class TrackingStopCommand extends BaseCommand {
  TrackingStopCommand() {
    argParser
      ..addOption(
        'server',
        abbr: 's',
        help: 'Server name',
      );
  }

  @override
  final name = 'stop';

  @override
  final description = 'stop is used to stop tracking service in given server';

  @override
  FutureOr<String> run() async {
    writeln(highlight('> Tracking remove'), stdout);
    final token = await AuthUtils.getToken(this);
    final name = argResults['server'] as String;
    if (name == null) {
      usageException(red(' Server name is missing'));
      return writeln(red(' Server name is missing'), stderr);
    }
    writeln(
      '  json: ${await post(
        client,
        '/ops/api/services/tracking',
        {
          'action': 'stop',
        },
        (pods) => '$pods',
        token: token,
      )}',
      stdout,
    );

    return buffer.toString();
  }
}

String _toStatuses(List items, {bool verbose = false}) {
  final buffer = StringBuffer();
  for (var instance in items.map((item) => Map.from(item))) {
    buffer.writeln('  Name ${green(instance.elementAt('name') ?? 'Test')}');
    _toStatus(buffer, instance, indent: 4, verbose: verbose);
  }
  return buffer.toString();
}

void _toStatus(StringBuffer buffer, Map instance, {int indent = 2, bool verbose = false}) {
  final spaces = List.filled(indent, ' ').join();
  final trackings = instance.listAt('managerOf');
  buffer.writeln('${spaces}Status: ${green(instance.elementAt('status'))} ${gray('(service)')}');
  buffer.writeln('${spaces}Total seen: ${green(instance.elementAt('total'))} ${gray('(all tracking objects)')}');
  buffer.writeln(
    '${spaces}Is managing: ${green(trackings.length)} '
    '${gray('(${(instance.elementAt<int>('fractionManaged:', defaultValue: 0) * 100).toInt()}% of tracking objects)')}',
  );
  buffer.writeln(
    '${spaces}Positions processed: ${green(instance.elementAt<int>('positions/total', defaultValue: 0))}',
  );
  for (var tracking in trackings.map((item) => Map.from(item))) {
    final alive = tracking.elementAt<bool>('status/health/alive');
    final ready = tracking.elementAt<bool>('status/health/ready');
    //   final alive = tracking.elementAt<bool>('status/health/alive');
    //   final ready = tracking.elementAt<bool>('status/health/ready');
    //   if (verbose) {
    //     buffer.writeln(gray('${spaces}--------------------------------------------'));
    //     buffer.writeln('${spaces}Name: ${green(tracking.elementAt('name'))}');
    //     buffer.writeln('${spaces}API');
    //     buffer.writeln('${spaces}  Alive: ${green(alive)}');
    //     buffer.writeln('${spaces}  Ready: ${green(alive)}');
    //     buffer.writeln('${spaces}Deployment');
    //     final conditions = tracking.listAt('status/conditions');
    //     for (var condition in conditions.map((item) => Map.from(item))) {
    //       final status = condition.elementAt<String>('status');
    //       final acceptable = 'true' == status.toLowerCase();
    //       buffer.writeln(
    //         '${spaces}  ${condition['type']}: '
    //         '${acceptable ? green(status) : red(status)} '
    //         '${condition.hasPath('message') ? gray('(${condition.elementAt<String>('message')})') : ''}',
    //       );
    //     }
    //   } else {
    //     final down = !alive || !ready;
    //     final api = '${alive ? '1' : '0'}/${alive ? '1' : '0'}';
    //     buffer.writeln(
    //       '${spaces}${green(tracking.elementAt('name'))} '
    //       'API: ${down ? red(api) : green(api)} ${gray('(Alive/Ready)')}',
    //     );
    //   }
  }
}
