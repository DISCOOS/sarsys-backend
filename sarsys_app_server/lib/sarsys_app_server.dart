// @dart=2.10

/// sarsys_app_server
///
/// A Aqueduct web server.
library sarsys_app_server;

export 'package:sarsys_core/sarsys_core.dart';

export 'config.dart';
export 'controllers/domain/controllers.dart';
export 'controllers/domain/schemas.dart';
export 'controllers/domain/track_request_utils.dart';
export 'controllers/tenant/controllers.dart';

export 'sarsys_app_channel.dart';

/// Path to SarSys OpenAPI specification file
const String apiSpecPath = 'web/sarsys-app.json';
