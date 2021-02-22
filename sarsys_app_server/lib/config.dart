import 'package:sarsys_app_server/sarsys_app_server.dart' as sarsys;

import 'sarsys_app_server.dart';

class SarSysAppConfig extends SarSysModuleConfig {
  SarSysAppConfig();
  SarSysAppConfig.fromFile(String path) : super.fromFile(path);

  /// App server URI as string
  @override
  String get url => '$scheme://$host:$port';

  /// Path OpenApi v3 to api specification
  String apiSpecPath = sarsys.apiSpecPath;

  /// App http server port
  @optionalConfiguration
  int port = 80;

  /// App grpc server port
  @optionalConfiguration
  int grpcPort = 8080;

  /// The maximum size of a request body. Default is 10MB
  @optionalConfiguration
  int maxBodySize = 10;

  /// Flag activating standalone mode.
  ///
  /// In standalone mode every service
  /// is running in same process,
  /// eliminating all external dependencies
  ///
  /// TODO: Implement EventFileStore
  @optionalConfiguration
  bool standalone = false;
}
