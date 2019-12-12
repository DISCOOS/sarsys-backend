import 'dart:math';

import 'package:args/args.dart';
import 'package:sarsys_app_server/sarsys_app_server.dart';

Future main(List<String> args) async {
  final parser = ArgParser()
    ..addOption("port", defaultsTo: "80", abbr: "p")
    ..addOption("config", defaultsTo: "config.yaml", abbr: "c")
    ..addOption("instances", defaultsTo: "1", abbr: "i");
  final results = parser.parse(args);
  final app = Application<SarSysAppServerChannel>()
    ..options.configurationFilePath = results['config'] as String
    ..options.port = int.tryParse(results['port'] as String) ?? 8888;

  final count = min(
    Platform.numberOfProcessors ~/ 2,
    int.tryParse(results['instances'] as String) ?? 1,
  );
  await app.start(numberOfInstances: count > 0 ? count : 1);

  print("Application started on port: ${app.options.port}.");
  print("Use Ctrl-C (SIGINT) to stop running the application.");
}
