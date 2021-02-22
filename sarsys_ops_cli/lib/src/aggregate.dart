import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:meta/meta.dart';
import 'package:event_source/event_source.dart';
import 'package:sarsys_ops_cli/sarsys_ops_cli.dart';
import 'package:strings/strings.dart';
import 'package:timeago/timeago.dart' as tgo;

import 'core.dart';

class AggregateCommand extends BaseCommand {
  AggregateCommand() {
    addSubcommand(AggregateGetCommand());
    // addSubcommand(AggregateReplaceCommand());
    // addSubcommand(AggregateRemoveCommand());
    // addSubcommand(AggregateStartCommand());
    // addSubcommand(AggregateStopCommand());
  }

  @override
  final name = 'aggregate';

  @override
  final description = 'is used to manage aggregate instances';
}

abstract class AggregateCommandBase extends BaseCommand {
  Future<String> executeOn(
    String type,
    String uuid,
    String instance,
    Map<String, dynamic> args,
    bool verbose,
  ) async {
    final token = await AuthUtils.getToken(this);
    final expand = verbose ? '?expand=all' : '';
    final status = await post(
      client,
      '/ops/api/services/aggregate/$type/$uuid/$instance$expand',
      args,
      (result) {
        final buffer = StringBuffer();
        toInstanceStatus(
          type,
          result['meta'],
          buffer: buffer,
          verbose: verbose,
        );
        return buffer.toString();
      },
      token: token,
      format: (result) => result,
    );
    return status;
  }

  String toTypeStatus(String type, List items, {bool verbose = false}) {
    final buffer = StringBuffer();
    for (var instance in items.map((item) => Map.from(item))) {
      toInstanceStatus(
        type,
        instance,
        buffer: buffer,
        verbose: verbose,
      );
      buffer.writeln();
    }
    return buffer.toString();
  }

  void toInstanceStatus(
    String type,
    Map instance, {
    @required StringBuffer buffer,
    int indent = 2,
    bool verbose = false,
  }) {
    final uuid = instance.elementAt<String>('uuid', defaultValue: '');
    final separator = fill(max(uuid.length, 42) + 30, '-');
    final columns = separator.length;
    sprint(columns, buffer: buffer, format: highlight);
    vprint('Instance', instance.elementAt('name'), buffer: buffer);
    sprint(columns, buffer: buffer, format: highlight);
    if (uuid.isEmpty) {
      buffer.writeln('${fill(indent)}${red('${capitalize(type)} not found')}');
    } else {
      vprint(
        instance.elementAt('type'),
        uuid,
        unit: 'uuid',
        max: columns,
        buffer: buffer,
        indent: indent,
      );
      final createdWhen = instance.elementAt<DateTime>('createdBy/timestamp');
      vprint(
        'Created When',
        createdWhen.toIso8601String(),
        unit: 'event #${instance.elementAt('createdBy/number')}, ${tgo.format(createdWhen)}',
        max: columns,
        buffer: buffer,
        indent: indent,
      );
      final isDeleted = instance.hasPath('deletedBy');
      final changedBy = isDeleted ? 'deletedBy' : 'changedBy';
      final changedWhen = instance.elementAt<DateTime>('$changedBy/timestamp');
      vprint(
        isDeleted ? 'Deleted When' : 'Updated When',
        changedWhen.toIso8601String(),
        unit: 'event #${instance.elementAt('$changedBy/number')}, ${tgo.format(changedWhen)}',
        max: columns,
        buffer: buffer,
        indent: indent,
      );
      if (verbose) {
        final maxItems = 10;
        elPrint('applied', instance, maxItems, max: columns, indent: indent, buffer: buffer);
        elPrint('changed', instance, maxItems, max: columns, indent: indent, buffer: buffer);
        elPrint('skipped', instance, maxItems, max: columns, indent: indent, buffer: buffer);
        sprint(columns, buffer: buffer, format: gray);
        jPrint(instance, left: indent, buffer: buffer);
      } else {
        vprint(
          'States',
          instance.jointAt<int>(
            ['skipped/count', 'changed/count', 'applied/count'],
            separator: '/',
            defaultValue: 0,
          ),
          unit: 'skipped,changed,applied',
          max: columns,
          buffer: buffer,
          indent: indent,
        );
      }
    }
  }
}

class AggregateGetCommand extends AggregateCommandBase {
  AggregateGetCommand() {
    argParser
      ..addOption(
        'type',
        abbr: 't',
        help: 'Aggregate type name',
      )
      ..addOption(
        'uuid',
        abbr: 'u',
        help: 'Aggregate instance universal unique id',
      )
      ..addOption(
        'instance',
        abbr: 'i',
        help: 'Aggregate server instance name',
      );
  }

  @override
  final name = 'get';

  @override
  final description = 'is used to check tracking status';

