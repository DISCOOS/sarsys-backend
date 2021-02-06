import 'package:sarsys_http_core/sarsys_http_core.dart';

class SarSysTrackingConfig extends SarSysModuleConfig {
  SarSysTrackingConfig();
  SarSysTrackingConfig.fromFile(String path) : super.fromFile(path);

  /// App server health URI as string
  @override
  String get url => '$scheme://$host:$healthPort';

  /// TrackingService will start to compete on build
  @optionalConfiguration
  bool startup = true;

  /// Tracking server grpc port
  @requiredConfiguration
  int grpcPort = 8082;

  /// Tracking server health check port
  @requiredConfiguration
  int healthPort = 8083;
}
