import 'package:sarsys_app_server/auth/access_validator.dart';
import 'package:sarsys_app_server/controllers/health_controller.dart';
import 'package:sarsys_app_server/controllers/app_config_controller.dart';
import 'package:sarsys_app_server/eventstore/eventstore.dart';

import 'controllers/websocket_controller.dart';
import 'domain/app_config.dart';
import 'sarsys_app_server.dart';

/// This type initializes an application.
///
/// Override methods in this class to set up routes and initialize services like
/// database connections. See http://aqueduct.io/docs/http/channel/.
class SarSysAppServerChannel extends ApplicationChannel {
  /// Validates oidc tokens against scopes
  final AccessValidator validator = AccessValidator();

  /// Manages an [EventStore] for each registered event stream
  final EventStoreManager manager = EventStoreManager(MessageBus(), EventStoreConnection());

  /// Channel responsible for distributing messages to client applications
  final MessageChannel messages = MessageChannel();

  /// Initialize services in this method.
  ///
  /// Implement this method to initialize services, read values from [options]
  /// and any other initialization required before constructing [entryPoint].
  ///
  /// This method is invoked prior to [entryPoint] being accessed.
  @override
  Future prepare() async {
    final stopwatch = Stopwatch()..start();
    logger.onRecord.listen(
      (rec) => print("$rec ${rec.error ?? ""} ${rec.stackTrace ?? ""}"),
    );

    // Register event handled by message broker
    messages.register<AppConfigCreated>(manager.bus);
    messages.register<AppConfigUpdated>(manager.bus);

    // Register repositories
    manager.register<AppConfig>((store) => AppConfigRepository(store));
    await manager.build();
    logger.info("Built repositories in ${stopwatch.elapsedMilliseconds}ms");

    // Sanity check
    if (stopwatch.elapsed.inSeconds > 25) {
      logger.severe("Approaching maximum duration to wait for each isolate to complete startup");
    }
  }

  /// Construct the request channel.
  ///
  /// Return an instance of some [Controller] that will be the initial receiver
  /// of all [Request]s.
  ///
  /// This method is invoked after [prepare].
  @override
  Controller get entryPoint {
    final authorizer = Authorizer.bearer(validator);
    return Router()
      ..route('/').link(() => authorizer)
      ..route('/api/*').link(() => FileController("web"))
      ..route('/api/healthz').link(() => HealthController())
      ..route('/api/app-config[/:id]').link(() => AppConfigController(manager.get<AppConfig>()))
      ..route('/api/connect').link(() => WebSocketController(messages));
//      ..route('/api/connect').linkFunction((request) async {
//        final socket = await WebSocketTransformer.upgrade(request.raw);
//        final data = await request.raw.headers;
//        if (data != null && data['appId'] is String) {
//          messages.subscribe(data['appId'] as String, socket);
//        } else {
//          await socket.close(WebSocketStatus.protocolError, "Expected 'appId', none found");
//        }
//        return null;
//      });
  }

  @override
  Future close() {
    manager?.dispose();
    messages?.dispose();
    manager?.connection?.close();
    return super.close();
  }
}
