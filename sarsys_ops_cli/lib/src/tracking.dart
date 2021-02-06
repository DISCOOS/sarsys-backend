import 'dart:async';
import 'dart:io';

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
  TrackingStatusCommand();

  @override
  final name = 'status';

  @override
  final description = 'status is used to check tracking status';

  @override
  FutureOr<String> run() async {
    writeln(highlight('> Tracking status'), stdout);
    final token = await AuthUtils.getToken(this);
    writeln(
      '  json: ${await get(
        client,
        '/ops/api/services/tracking',
        (pods) => '$pods',
        token: token,
      )}',
      stdout,
    );

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
