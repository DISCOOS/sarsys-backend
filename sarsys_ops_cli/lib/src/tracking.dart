import 'dart:async';
import 'dart:convert';
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
  final description = 'is used to manage tracking module';
}

abstract class TrackingCommandBase extends BaseCommand {
  Future<String> executeOn(
    String instance,
    Map<String, dynamic> args,
    bool verbose,
  ) async {
    final token = await AuthUtils.getToken(this);
    final result = await post(
      client,
      '/ops/api/services/tracking/$instance?expand=metrics',
      args,
      (result) {
        final buffer = StringBuffer();
        toInstanceStatus(
          buffer,
          result['meta'],
          verbose: verbose,
        );
        return buffer.toString();
      },
      token: token,
      format: (result) => result,
    );
    return result.buffer.toString();
  }

  String toModuleStatus(List items, {bool verbose = false}) {
    final buffer = StringBuffer();
    for (var instance in items.map((item) => Map.from(item))) {
      sprint(60, buffer: buffer, format: highlight);
      vprint('Name', instance.elementAt('name'), buffer: buffer);
      toInstanceStatus(buffer, instance, verbose: verbose);
      buffer.writeln();
    }
    return buffer.toString();
  }

  void toInstanceStatus(
    StringBuffer buffer,
    Map instance, {
    int indent = 2,
    bool verbose = false,
  }) {
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
      instance.elementAt<int>('trackings/total', defaultValue: 0),
      unit: 'all tracking objects',
      max: columns,
      buffer: buffer,
      indent: indent,
    );
    buffer.writeln('$spaces$separator');
    vprint(
      'Is managing',
      trackings.length,
      unit: '${(instance.elementAt<double>('trackings/fractionManaged', defaultValue: 0) * 100).toInt()}'
          '% of all tracking objects',
      max: columns,
      buffer: buffer,
      indent: indent,
    );
    vprint(
      'TPM',
      instance.elementAt<double>('trackings/eventsPerMinute', defaultValue: 0).toStringAsFixed(1),
      unit: 'trackings per minute',
      max: columns,
      buffer: buffer,
      indent: indent,
    );
    vprint(
      'TPT',
      instance.elementAt<int>('trackings/averageProcessingTimeMillis', defaultValue: 0),
      unit: 'average tracking processing in ms',
      max: columns,
      buffer: buffer,
      indent: indent,
    );
    buffer.writeln('$spaces$separator');
    vprint(
      'Processed',
      instance.elementAt<int>('positions/total', defaultValue: 0),
      unit: 'positions',
      max: columns,
      buffer: buffer,
      indent: indent,
    );
    vprint(
      'PPM',
      instance.elementAt<double>('positions/eventsPerMinute', defaultValue: 0).toStringAsFixed(1),
      unit: 'positions per minute',
      max: columns,
      buffer: buffer,
      indent: indent,
    );
    vprint(
      'PPT',
      instance.elementAt<int>('positions/averageProcessingTimeMillis', defaultValue: 0),
      unit: 'average position processing in ms',
      max: columns,
      buffer: buffer,
      indent: indent,
    );
    final metrics = instance.mapAt('metrics');
    if (metrics != null) {
      buffer.writeln('$spaces$separator');
      vprint(
        'CPU',
        '${metrics.jointAt(['usage/cpu', 'requests/cpu', 'limits/cpu'], separator: '/')}',
        unit: 'use/req/max',
        max: columns,
        buffer: buffer,
        indent: indent,
      );
      vprint(
        'Memory',
        '${metrics.jointAt(['usage/memory', 'requests/memory', 'limits/memory'], separator: '/')}',
        unit: 'use/req/max',
        max: columns,
        buffer: buffer,
        indent: indent,
      );
    }
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
        final ts = tracking.elementAt<DateTime>('lastEvent/timestamp');
        vprint(
          'Applied when',
          ts.toIso8601String(),
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
        'instance',
        abbr: 'i',
        help: 'Instance name',
      );
  }

  @override
  final name = 'status';

  @override
  final description = 'is used to check tracking status';

  @override
  FutureOr<String> onJson() async {
    final token = await AuthUtils.getToken(this);
    final instance = argResults['instance'] as String;
    final uri = instance == null
        ? '/ops/api/services/tracking?expand=metrics'
        : '/ops/api/services/tracking/$instance?expand=metrics';
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
    final instance = argResults['instance'] as String;
    writeln(highlight('> Tracking status...'), stdout);
    final token = await AuthUtils.getToken(this);
    if (instance == null) {
      final statuses = await get(
        client,
        '/ops/api/services/tracking?expand=metrics',
        (meta) => toModuleStatus(
          Map.from(meta).listAt('items'),
          verbose: globalResults['verbose'] as bool,
        ),
        token: token,
        format: (result) => result,
      );
      writeln(statuses, stdout);
    } else {
      final status = await get(
        client,
        '/ops/api/services/tracking/$instance?expand=metrics',
        (meta) {
          final buffer = StringBuffer();
          toInstanceStatus(
            buffer,
            meta,
            verbose: globalResults['verbose'] as bool,
          );
          return buffer.toString();
        },
        token: token,
        format: (result) => result,
      );
      writeln(status, stdout);
    }
  }
}

