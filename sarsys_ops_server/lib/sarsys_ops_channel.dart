import 'dart:convert';

import 'package:event_source/event_source.dart';
import 'package:grpc/grpc.dart';
import 'package:hive/hive.dart';
import 'package:sarsys_ops_server/src/controllers/module_status_controller.dart';
import 'package:sarsys_ops_server/src/controllers/snapshot_grpc_file_service_controller.dart';
import 'package:sarsys_ops_server/src/controllers/snapshot_grpc_service_controller.dart';
import 'package:sarsys_ops_server/src/k8s/k8s_api.dart';
import 'package:stack_trace/stack_trace.dart';

import 'sarsys_ops_server.dart';
import 'src/config.dart';
import 'src/controllers/aggregate_grpc_service_controller.dart';
import 'src/controllers/repository_grpc_service_controller.dart';
import 'src/controllers/tracking_grpc_service_controller.dart';

/// MUST BE used when bootstrapping Aqueduct
const int isolateStartupTimeout = 30;

const List<String> allScopes = [
  'roles:admin',
];

/// This initializes a SARSys http backend ops server
class SarSysOpsServerChannel extends SarSysServerChannelBase {
  /// Loaded in [prepare]
  SarSysOpsConfig config;

  /// Validates requests against current open api specification
  JsonValidation requestValidator;

  /// Secure router enforcing authorization
  SecureRouter router;

  /// K8s Api instance
  K8sApi k8s;

  /// Grpc channels
  final Map<String, ClientChannel> channels = {};

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
      _buildValidators();
      await _configureK8sApi();
      await _buildSecureRouter();

