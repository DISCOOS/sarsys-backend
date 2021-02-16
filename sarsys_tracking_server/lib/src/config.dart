import 'package:sarsys_core/sarsys_core.dart';

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
  @optionalConfiguration
  int grpcPort = 8082;

  /// Tracking server health check port
  @optionalConfiguration
  int healthPort = 8083;
}
