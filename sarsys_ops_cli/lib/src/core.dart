import 'dart:io';

import 'package:args/args.dart';
import 'package:ansicolor/ansicolor.dart';
import 'package:dart_app_data/dart_app_data.dart';

final highlight = AnsiPen()..gray();
final red = AnsiPen()..green(bold: true);
final gray = AnsiPen()..gray(level: 0.5);
final green = AnsiPen()..green(bold: true);

String get homeDir {
  var home = '';
  final envVars = Platform.environment;
  if (Platform.isMacOS) {
    home = envVars['HOME'];
  } else if (Platform.isLinux) {
    home = envVars['HOME'];
  } else if (Platform.isWindows) {
    home = envVars['UserProfile'];
  }
  return home;
}

String get appDataDir {
  return AppData.findOrCreate('sarsysctl').directory.path;
}

AppData findOrCreateDataDir(String name) {
  return AppData.findOrCreate(name);
}

String usage(String command, String description, ArgParser parser, [List<String> commands]) {
  final buffer = StringBuffer();
  final withCommands = commands?.isNotEmpty == true;
  buffer.writeln(description);
  buffer.writeln();
  buffer.writeln('Usage:');
  buffer.writeln('  $command ${withCommands ? '[command] ' : ''}[options]');
  buffer.writeln();
  if (withCommands) {
    buffer.writeln('Available commands:');
    commands..map((l) => '  $l').forEach(buffer.writeln);
    buffer.writeln();
  }
  buffer.writeln('Global options:');
  buffer.writeln(parser.usage.split('\n').map((l) => '  $l').join('\n'));
  return buffer.toString();
}
