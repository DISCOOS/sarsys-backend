import 'dart:math';

import 'package:args/args.dart';
import 'package:sarsys_app_server/sarsys_app_server.dart';

Future main(List<String> args) async {
  final logger = Logger("main")
    ..onRecord.listen(
      SarSysAppServerChannel.printRecord,
    );
  final parser = ArgParser()
    ..addOption("port", defaultsTo: "80", abbr: "p")
    ..addOption("config", defaultsTo: "config.yaml", abbr: "c")
    ..addOption("instances", defaultsTo: "1", abbr: "i")
    ..addOption("timeout", defaultsTo: "30")
    ..addOption("training", defaultsTo: "false");
  final results = parser.parse(args);
  final training = (results['training'] as String).toLowerCase() == "true";
  final app = Application<SarSysAppServerChannel>()
    ..isolateStartupTimeout = const Duration(seconds: isolateStartupTimeout)
    ..options.configurationFilePath = results['config'] as String
    ..options.port = int.tryParse(results['port'] as String) ?? 8888;

  final count = min(
    Platform.numberOfProcessors ~/ 2,
    int.tryParse(results['instances'] as String) ?? 1,
  );
  await app.start(numberOfInstances: count > 0 ? count : 1);

  logger.info("Application started on port: ${app.options.port}.");
  if (training) {
    logger.info("Snapshot training, stopping...");
    await app.stop();
  }
  logger.info("Use Ctrl-C (SIGINT) to stop running the application.");
}
