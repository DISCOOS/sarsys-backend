import 'package:args/command_runner.dart';

import 'auth.dart';
import 'init.dart';
import 'status.dart';

Future<String> run(List<String> args) async {
  final runner = CommandRunner<String>(
    'sarsysctl',
    'Command line interface for monitoring and controlling SARSys backend modules',
  )
    ..addCommand(InitCommand())
    ..addCommand(AuthCommand())
    ..addCommand(StatusCommand());

  return runner.run(args);
}
