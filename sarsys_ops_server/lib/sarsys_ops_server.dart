/// sarsys_ops_server
///
/// SARSys ops server.
library sarsys_ops_server;

export 'package:sarsys_core/sarsys_core.dart';

export 'sarsys_ops_channel.dart';
export 'src/k8s/k8s_api.dart';
export 'src/schemas.dart';

/// Path to SARSys Ops OpenAPI specification file
const String apiSpecPath = 'web/sarsys-ops.json';
