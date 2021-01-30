import 'dart:convert';

import 'package:event_source/event_source.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart';
import 'package:jose/jose.dart';
import 'package:meta/meta.dart';
import 'package:aqueduct/aqueduct.dart' as aq;
import 'package:sarsys_ops_server/src/k8s/k8s_api.dart';
import 'package:stack_trace/stack_trace.dart';
import 'package:uuid/uuid.dart';

import 'sarsys_ops_server.dart';
import 'src/schemas.dart';

/// MUST BE used when bootstrapping Aqueduct
const int isolateStartupTimeout = 30;

const List<String> allScopes = [
  'roles:admin',
];

/// Path to SARSys Ops OpenAPI specification file
const String apiSpecPath = 'web/sarsys-ops.json';

/// This type initializes an application.
///
/// Override methods in this class to set up routes and initialize services like
/// database connections. See http://aqueduct.io/docs/http/channel/.
class SarSysOpsServerChannel extends ApplicationChannel {
  /// Loaded in [prepare]
  SarSysConfig config;

  /// Validates requests against current open api specification
  JsonValidation requestValidator;

  /// Secure router enforcing authorization
  SecureRouter router;

  /// Logger instance
  @override
  final Logger logger = Logger("SarSysOpsServerChannel");

  static RemoteLogger _remoteLogger;

  /// Print [LogRecord] formatted
  static void printRecord(LogRecord rec, {bool debug = false, bool stdout = false}) {
    if (stdout) {
      Context.printRecord(rec, debug: debug);
    }
    _remoteLogger?.log(rec);
  }

  /// Initialize services in this method.
  ///
  /// Implement this method to initialize services, read values from [options]
  /// and any other initialization required before constructing [entryPoint].
  ///
  /// This method is invoked prior to [entryPoint] being accessed.
  @override
  Future prepare() async {
    try {
      final stopwatch = Stopwatch()..start();

      _loadConfig();
      _initHive();
      _configureLogger();
      _buildValidators();
      await _configureK8sApi();
      await _buildSecureRouter();

      if (stopwatch.elapsed.inSeconds > isolateStartupTimeout * 0.8) {
        logger.severe(
          "Approaching maximum duration to wait for each isolate to complete startup",
        );
      }
    } catch (e, stackTrace) {
      _terminateOnFailure(e, stackTrace);
    }
  }

  /// Construct the request channel.
  ///
  /// Return an instance of some [Controller] that will be the initial receiver of all requests.
  ///
  /// This method is invoked after [prepare].
  @override
  Controller get entryPoint {
    return router
      ..route('/ops/api/*').link(
        () => DocumentController(),
      )
      ..route('/ops/api/healthz/alive').link(() => LivenessController())
      ..route('/ops/api/healthz/ready').link(() => LivenessController());
  }

