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

abstract class TrackingCommandBase extends BaseCommand {
  Future<String> executeOn(
    String server,
    Map<String, dynamic> args,
    bool verbose,
  ) async {
    final token = await AuthUtils.getToken(this);
    final status = await post(
      client,
      '/ops/api/services/tracking/$server',
      args,
      (result) {
        final buffer = StringBuffer();
        toStatus(
          buffer,
          result['meta'],
          verbose: verbose,
        );
        return buffer.toString();
      },
      token: token,
      format: (result) => result,
    );
    return status;
  }

  String toStatuses(List items, {bool verbose = false}) {
    final buffer = StringBuffer();
    for (var instance in items.map((item) => Map.from(item))) {
      sprint(60, buffer: buffer, format: highlight);
      vprint('Name', instance.elementAt('name'), buffer: buffer);
      toStatus(buffer, instance, verbose: verbose);
      buffer.writeln();
    }
    return buffer.toString();
  }

  void toStatus(StringBuffer buffer, Map instance, {int indent = 2, bool verbose = false}) {
    final separator = fill(60, '-');
    final columns = separator.length;
    final spaces = fill(indent);
    buffer.writeln(highlight('$spaces$separator'));
    final trackings = instance.listAt<Map<String, dynamic>>(
      'managerOf',
      defaultList: [],
    );
    vprint(
      'Status',
      instance.elementAt('status'),
      unit: 'tracking service',
      max: columns,
      buffer: buffer,
      indent: indent,
    );
    vprint(
      'Trackings seen',
      instance.elementAt<int>('metrics/trackings/total', defaultValue: 0),
      unit: 'all tracking objects',
      max: columns,
      buffer: buffer,
      indent: indent,
    );
    buffer.writeln('$spaces$separator');
    vprint(
      'Is managing',
      trackings.length,
      unit: '${(instance.elementAt<double>('metrics/trackings/fractionManaged', defaultValue: 0) * 100).toInt()}'
          '% of all tracking objects',
      max: columns,
      buffer: buffer,
      indent: indent,
    );
    vprint(
      'TPM',
      instance.elementAt<double>('metrics/trackings/eventsPerMinute', defaultValue: 0),
      unit: 'trackings per minute',
      max: columns,
      buffer: buffer,
      indent: indent,
    );
    vprint(
      'TPT',
      instance.elementAt<int>('metrics/trackings/averageProcessingTimeMillis', defaultValue: 0),
      unit: 'average tracking processing in ms',
      max: columns,
      buffer: buffer,
      indent: indent,
    );
    buffer.writeln('$spaces$separator');
    vprint(
      'Processed',
      instance.elementAt<int>('metrics/positions/total', defaultValue: 0),
      unit: 'positions',
      max: columns,
      buffer: buffer,
      indent: indent,
    );
    vprint(
      'PPM',
      instance.elementAt<double>('metrics/positions/eventsPerMinute', defaultValue: 0),
      unit: 'positions per minute',
      max: columns,
      buffer: buffer,
      indent: indent,
    );
    vprint(
      'PPT',
      instance.elementAt<int>('metrics/positions/averageProcessingTimeMillis', defaultValue: 0),
      unit: 'average position processing in ms',
      max: columns,
      buffer: buffer,
      indent: indent,
    );
    if (verbose) {
      var i = 0;
      for (var tracking in trackings.map((item) => Map<String, dynamic>.from(item))) {
        buffer.writeln(gray('${spaces}$separator'));
        vprint(
          'Tracking',
          tracking.elementAt('uuid'),
          unit: '# ${++i}',
          max: columns,
          buffer: buffer,
          indent: indent,
        );
        vprint(
          'Applied last',
          tracking.elementAt<String>('lastEvent/type', defaultValue: 'none'),
          unit: 'event ${tracking.elementAt<int>('lastEvent/number')}',
          max: columns,
          buffer: buffer,
          indent: indent,
        );
        final ts = tracking.elementAt<int>('lastEvent/timestamp', defaultValue: 0);
        vprint(
          'Applied when',
          DateTime.fromMillisecondsSinceEpoch(ts).toIso8601String(),
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
}

class TrackingStatusCommand extends TrackingCommandBase {
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
    final server = argResults['server'] as String;
    writeln(highlight('> Tracking status...'), stdout);
    final token = await AuthUtils.getToken(this);
    if (server == null) {
      final statuses = await get(
        client,
        '/ops/api/services/tracking',
        (list) => toStatuses(
          list,
          verbose: argResults['verbose'] as bool,
        ),
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
          toStatus(
            buffer,
            meta,
            verbose: argResults['verbose'] as bool,
          );
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

class TrackingStartCommand extends TrackingCommandBase {
  TrackingStartCommand() {
    argParser
      ..addOption(
        'server',
        abbr: 's',
        help: 'Server name',
      )
      ..addFlag(
        'all',
        abbr: 'a',
        help: 'All servers',
      )
      ..addFlag(
        'verbose',
        abbr: 'v',
        help: 'Verbose output',
      );
  }

  @override
  final name = 'start';

  @override
  final description = 'start is used to start tracking service in given server';

  @override
  FutureOr<String> run() async {
    final all = argResults['all'] as String;
    final server = argResults['server'] as String;
    if (all == null && server == null) {
      usageException(red(' Server name is missing'));
      return writeln(red(' Server name is missing'), stderr);
    }
    writeln(highlight('> Start racking $server...'), stdout);
    final status = await executeOn(
      server,
      {
        'action': 'start',
      },
      argResults['verbose'] as bool,
    );
    writeln(status, stdout);

    return buffer.toString();
  }
}

class TrackingStopCommand extends TrackingCommandBase {
  TrackingStopCommand() {
    argParser
      ..addOption(
        'server',
        abbr: 's',
        help: 'Server name',
      )
      ..addFlag(
        'all',
        abbr: 'a',
        help: 'All servers',
      )
      ..addFlag(
        'verbose',
        abbr: 'v',
        help: 'Verbose output',
      );
  }

  @override
  final name = 'stop';

  @override
  final description = 'stop is used to stop tracking service in given server';

  @override
  FutureOr<String> run() async {
    final all = argResults['all'] as String;
    final server = argResults['server'] as String;
    if (all == null && server == null) {
      usageException(red(' Server name is missing'));
      return writeln(red(' Server name is missing'), stderr);
    }
    writeln(highlight('> Stop tracking $server...'), stdout);
    final status = await executeOn(
      server,
      {
        'action': 'stop',
      },
      argResults['verbose'] as bool,
    );
    writeln(status, stdout);
    return buffer.toString();
  }
}

class TrackingAddCommand extends TrackingCommandBase {
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
      )
      ..addFlag(
        'verbose',
        abbr: 'v',
        help: 'Verbose output',
      );
  }

  @override
  final name = 'add';

  @override
  final description = 'add is used to add tracking objects to given server';

  @override
  FutureOr<String> run() async {
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
    writeln(highlight('> Add trackings object to $server...'), stdout);
    final status = await executeOn(
      server,
      {
        'action': 'add_trackings',
        'uuids': uuids,
      },
      argResults['verbose'] as bool,
    );
    writeln(status, stdout);
    return buffer.toString();
  }
}

class TrackingRemoveCommand extends TrackingCommandBase {
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
      )
      ..addFlag(
        'verbose',
        abbr: 'v',
        help: 'Verbose output',
      );
  }

  @override
  final name = 'remove';

  @override
  final description = 'remove is used to remove tracking objects from given server';

  @override
  FutureOr<String> run() async {
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
    writeln(highlight('> Remove trackings object from $server...'), stdout);
    final status = await executeOn(
      server,
      {
        'action': 'remove_trackings',
        'uuids': uuids,
      },
      argResults['verbose'] as bool,
    );
    writeln(status, stdout);

    return buffer.toString();
  }
}
