import 'package:args/command_runner.dart';

class AuthCommand extends Command<String> {
  AuthCommand() {
    // argParser.addFlag(
    //   'help',
    //   abbr: 'h',
    //   negatable: false,
    //   help: 'Displays this help information.',
    // );
  }

  @override
  final name = 'auth';

  @override
  final description = 'auth is used to authenticate the user';

  @override
  String run() {
    final buffer = StringBuffer();
    buffer.write('${argResults.name}');
    return buffer.toString();
  }
}
