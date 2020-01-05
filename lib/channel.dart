import 'dart:convert';

import 'package:http/http.dart';
import 'package:sarsys_app_server/validation/validation.dart';

import 'auth/oidc.dart';
import 'controllers/app_config_controller.dart';
import 'controllers/health_controller.dart';
import 'controllers/incident_controller.dart';
import 'controllers/operation_controller.dart';
import 'controllers/websocket_controller.dart';
import 'domain/incident/incident.dart';
import 'domain/messages.dart';
import 'domain/operation/operation.dart' as sar;
import 'domain/tenant/app_config.dart';
import 'eventsource/eventsource.dart';

import 'sarsys_app_server.dart';

/// MUST BE used when bootstrapping Aqueduct
const int isolateStartupTimeout = 30;

/// Accepted ID token scopes
const List<String> scopes = [
  'roles:admin',
  'roles:commander',
  'roles:unit_leader',
  'roles:personnel',
];

/// Path to SarSys OpenAPI specification file
const String apiSpecPath = 'web/sarsys.json';

/// This type initializes an application.
///
/// Override methods in this class to set up routes and initialize services like
/// database connections. See http://aqueduct.io/docs/http/channel/.
class SarSysAppServerChannel extends ApplicationChannel {
  /// Validates oidc tokens against scopes
  final OIDCValidator authValidator = OIDCValidator();

  /// Channel responsible for distributing messages to client applications
  final MessageChannel messages = MessageChannel(
    handler: WebSocketMessageProcessor(),
  );

  /// Loaded in [prepare]
  SarSysConfig config;

  /// Validates requests against current open api specification
  RequestValidator requestValidator;

  /// Manages an [Repository] for each registered [AggregateRoot]
  RepositoryManager manager;

  /// Logger instance
  @override
  final Logger logger = Logger("SarSysAppServerChannel");

  /// Initialize services in this method.
  ///
  /// Implement this method to initialize services, read values from [options]
  /// and any other initialization required before constructing [entryPoint].
  ///
  /// This method is invoked prior to [entryPoint] being accessed.
  @override
  Future prepare() async {
    final stopwatch = Stopwatch()..start();

    _loadConfig();
    _configureLogger();
    _buildValidators();
    _buildRepoManager();
    _buildRepos(stopwatch);
    _buildMessageChannel();

    if (stopwatch.elapsed.inSeconds > isolateStartupTimeout * 0.8) {
      logger.severe("Approaching maximum duration to wait for each isolate to complete startup");
    }
  }

  /// Construct the request channel.
  ///
  /// Return an instance of some [Controller] that will be the initial receiverof all requests.
  ///
  /// This method is invoked after [prepare].
  @override
  Controller get entryPoint {
    // TODO: PassCodes - implement ReadModel and validation for all protected Aggregates

    final authorizer = Authorizer.bearer(authValidator, scopes: scopes);
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
      ..route('/api/app-configs[/:uuid]').link(() => AppConfigController(
            manager.get<AppConfigRepository>(),
            requestValidator,
          ))
      ..route('/api/incidents[/:uuid]').link(() => IncidentController(manager.get<IncidentRepository>()))
      ..route('/api/operations[/:uuid]').link(() => OperationController(manager.get<sar.OperationRepository>()));
  }

  @override
  void willStartReceivingRequests() {
    // Set k8s information for debugging purposes
    if (config.debug == true) {
      _setResponseFromEnv("TENANT", "X-Tenant");
      _setResponseFromEnv("PREFIX", "X-Prefix");
      _setResponseFromEnv("NODE_NAME", "X-Node-Name");
      _setResponseFromEnv("POD_NAME", "X-Pod-Name");
      _setResponseFromEnv("POD_NAMESPACE", "X-Pod-Namespace");
    }
  }

  void _loadConfig() {
    // Parse from config file, given by --config to main.dart or default config.yaml
    config = SarSysConfig(options.configurationFilePath);
    logger.onRecord.listen(
      (record) => printRecord(record, debug: config.debug),
    );

    if (config.debug == true) {
      logger.info("Debug mode enabled");
      if (Platform.environment.containsKey("PREFIX")) {
        logger.info("PREFIX is '${Platform.environment["PREFIX"]}'");
      }
      if (Platform.environment.containsKey("NODE_NAME")) {
        logger.info("NODE_NAME is '${Platform.environment["NODE_NAME"]}'");
      }
      if (Platform.environment.containsKey("POD_NAME")) {
        logger.info("POD_NAME is '${Platform.environment["POD_NAME"]}'");
      }
      if (Platform.environment.containsKey("POD_NAMESPACE")) {
        logger.info("POD_NAMESPACE is '${Platform.environment["POD_NAMESPACE"]}'");
      }
    }
    logger.info("TENANT is '${config.tenant == null ? 'not set' : '${config.tenant}'}'");
  }

