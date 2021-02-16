import 'package:aqueduct/aqueduct.dart';
import 'package:sarsys_app_server/config.dart';
import 'package:sarsys_core/sarsys_core.dart';
import 'package:sarsys_tracking_server/sarsys_tracking_server.dart';

import '../sarsys_ops_server.dart' as sarsys;

class SarSysOpsConfig extends SarSysModuleConfig {
  SarSysOpsConfig(String path) : super.fromFile(path);

  /// Path OpenApi v3 to api specification
  String apiSpecPath = sarsys.apiSpecPath;

  /// The maximum size of a request body. Default is 10MB
  @requiredConfiguration
  int maxBodySize = 10;

  /// SARYs app server
  @requiredConfiguration
  SarSysAppConfig app;

  /// SARYs tracking server
  @requiredConfiguration
  SarSysTrackingConfig tracking;
}