class TrackingStartCommand extends TrackingCommandBase {
  TrackingStartCommand() {
    argParser
      ..addOption(
        'instance',
        abbr: 'i',
        help: 'Instance name',
      )
      ..addFlag(
        'all',
        abbr: 'a',
        help: 'All servers',
      );
  }

  @override
  final name = 'start';

  @override
  final description = 'is used to start tracking service in given server';

  @override
  FutureOr<String> run() async {
    final all = argResults['all'] as String;
    final instance = argResults['instance'] as String;
    if (all == null && instance == null) {
      usageException(red(' Instance name is missing'));
      return writeln(red(' Instance name is missing'), stderr);
    }
    writeln(highlight('> Start racking $instance...'), stdout);
    final status = await executeOn(
      instance,
      {
        'action': 'start',
      },
      globalResults['verbose'] as bool,
    );
    writeln(status, stdout);

    return buffer.toString();
  }
}

class TrackingStopCommand extends TrackingCommandBase {
  TrackingStopCommand() {
    argParser
      ..addOption(
        'instance',
        abbr: 'i',
        help: 'Instance name',
      )
      ..addFlag(
        'all',
        abbr: 'a',
        help: 'All servers',
      );
  }

  @override
  final name = 'stop';

  @override
  final description = 'is used to stop tracking service in given server';

  @override
  FutureOr<String> run() async {
    final all = argResults['all'] as String;
    final instance = argResults['instance'] as String;
    if (all == null && instance == null) {
      usageException(red(' Instance name is missing'));
      return writeln(red(' Instance name is missing'), stderr);
    }
    writeln(highlight('> Stop tracking $instance...'), stdout);
    final status = await executeOn(
      instance,
      {
        'action': 'stop',
      },
      globalResults['verbose'] as bool,
    );
    writeln(status, stdout);
    return buffer.toString();
  }
}

class TrackingAddCommand extends TrackingCommandBase {
  TrackingAddCommand() {
    argParser
      ..addOption(
        'instance',
        abbr: 'i',
        help: 'Instance name',
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
  final description = 'is used to add tracking objects to given server';

  @override
  FutureOr<String> run() async {
    final instance = argResults['instance'] as String;
    if (instance == null) {
      usageException(red(' Instance name is missing'));
      return writeln(red(' Instance name is missing'), stderr);
    }
    final uuids = argResults['uuids'] as List<String>;
    if (uuids.isEmpty) {
      usageException(red(' Tracking uuids are missing'));
      return writeln(red(' Tracking uuids are missing'), stderr);
    }
    writeln(highlight('> Add trackings object to $instance...'), stdout);
    final status = await executeOn(
      instance,
      {
        'action': 'add_trackings',
        'uuids': uuids,
      },
      globalResults['verbose'] as bool,
    );
    writeln(status, stdout);
    return buffer.toString();
  }
}

class TrackingRemoveCommand extends TrackingCommandBase {
  TrackingRemoveCommand() {
    argParser
      ..addOption(
        'instance',
        abbr: 'i',
        help: 'Instance name',
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
  final description = 'is used to remove tracking objects from given server';

  @override
  FutureOr<String> run() async {
    final instance = argResults['instance'] as String;
    if (instance == null) {
      usageException(red(' Instance name is missing'));
      return writeln(red(' Instance name is missing'), stderr);
    }
    final uuids = argResults['uuids'] as List<String>;
    if (uuids.isEmpty) {
      usageException(red(' Tracking uuids are missing'));
      return writeln(red(' Tracking uuids are missing'), stderr);
    }
    writeln(highlight('> Remove trackings object from $instance...'), stdout);
    final status = await executeOn(
      instance,
      {
        'action': 'remove_trackings',
        'uuids': uuids,
      },
      globalResults['verbose'] as bool,
    );
    writeln(status, stdout);

    return buffer.toString();
  }
}