  @override
  void willStartReceivingRequests() {
    // Set k8s information for debugging purposes
    if (config.debug == true) {
      _setResponseFromEnv("IMAGE", "X-Image");
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
    RequestBody.maxSize = 1024 * 1024 * config.maxBodySize;
    logger.onRecord.listen(
      (record) => printRecord(
        record,
        debug: config.debug,
        stdout: config.logging.stdout,
      ),
    );

    logger.info("EVENTSTORE_HOST is ${config.eventstore.host}");
    logger.info("EVENTSTORE_PORT is ${config.eventstore.port}");
    logger.info("EVENTSTORE_LOGIN is ${config.eventstore.login}");
    logger.info("EVENTSTORE_REQUIRE_MASTER is ${config.eventstore.requireMaster}");

    if (config.debug == true) {
      logger.info("Debug mode enabled");
      if (Platform.environment.containsKey("IMAGE")) {
        logger.info("IMAGE is '${Platform.environment["IMAGE"]}'");
      }
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

    logger.info("AUTHORIZATION is ${config.auth.enabled ? 'ENABLED' : 'DISABLED'}");
    if (config.auth.enabled) {
      logger.info("OpenID Connect Provider BASE URL is ${config.auth.baseUrl}");
      logger.info("OpenID Connect Provider Issuer is ${config.auth.issuer}");
      logger.info("OpenID Connect Provider Audience is ${config.auth.audience}");
      logger.info("OpenID Connect Provider Roles Claims are ${config.auth.rolesClaims}");
    }

    // Ensure that data path exists?
    if (config.data.enabled) {
      final dir = Directory(config.data.path);
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
        logger.info("Created data path ${config.data.path}");
      } else {
        logger.info("Data path is ${config.data.path}");
      }
      if (config.data.snapshots.enabled) {
        logger.info("Snapshot keep is ${config.data.snapshots.keep}");
        logger.info("Snapshot threshold is ${config.data.snapshots.threshold}");
      } else {
        logger.info("Snapshots DISABLED");
      }
    } else {
      logger.info("Data is DISABLED");
    }
  }

  void _configureLogger() {
    Logger.root.level = LoggerConfig.toLevel(
      config.logging.level,
    );
    logger.info("Server log level set to ${Logger.root.level.name}");
    if (config.logging.sentry != null) {
      _remoteLogger = RemoteLogger(config);
      logger.info("Sentry DSN is ${config.logging.sentry.dsn}");
      logger.info("Sentry log level set to ${_remoteLogger.level}");
    }
  }

  Future<bool> _configureK8sApi() async {
    final k8s = K8sApi();
    final ok = await k8s.check();
    final pods = await k8s.getPodNamesFromNs(
      k8s.namespace,
    );
    logger.info("PODS: ${pods.toList()}");
    return ok;
  }

  void _buildValidators() {
    final file = File(apiSpecPath);
    final spec = file.readAsStringSync();
    final data = json.decode(spec.isEmpty ? '{}' : spec);
    requestValidator = JsonValidation(data as Map<String, dynamic>);
  }

  void _initHive() {
    final enabled = options.context.elementAt<bool>(
      'data_enabled',
      defaultValue: config.data.enabled,
    );
    if (enabled) {
      final path = options.context.elementAt<String>(
        'data_path',
        defaultValue: config.data.path,
      );
      final hiveDir = Directory(path);
      hiveDir.createSync(recursive: true);
      Hive.init(hiveDir.path);
    }
  }

  void _terminateOnFailure(Object error, StackTrace stackTrace) {
    logger.severe(
      "Failed to build repositories: $error: $stackTrace",
      error,
      Trace.from(stackTrace),
    );
    logger.severe(
      "Terminating server safely...",
      error,
      Trace.from(stackTrace),
    );
    server.close();
  }

  Future _buildSecureRouter() async {
    router = SecureRouter(
      config.auth,
    );
    if (config.auth.enabled) {
      await router.prepare();
    }
  }

  void _setResponseFromEnv(String name, String header) {
    if (Platform.environment.containsKey(name)) {
      server.server.defaultResponseHeaders.add(
        header,
        Platform.environment[name],
      );
    }
  }

  //////////////////////////////////
  // Documentation
  //////////////////////////////////

  @override
  void documentComponents(APIDocumentContext context) {
    documentResponses(context);
    documentSchemas(context);
    documentSecuritySchemas(context);
    super.documentComponents(context);
  }

  APIComponentCollection<APIResponse> documentResponses(APIDocumentContext registry) {
    return registry.responses
      ..register(
          "200",
          APIResponse(
            "OK. Indicates that the request has succeeded. A 200 response is cacheable by default. "
            "The meaning of a success depends on the HTTP request method.",
          ))
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
          APIResponse(
            "Not found. The requested resource does not exist in server.",
          ))
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
          "416",
          APIResponse(
            "Range Not Satisfiable. Indicates that a server cannot serve the requested ranges. "
            "The most likely reason is that the document doesn't contain such ranges, "
            "or that the Range header value, though syntactically correct, doesn't make sense.",
          ))
      ..register(
          "426",
          APIResponse(
            "Source or destination resource of a method is locked. Indicates that resource is read-only.",
          ))
      ..register(
          "429",
          APIResponse(
            "Too Many Requests. Indicates the user has sent too many requests in a given amount of time "
            "('rate limiting'). A Retry-After header might be included to this response indicating "
            "how long to wait before making a new request.",
          ))
      ..register(
          "500",
          APIResponse(
            "Internal Server Error. indicates that the server encountered an unexpected condition "
            "that prevented it from fulfilling the request. This error response is a generic 'catch-all' response",
          ))
      ..register(
          "503",
          APIResponse(
            "Service unavailable. The server is currently unable to handle the request due to a temporary "
            "overloading or maintenance of the server. The implication is that this is a temporary "
            "condition which will be alleviated after some delay. If known, the length of the delay MAY be "
            "indicated in a Retry-After header.",
          ))
      ..register(
          "504",
          APIResponse(
            "Gateway Timeout server. Indicates that the server, while acting as a gateway or proxy, "
            "did not get a response in time from the upstream server that it needed in order to complete the request.",
          ));
  }

  void documentSecuritySchemas(APIDocumentContext context) => context.securitySchemes
    ..register(
        'OpenId Connect',
        APISecurityScheme.openID(
          Uri.parse(
            '${config.auth?.baseUrl ?? 'https://id.discoos.io/auth/realms/DISCOOS'}/.well-known/openid-configuration',
          ),
        ));

  void documentSchemas(APIDocumentContext context) => context.schema
    ..register('ID', documentID())
    ..register('UUID', documentUUID())
    ..register('ServerStatus', documentServerStatus());
}

