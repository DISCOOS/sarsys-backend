import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:sarsys_ops_cli/src/aggregate.dart';

import 'auth.dart';
import 'core.dart';
import 'status.dart';
import 'tracking.dart';

Future<String> run(List<String> args) async {
  final runner = CommandRunner<String>(
    'sarsysctl',
    'Command line interface for monitoring and controlling SARSys backend modules',
  )
    ..addCommand(ListCommand())
    ..addCommand(AuthCommand())
    ..addCommand(StatusCommand())
    ..addCommand(AggregateCommand())
    ..addCommand(TrackingCommand())
    ..argParser.addOption(
      'config',
      abbr: 'c',
      help: 'Path to configuration file',
      defaultsTo: '${appDataDir}/config.yaml',
    )
    ..argParser.addOption(
      'output',
      abbr: 'o',
      defaultsTo: 'print',
      help: 'Output format',
      allowed: ['print', 'json'],
    )
    ..argParser.addFlag(
      'verbose',
      abbr: 'v',
      help: 'Verbose output',
    );
  ;

  return runner.run(args);
}

class ListCommand extends BaseCommand {
  ListCommand();

  @override
  final name = 'list';

  @override
  final description = 'is used to list module names';

  @override
  FutureOr<String> run() {
    writeln(highlight('> SARSys modules'), stdout);
    writeln('  ${green('sarsys-app-server')}', stdout);
    writeln('  ${green('sarsys-tracking-server')}', stdout);
    return buffer.toString();
  }
}
