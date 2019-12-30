import 'package:sarsys_app_server/auth/oidc.dart';
import 'package:sarsys_app_server/controllers/health_controller.dart';
import 'package:sarsys_app_server/controllers/app_config_controller.dart';
import 'package:sarsys_app_server/domain/messages.dart';
import 'package:sarsys_app_server/eventsource/eventsource.dart';

import 'controllers/websocket_controller.dart';
import 'domain/app_config.dart';
import 'sarsys_app_server.dart';

/// MUST BE used when bootstrapping Aqueduct
const int isolateStartupTimeout = 120;

/// This type initializes an application.
///
/// Override methods in this class to set up routes and initialize services like
/// database connections. See http://aqueduct.io/docs/http/channel/.
class SarSysAppServerChannel extends ApplicationChannel {
  /// Validates oidc tokens against scopes
  final OIDCValidator validator = OIDCValidator();

  /// Channel responsible for distributing messages to client applications
  final MessageChannel messages = MessageChannel(
    handler: WebSocketMessageProcessor(),
  );

  /// Loaded in [prepare]
  SarSysConfig config;

  /// Manages an [EventStore] for each registered event stream
  EventSourceManager manager;

  /// Logger instance
  @override
  final Logger logger = Logger("SarSysAppServerChannel")
    ..onRecord.listen(
      printRecord,
    );

  /// Initialize services in this method.
  ///
  /// Implement this method to initialize services, read values from [options]
  /// and any other initialization required before constructing [entryPoint].
  ///
  /// This method is invoked prior to [entryPoint] being accessed.
  @override
  Future prepare() async {
    final stopwatch = Stopwatch()..start();

    // Parse from config file, given by --config to main.dart or default config.yaml
    config = SarSysConfig(options.configurationFilePath);
    if (config.debug == true) {
      logger.info("Debug mode enabled");
      if (Platform.environment.containsKey("NODE_NAME")) {
        logger.info("NODE_NAME is '${Platform.environment["NODE_NAME"]}'");
      }
      if (Platform.environment.containsKey("POD_NAME")) {
        logger.info("POD_NAME is '${Platform.environment["POD_NAME"]}'");
      }
    }

    // Set log level
    Logger.root.level = Level.LEVELS.firstWhere(
      (level) => level.name == config.level,
      orElse: () => Level.INFO,
    );
    logger.info("Log level set to ${Logger.root.level.name}");

    // Construct manager from configurations
    manager = EventSourceManager(
      MessageBus(),
      EventStoreConnection(
        host: config.eventstore.host,
        port: config.eventstore.port,
        credentials: UserCredentials(
          login: config.eventstore.login,
          password: config.eventstore.password,
        ),
      ),
      prefix: config.prefix,
    );

    // Register events handled by message broker
    messages.register<AppConfigCreated>(manager.bus);
    messages.register<AppConfigUpdated>(manager.bus);
    messages.build();

    // Register aggregate-root repositories
    manager.register<AppConfig>((store) => AppConfigRepository(store));
    await manager.build();
    logger.info("Built repositories in ${stopwatch.elapsedMilliseconds}ms");

    // Sanity check
    if (stopwatch.elapsed.inSeconds > isolateStartupTimeout * 0.8) {
      logger.severe("Approaching maximum duration to wait for each isolate to complete startup");
    }
  }

  /// Print [LogRecord] formatted
  static void printRecord(LogRecord rec) {
    print(
      "${rec.time}: ${rec.level.name}: ${rec.loggerName}: "
      "${rec.message} ${rec.error ?? ""} ${rec.stackTrace ?? ""}",
    );
  }

  /// Construct the request channel.
  ///
  /// Return an instance of some [Controller] that will be the initial receiver
  /// of all [Request]s.
  ///
  /// This method is invoked after [prepare].
  @override
  Controller get entryPoint {
    final authorizer = Authorizer.bearer(validator, scopes: [
      'roles:admin',
      'roles:commander',
      'roles:unit_leader',
      'roles:personnel',
    ]);
    return Router()
      ..route('/').link(() => authorizer)
      ..route('/api/*').link(
        () => FileController("web")
          ..addCachePolicy(
            const CachePolicy(preventCaching: true),
            (p) => p.endsWith("client.html"),
          ),
      )
      ..route('/api/healthz').link(() => HealthController())
      ..route('/api/messages/connect').link(() => WebSocketController(messages))
      ..route('/api/app-config[/:uuid]').link(() => AppConfigController(manager.get<AppConfigRepository>()));
  }

  @override
  void willStartReceivingRequests() {
    // Set k8s information for debugging purposes
    if (config.debug == true) {
      if (Platform.environment.containsKey("NODE_NAME")) {
        server.server.defaultResponseHeaders.add(
          "X-Node-Name",
          Platform.environment["NODE_NAME"],
        );
      }
      if (Platform.environment.containsKey("POD_NAME")) {
        server.server.defaultResponseHeaders.add(
          "X-Pod-Name",
          Platform.environment["POD_NAME"],
        );
      }
    }
  }

  @override
  Future close() {
    manager?.dispose();
    messages?.dispose();
    manager?.connection?.close();
    return super.close();
  }

  @override
  void documentComponents(APIDocumentContext registry) {
    registry.responses
      ..register(
          "201",
          APIResponse(
            "Created. The POST-ed resource was created.",
          ))
      ..register(
          "204",
          APIResponse(
            "No Content. The resource was updated.",
          ))
      ..register(
          "400",
          APIResponse(
            "Bad request. Request contains wrong or is missing required data",
          ))
      ..register(
          "401",
          APIResponse(
            "Unauthorized. The client must authenticate itself to get the requested response.",
          ))
      ..register(
          "403",
          APIResponse(
            "Forbidden. The client does not have access rights to the content.",
          ))
      ..register(
        "404",
        APIResponse("Not found. The requested resource does not exist in server."),
      )
      ..register(
          "405",
          APIResponse(
            "Method Not Allowed. The request method is known by the server but has been disabled and cannot be used.",
          ))
      ..register(
          "409",
          APIResponse(
            "Conflict. This response is sent when a request conflicts with the current state of the server.",
          ))
      ..register(
          "503",
          APIResponse(
            "Service unavailable. The server is not ready to handle the request. "
            "Common causes are a server that is down for maintenance or that is overloaded.",
          ));
    super.documentComponents(registry);
  }
}

class SarSysConfig extends Configuration {
  SarSysConfig(String path) : super.fromFile(File(path));

  /// Stream prefix
  @optionalConfiguration
  String prefix;

  /// Debug flag.
  ///
  /// Adds headers 'x-node-name' and 'x-pod-name' to
  /// responses from environment variables 'NODE_NAME'
  /// and 'POD_NAME', see k8s/sarsys.yaml
  @optionalConfiguration
  bool debug = false;

  /// Log level
  @optionalConfiguration
  String level = Level.INFO.name;

  /// [EventStore](www.eventstore.org) config values
  EvenStoreConfig eventstore;
}

class EvenStoreConfig extends Configuration {
  EvenStoreConfig();

  /// The host of the database to connect to.
  ///
  /// This property is required.
  String host;

  /// The port of the database to connect to.
  ///
  /// This property is required.
  int port;

  /// A username for authenticating to the database.
  ///
  /// This property is required.
  String login;

  /// A password for authenticating to the database.
  ///
  /// This property is required.
  String password;
}
