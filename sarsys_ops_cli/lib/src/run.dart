import 'package:args/command_runner.dart';

import 'auth.dart';
import 'core.dart';
import 'status.dart';
import 'tracking.dart';

Future<String> run(List<String> args) async {
  final runner = CommandRunner<String>(
    'sarsysctl',
    'Command line interface for monitoring and controlling SARSys backend modules',
  )
    ..addCommand(AuthCommand())
    ..addCommand(StatusCommand())
    ..addCommand(TrackingCommand())
    ..argParser.addOption(
      'config',
      abbr: 'c',
      help: 'Path to configuration file',
      defaultsTo: '${appDataDir}/config.yaml',
    );
  ;

  return runner.run(args);
}