class RequestContext {
  const RequestContext({
    @required this.correlationId,
    @required this.transactionId,
    @required this.inStickySession,
  });

  /// Get current correlation. A correlation id
  /// is created if header 'x-correlation-id'
  /// was missing.
  final String correlationId;

  /// Check if current request is in a sticky session
  final bool inStickySession;

  /// Get transaction id sticky session
  final String transactionId;
}

class SecureRouter extends Router {
  SecureRouter(this.config) : keyStore = JsonWebKeyStore();
  final AuthConfig config;
  final JsonWebKeyStore keyStore;
  final Map<String, RequestContext> _contexts = {};

  Map<String, RequestContext> getContexts() => Map.unmodifiable(_contexts);
  RequestContext getContext(String correlationId) => _contexts[correlationId];
  bool hasContext(String correlationId) => _contexts.containsKey(correlationId);

  Future<RequestOrResponse> setRequest(aq.Request request) async {
    final correlationId = request.raw.headers.value('x-correlation-id') ?? Uuid().v4();
    final transactionId = request.raw.cookies
        // Find cookie for sticky session
        .where((c) => c.name == 'x-transaction-id')
        // Get transaction id
        .map((c) => c.value)
        .firstOrNull;
    final inStickySession = transactionId != null;
    request.addResponseModifier((r) {
      r.headers['x-correlation-id'] = correlationId;
      _contexts.remove(correlationId);
    });
    _contexts[correlationId] = RequestContext(
      correlationId: correlationId,
      transactionId: transactionId,
      inStickySession: inStickySession,
    );
    return request;
  }

  Future prepare() async {
    if (config.enabled) {
      final response = await get('${config.baseUrl}/.well-known/openid-configuration');
      final body = json.decode(response.body) as Map<String, dynamic>;
      if (body is Map<String, dynamic>) {
        if (body.containsKey('jwks_uri')) {
          keyStore.addKeySetUrl(Uri.parse(body['jwks_uri'] as String));
          return;
        }
      }
      throw 'Unexpected response from OpenID Connect Provider ${config.baseUrl}: $body';
    }
  }

  void secure(String pattern, Controller creator()) {
    super.route(pattern).linkFunction(setRequest).link(authorizer).link(creator);
  }

  Controller authorizer() {
    if (config.enabled) {
      return Authorizer.bearer(
        AccessTokenValidator(
          keyStore,
          config,
        ),
        scopes: config.required,
      );
    }
    return AnyAuthorizer(config.required, [
      'roles:admin',
    ]);
  }
}