  void _configureLogger() {
    Logger.root.level = Level.LEVELS.firstWhere(
      (level) => level.name == config.level,
      orElse: () => Level.INFO,
    );
    logger.info("Log level set to ${Logger.root.level.name}");
  }

  void _buildValidators() {
    final file = File(apiSpecPath);
    final spec = file.readAsStringSync();
    final data = json.decode(spec.isEmpty ? '{}' : spec);
    requestValidator = RequestValidator(data as Map<String, dynamic>);
  }

  void _buildRepoManager() {
    final namespace = EventStore.toCanonical([
      config.tenant,
      config.prefix,
    ]);

    // Construct manager from configurations
    manager = RepositoryManager(
      MessageBus(),
      EventStoreConnection(
        host: config.eventstore.host,
        port: config.eventstore.port,
        credentials: UserCredentials(
          login: config.eventstore.login,
          password: config.eventstore.password,
        ),
      ),
      prefix: namespace,
    );
  }

  void _buildMessageChannel() {
    messages.register<AppConfigCreated>(manager.bus);
    messages.register<AppConfigUpdated>(manager.bus);
    messages.register<IncidentRegistered>(manager.bus);
    messages.register<IncidentInformationUpdated>(manager.bus);
    messages.register<IncidentRespondedTo>(manager.bus);
    messages.register<IncidentCancelled>(manager.bus);
    messages.register<IncidentResolved>(manager.bus);
    messages.build();
  }

  void _buildRepos(Stopwatch stopwatch) {
    // Register repositories
    manager.register<AppConfig>((manager) => AppConfigRepository(manager));
    manager.register<Incident>((manager) => IncidentRepository(manager));
    manager.register<sar.Operation>((manager) => sar.OperationRepository(manager));

    // Defer repository builds so that isolates are not killed on eventstore connection timeouts
    Future.delayed(
      const Duration(milliseconds: 1),
      () => _buildReposWithRetries(stopwatch),
    );
  }

  void _buildReposWithRetries(Stopwatch stopwatch) async {
    /// Build resources
    try {
      await manager.build();
      logger.info("Built repositories in ${stopwatch.elapsedMilliseconds}ms => ready for aggregate requests!");
      return;
    } on ClientException catch (e) {
      logger.severe("Failed to connect to eventstore with ${manager.connection} with: $e => retrying in 2 seconds");
    } on SocketException catch (e) {
      logger.severe("Failed to connect to eventstore with ${manager.connection} with: $e => retrying in 2 seconds");
    }
    await Future.delayed(const Duration(seconds: 2), () => _buildReposWithRetries(stopwatch));
  }

  void _setResponseFromEnv(String name, String header) {
    if (Platform.environment.containsKey(name)) {
      server.server.defaultResponseHeaders.add(
        header,
        Platform.environment[name],
      );
    }
  }

  /// Print [LogRecord] formatted
  static void printRecord(LogRecord rec, {bool debug = false}) {
    print(
      "${rec.time}: ${rec.level.name}: "
      "${debug ? '${rec.loggerName}: ' : ''}"
      "${debug && Platform.environment.containsKey('POD-NAME') ? '${Platform.environment['POD-NAME']}: ' : ''}"
      "${rec.message} ${rec.error ?? ""} ${rec.stackTrace ?? ""}",
    );
  }

  @override
  Future close() {
    manager?.dispose();
    messages?.dispose();
    manager?.connection?.close();
    return super.close();
  }

  //////////////////////////////////
  // Documentation
  //////////////////////////////////

  @override
  void documentComponents(APIDocumentContext registry) {
    documentResponses(registry);
    registry.schema.register('PassCodes', documentPassCodes());
    super.documentComponents(registry);
  }

  // TODO: Use https://pub.dev/packages/password to hash pass codes in streams?
  APISchemaObject documentPassCodes() => APISchemaObject.object(
        {
          "commander": APISchemaObject.string()..description = "Passcode for access with Commander rights",
          "personnel": APISchemaObject.string()..description = "Passcode for access with Personnel rights",
        },
      )
        ..description = "Pass codes for access rights to spesific Incident instance"
        ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
        ..required = [
          'commander',
          'personnel',
        ];

  APIComponentCollection<APIResponse> documentResponses(APIDocumentContext registry) {
    return registry.responses
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
  }
}