      if (stopwatch.elapsed.inSeconds > isolateStartupTimeout * 0.8) {
        logger.severe(
          "Approaching maximum duration to wait for each isolate to complete startup",
        );
      }
    } catch (e, stackTrace) {
      await _terminateOnFailure(e, stackTrace);
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
      ..route('/ops/api/healthz/ready').link(() => LivenessController())
      ..secure(
        '/ops/api/system/status[/:name]',
        () => ModuleStatusController(k8s, config),
      )
      ..secure(
        '/ops/api/services/aggregate/:type/:uuid[/:name]',
        () => AggregateGrpcServiceController(
          k8s,
          channels,
          config,
          options.context,
        ),
      )
      ..secure(
        '/ops/api/services/repository/:type[/:name]',
        () => RepositoryGrpcServiceController(
          k8s,
          channels,
          config,
          options.context,
        ),
      )
      ..secure(
        '/ops/api/services/snapshot/:type[/:name]',
        () => SnapshotGrpcServiceController(
          k8s,
          channels,
          config,
          options.context,
        ),
      )
      ..secure(
        '/ops/api/services/snapshot/upload/:type[/:name]',
        () => SnapshotGrpcFileServiceController(
          k8s,
          channels,
          config,
          options.context,
        ),
      )
      ..secure(
        '/ops/api/services/snapshot/download/:type/:name',
        () => SnapshotGrpcFileServiceController(
          k8s,
          channels,
          config,
          options.context,
        ),
      )
      ..secure(
        '/ops/api/services/tracking[/:name]',
        () => TrackingGrpcServiceController(
          k8s,
          channels,
          config,
          options.context,
        ),
      );
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
    // Parse from config file, given by --config to document.dart or default config.yaml
    config = SarSysOpsConfig(options.configurationFilePath);

    // Overwrite config with values from context
    _writeContextOnConfig();

    // Set maximum content size
    RequestBody.maxSize = 1024 * 1024 * config.app.maxBodySize;

    // Configure logging
    final level = LoggerConfig.toLevel(
      config.logging.level,
    );
    Logger.root.level = level;
    logger.onRecord.where((event) => logger.level >= level).listen(
          (record) => printRecord(
            record,
            debug: config.debug,
            stdout: config.logging.stdout,
          ),
        );
    logger.info("Server log level set to ${Logger.root.level.name}");
    if (config.logging.sentry != null) {
      _remoteLogger = RemoteLogger(
        config.logging.sentry,
        config.tenant,
      );
      logger.info("Sentry DSN is ${config.logging.sentry.dsn}");
      logger.info("Sentry log level set to ${_remoteLogger.level}");
    }

    _logModuleConfig('APP', config.app);
    _logModuleConfig('TRACKING', config.tracking);

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

  void _writeContextOnConfig() {
    config.debug = _propertyAt<bool>('DEBUG', config.debug);
    config.prefix = _propertyAt<String>('PREFIX', config.prefix);
    config.tenant = _propertyAt<String>('TENANT', config.tenant);
    config.maxBodySize = _propertyAt<int>('MAX_BODY_SIZE', config.maxBodySize);
    config.apiSpecPath = _propertyAt<String>('API_SPEC_PATH', config.apiSpecPath);

    config.logging?.level = _propertyAt<String>('LOG_LEVEL', config.logging?.level);
    config.logging?.stdout = _propertyAt<bool>('LOG_STDOUT', config.logging?.stdout);
    config.logging?.sentry?.level = _propertyAt<String>(
      'LOG_SENTRY_LEVEL',
      config.logging?.sentry?.level,
    );
    config.logging?.sentry?.dsn = _propertyAt<String>(
      'LOG_SENTRY_DSN',
      config.logging?.sentry?.dsn,
    );

    config.auth?.enabled = _propertyAt<bool>('AUTH_ENABLED', config.auth?.enabled);
    config.auth?.audience = _propertyAt<String>('AUTH_AUDIENCE', config.auth?.audience);
    config.auth?.issuer = _propertyAt<String>('AUTH_ISSUER', config.auth?.issuer);
    config.auth?.baseUrl = _propertyAt<String>('AUTH_BASE_URL', config.auth?.baseUrl);

    config.data.enabled = _propertyAt<bool>('DATA_ENABLED', config.data?.enabled);
    config.data.path = _propertyAt<String>('DATA_PATH', config.data?.path);

    // Disable (not in use)
    config.data.snapshots = SnapshotsConfig();

    config.eventstore?.scheme = _propertyAt<String>(
      'EVENTSTORE_SCHEME',
      config.eventstore?.scheme,
    );
    config.eventstore?.host = _propertyAt<String>(
      'EVENTSTORE_HOST',
      config.eventstore?.host,
    );
    config.eventstore?.port = _propertyAt<int>(
      'EVENTSTORE_PORT',
      config.eventstore?.port,
    );

    config.app?.scheme = _propertyAt<String>('TRACKING_SERVER_SCHEME', config.app?.scheme);
    config.app?.host = _propertyAt<String>('APP_SERVER_HOST', config.app?.host);
    config.app?.port = _propertyAt<int>('APP_SERVER_PORT', config.app?.port);

    config.tracking?.scheme = _propertyAt<String>('TRACKING_SERVER_SCHEME', config.tracking?.scheme);
    config.tracking?.host = _propertyAt<String>('TRACKING_SERVER_HOST', config.tracking?.host);
    config.tracking?.grpcPort = _propertyAt<int>('TRACKING_SERVER_GRPC_PORT', config.tracking?.grpcPort);
    config.tracking?.healthPort = _propertyAt<int>('TRACKING_SERVER_HEALTH_PORT', config.tracking?.healthPort);
  }

  T _propertyAt<T>(String key, T defaultValue) => options.context.elementAt<T>(
        key,
        defaultValue: defaultValue,
      );

  void _logModuleConfig(String module, SarSysModuleConfig config) {
    logger.info("${module}_SERVER url is ${config.url}");
    logger.info("${module}_EVENTSTORE url is ${config.eventstore.url}");
    logger.info("${module}_EVENTSTORE_LOGIN is ${config.eventstore.login}");
    logger.info("${module}_EVENTSTORE_REQUIRE_MASTER is ${config.eventstore.requireMaster}");
  }

  Future<bool> _configureK8sApi() async {
    k8s = _propertyAt<K8sApi>('K8S_API', K8sApi());
    final serverOK = await k8s.checkApi();
    final metricsOK = await k8s.checkMetricsApi();
    if (serverOK) {
      final pods = await k8s.getPodList(
        k8s.namespace,
      );
      logger.info(
        "PODS found in namespace '${k8s.namespace}': ${pods.length}",
      );
    }
    return serverOK && metricsOK;
  }

  void _buildValidators() {
    final file = File(config.apiSpecPath);
    final spec = file.readAsStringSync();
    final data = json.decode(spec.isEmpty ? '{}' : spec);
    requestValidator = JsonValidation(data as Map<String, dynamic>);
  }

  void _initHive() {
    if (config.data.enabled) {
      final hiveDir = Directory(
        config.data.path,
      );
      hiveDir.createSync(
        recursive: true,
      );
      Hive.init(hiveDir.path);
    }
  }

  Future _terminateOnFailure(Object error, StackTrace stackTrace) async {
    stdout.writeln(
      "Failed to prepare server: $error: $stackTrace",
    );
    logger.severe(
      "Failed to prepare server: $error",
      error,
      Trace.from(stackTrace),
    );
    stdout.writeln("Terminating server safely...");
    logger.severe(
      "Terminating server safely...",
      error,
      Trace.from(stackTrace),
    );
    return server.close();
  }

  Future _buildSecureRouter() async {
    router = SecureRouter(config.auth, [
      'roles:admin',
    ]);
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
}
