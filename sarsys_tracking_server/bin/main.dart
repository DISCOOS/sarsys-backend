import 'package:args/args.dart';
import 'package:logging/logging.dart';
import 'package:sarsys_http_core/sarsys_http_core.dart';
import 'package:sarsys_tracking_server/sarsys_tracking_server.dart';

Future main(List<String> args) async {
  final logger = Logger("main")
    ..onRecord.listen(
      SarSysTrackingServer.printRecord,
    );
  final parser = ArgParser()
    ..addOption("timeout", defaultsTo: "30")
    ..addOption("training", defaultsTo: "false")
    ..addOption("healthPort", defaultsTo: "80")
    ..addOption("grpcPort", defaultsTo: "8080", abbr: "p")
    ..addOption("config", defaultsTo: "config.yaml", abbr: "c");

  final results = parser.parse(args);
  final training = (results['training'] as String).toLowerCase() == "true";

  final server = SarSysTrackingServer();
  final config = SarSysTrackingConfig.fromFile(
    results['config'],
  );
  config.grpcPort = int.parse(results['grpcPort']);
  config.healthPort = int.parse(results['healthPort']);
  final request = server.start(
    config,
  );

  if (training) {
    logger.info("Snapshot training, stopping...");
    await server.stop();
    exit(0);
  }
  await request;

  logger.info("Server started on port: ${results['port']}.");
  logger.info("Use Ctrl-C (SIGINT) to stop running the server.");
}
