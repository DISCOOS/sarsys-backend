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
      ..addOption(
        'server',
        abbr: 's',
        help: 'Server name',
      )
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
    final server = argResults['server'] as String;
    writeln(highlight('> Tracking status...'), stdout);
    final token = await AuthUtils.getToken(this);
    if (server == null) {
      final statuses = await get(
        client,
        '/ops/api/services/tracking',
        (list) => _toStatuses(list, verbose: verbose),
        token: token,
        format: (result) => result,
      );
      writeln(statuses, stdout);
    } else {
      final status = await get(
        client,
        '/ops/api/services/tracking/$server',
        (meta) {
          final buffer = StringBuffer();
          _toStatus(buffer, meta, verbose: verbose);
          return buffer.toString();
        },
        token: token,
        format: (result) => result,
      );
      writeln(status, stdout);
    }

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
    final server = argResults['server'] as String;
    if (server == null) {
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
        '/ops/api/services/tracking/$server',
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
    buffer.writeln('  Name ${green(instance.elementAt('name'))}');
    _toStatus(buffer, instance, indent: 4, verbose: verbose);
  }
  return buffer.toString();
}

void _toStatus(StringBuffer buffer, Map instance, {int indent = 2, bool verbose = false}) {
  final delimiter = fill(51, '-');
  final columns = delimiter.length;
  buffer.writeln(instance);
  final spaces = fill(indent);
  final trackings = instance.listAt<Map<String, dynamic>>('managerOf');
  vprint(
    'Status',
    instance.elementAt('status'),
    unit: 'tracking service',
    max: columns,
    buffer: buffer,
    indent: indent,
  );
  vprint(
    'Processed',
    instance.elementAt<int>('positions/total', defaultValue: 0),
    unit: 'positions',
    max: columns,
    buffer: buffer,
    indent: indent,
  );
  vprint(
    'Total seen',
    instance.elementAt<int>('total', defaultValue: 0),
    unit: 'all tracking objects',
    max: columns,
    buffer: buffer,
    indent: indent,
  );
  vprint(
    'Is managing',
    trackings.length,
    unit: '${(instance.elementAt<double>('fractionManaged', defaultValue: 0) * 100).toInt()}% of tracking objects',
    max: columns,
    buffer: buffer,
    indent: indent,
  );
  vprint(
    'PPM',
    instance.elementAt<double>('positions/positionsPerMinute', defaultValue: 0),
    unit: 'positions per minute',
    max: columns,
    buffer: buffer,
    indent: indent,
  );
  vprint(
    'APT',
    instance.elementAt<double>('positions/averageProcessingTimeMillis', defaultValue: 0),
    unit: 'average processing time in ms',
    max: columns,
    buffer: buffer,
    indent: indent,
  );
  if (verbose) {
    var i = 0;
    for (var tracking in trackings.map((item) => Map<String, dynamic>.from(item))) {
      buffer.writeln(gray('${spaces}$delimiter'));
      vprint(
        'UUID ${++i}',
        tracking.elementAt('uuid'),
        max: columns,
        buffer: buffer,
        indent: indent,
      );
      vprint(
        'Last applied',
        tracking.elementAt<String>('lastEvent/type', defaultValue: 'none'),
        unit: 'event ${tracking.elementAt<int>('lastEvent/number')}',
        max: columns,
        buffer: buffer,
        indent: indent,
      );
      vprint(
        'Tracks',
        tracking.elementAt<int>('trackCount', defaultValue: 0),
        max: columns,
        buffer: buffer,
        indent: indent,
      );
      vprint(
        'Positions',
        tracking.elementAt<int>('positionCount', defaultValue: 0),
        max: columns,
        buffer: buffer,
        indent: indent,
      );
    }
  }
}