  @override
  FutureOr<String> onJson() async {
    final type = argResults['type'] as String;
    if (type == null) {
      usageException(red(' Aggregate type is missing'));
      return writeln(red(' Aggregate type is missing'), stderr, force: true);
    }
    final uuid = argResults['uuid'] as String;
    if (uuid == null) {
      usageException(red(' Aggregate uuid is missing'));
      return writeln(red(' Aggregate uuid is missing'), stderr);
    }
    final token = await AuthUtils.getToken(this);
    final instance = argResults['instance'] as String;
    final uri = instance == null
        ? '/ops/api/services/aggregate/$type/$uuid?expand=data'
        : '/ops/api/services/aggregate/$type/$uuid/$instance?expand=data';
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
    // Sanity checks
    final type = argResults['type'] as String;
    if (type == null) {
      usageException(red(' Aggregate type is missing'));
      return writeln(red(' Aggregate type is missing'), stderr);
    }
    final uuid = argResults['uuid'] as String;
    if (uuid == null) {
      usageException(red(' Aggregate uuid is missing'));
      return writeln(red(' Aggregate uuid is missing'), stderr);
    }

    // Prepare
    final instance = argResults['instance'] as String;
    final verbose = globalResults['verbose'] as bool;
    final expand = verbose ? '?expand=all' : '';

    // Get metadata
    writeln(highlight('> Get ${capitalize(type)} $uuid'), stdout);
    final token = await AuthUtils.getToken(this);
    if (instance == null) {
      final statuses = await get(
        client,
        '/ops/api/services/aggregate/$type/$uuid$expand',
        (meta) => toTypeStatus(
          type,
          Map.from(meta).listAt('items'),
          verbose: verbose,
        ),
        token: token,
        format: (result) => result,
      );
      writeln(statuses, stdout);
    } else {
      final status = await get(
        client,
        '/ops/api/services/aggregate/$type/$uuid/$instance$expand',
        (meta) {
          final buffer = StringBuffer();
          toInstanceStatus(
            type,
            meta,
            buffer: buffer,
            verbose: verbose,
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

// class AggregateStartCommand extends AggregateCommandBase {
//   AggregateStartCommand() {
//     argParser
//       ..addOption(
//         'instance',
//         abbr: 'i',
//         help: 'Instance name',
//       )
//       ..addFlag(
//         'all',
//         abbr: 'a',
//         help: 'All servers',
//       );
//   }
//
//   @override
//   final name = 'start';
//
//   @override
//   final description = 'is used to start tracking service in given server';
//
//   @override
//   FutureOr<String> run() async {
//     final all = argResults['all'] as String;
//     final instance = argResults['instance'] as String;
//     if (all == null && instance == null) {
//       usageException(red(' Instance name is missing'));
//       return writeln(red(' Instance name is missing'), stderr);
//     }
//     writeln(highlight('> Start racking $instance...'), stdout);
//     final status = await executeOn(
//       instance,
//       {
//         'action': 'start',
//       },
//       globalResults['verbose'] as bool,
//     );
//     writeln(status, stdout);
//
//     return buffer.toString();
//   }
// }
//
// class AggregateStopCommand extends AggregateCommandBase {
//   AggregateStopCommand() {
//     argParser
//       ..addOption(
//         'instance',
//         abbr: 'i',
//         help: 'Instance name',
//       )
//       ..addFlag(
//         'all',
//         abbr: 'a',
//         help: 'All servers',
//       );
//   }
//
//   @override
//   final name = 'stop';
//
//   @override
//   final description = 'is used to stop tracking service in given server';
//
//   @override
//   FutureOr<String> run() async {
//     final all = argResults['all'] as String;
//     final instance = argResults['instance'] as String;
//     if (all == null && instance == null) {
//       usageException(red(' Instance name is missing'));
//       return writeln(red(' Instance name is missing'), stderr);
//     }
//     writeln(highlight('> Stop tracking $instance...'), stdout);
//     final status = await executeOn(
//       instance,
//       {
//         'action': 'stop',
//       },
//       globalResults['verbose'] as bool,
//     );
//     writeln(status, stdout);
//     return buffer.toString();
//   }
// }
//
// class AggregateReplaceCommand extends AggregateCommandBase {
//   AggregateReplaceCommand() {
//     argParser
//       ..addOption(
//         'instance',
//         abbr: 'i',
//         help: 'Instance name',
//       )
//       ..addMultiOption(
//         'uuids',
//         abbr: 'u',
//         help: 'List of tracking object uuids',
//       );
//   }
//
//   @override
//   final name = 'add';
//
//   @override
//   final description = 'is used to add tracking objects to given server';
//
//   @override
//   FutureOr<String> run() async {
//     final instance = argResults['instance'] as String;
//     if (instance == null) {
//       usageException(red(' Instance name is missing'));
//       return writeln(red(' Instance name is missing'), stderr);
//     }
//     final uuids = argResults['uuids'] as List<String>;
//     if (uuids.isEmpty) {
//       usageException(red(' Aggregate uuids are missing'));
//       return writeln(red(' Aggregate uuids are missing'), stderr);
//     }
//     writeln(highlight('> Add trackings object to $instance...'), stdout);
//     final status = await executeOn(
//       instance,
//       {
//         'action': 'add_trackings',
//         'uuids': uuids,
//       },
//       globalResults['verbose'] as bool,
//     );
//     writeln(status, stdout);
//     return buffer.toString();
//   }
// }
//
// class AggregateRemoveCommand extends AggregateCommandBase {
//   AggregateRemoveCommand() {
//     argParser
//       ..addOption(
//         'instance',
//         abbr: 'i',
//         help: 'Instance name',
//       )
//       ..addMultiOption(
//         'uuids',
//         abbr: 'u',
//         help: 'List of tracking object uuids',
//       );
//   }
//
//   @override
//   final name = 'remove';
//
//   @override
//   final description = 'is used to remove tracking objects from given server';
//
//   @override
//   FutureOr<String> run() async {
//     final instance = argResults['instance'] as String;
//     if (instance == null) {
//       usageException(red(' Instance name is missing'));
//       return writeln(red(' Instance name is missing'), stderr);
//     }
//     final uuids = argResults['uuids'] as List<String>;
//     if (uuids.isEmpty) {
//       usageException(red(' Aggregate uuids are missing'));
//       return writeln(red(' Aggregate uuids are missing'), stderr);
//     }
//     writeln(highlight('> Remove trackings object from $instance...'), stdout);
//     final status = await executeOn(
//       instance,
//       {
//         'action': 'remove_trackings',
//         'uuids': uuids,
//       },
//       globalResults['verbose'] as bool,
//     );
//     writeln(status, stdout);
//
//     return buffer.toString();
//   }
// }
