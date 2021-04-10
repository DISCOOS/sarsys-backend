// @dart=2.10
import 'package:args/args.dart';
import 'package:sarsys_core/sarsys_core.dart';
import 'package:sarsys_tracking_server/sarsys_tracking_server.dart';

Future main(List<String> args) async {
  stdout.writeln('Starting server with args $args...');
  final parser = ArgParser()
    ..addOption("timeout", defaultsTo: "30")
    ..addOption("training", defaultsTo: "false")
    ..addOption("healthPort", defaultsTo: "8082")
    ..addOption("grpcPort", defaultsTo: "8083", abbr: "p")
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
    stdout.writeln("Snapshot training, stopping...");
    await server.stop();
    exit(0);
  }
  await request;

  stdout.writeln(
      "Server started with ports {health: ${results['healthPort']}, grpc: ${results['grpcPort']}}.");
  stdout.writeln("Use Ctrl-C (SIGINT) to stop running the server.");
}
