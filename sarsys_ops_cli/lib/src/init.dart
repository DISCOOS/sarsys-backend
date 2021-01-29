import 'package:args/command_runner.dart';

import 'core.dart';

class InitCommand extends Command<String> {
  InitCommand() {
    argParser
      ..addOption(
        'config',
        defaultsTo: '${homeDir}/sarsysctl/config.yaml',
        abbr: 'c',
        help: 'Path to configuration file',
      );
  }

  @override
  final name = 'init';

  @override
  final description = 'init is used to initialize configuration';

  @override
  String run() {
    final buffer = StringBuffer();
    buffer.write('${argResults.name}');
    return buffer.toString();
  }
}
