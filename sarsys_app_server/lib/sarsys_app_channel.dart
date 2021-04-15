import 'dart:convert';

import 'package:hive/hive.dart';
import 'package:http/http.dart';
import 'package:stack_trace/stack_trace.dart';

import 'package:collection_x/collection_x.dart';
import 'package:event_source/event_source.dart';

import 'package:event_source_grpc/event_source_grpc.dart';
import 'package:grpc/grpc.dart' as grpc;
import 'package:sentry/sentry.dart' hide Device;
import 'package:sarsys_domain/sarsys_domain.dart' hide Operation;
import 'package:sarsys_domain/sarsys_domain.dart' as sar show Operation;

import 'package:sarsys_core/sarsys_core.dart';
import 'controllers/domain/controllers.dart';
import 'controllers/domain/schemas.dart';
import 'controllers/messaging.dart';
import 'controllers/tenant/app_config.dart';
import 'controllers/tenant/controllers.dart';
import 'sarsys_app_server.dart';

/// MUST BE used when bootstrapping Aqueduct
const int isolateStartupTimeout = 30;

const List<String> allScopes = [
//  'roles:admin',
//  'roles:commander',
//  'roles:unit_leader',
  'roles:personnel',
];

/// This initializes a SARSys http backend apps server
class SarSysAppServerChannel extends SarSysServerChannelBase {
  /// Channel responsible for distributing messages to client applications
  final MessageChannel messages = MessageChannel(
    handler: WebSocketMessageProcessor(),
  );

  /// Loaded in [prepare]
  SarSysAppConfig config;

  /// Manages an [Repository] for each registered [AggregateRoot]
  RepositoryManager manager;

  /// Validates requests against current open api specification
  JsonValidation requestValidator;

  /// Tracking domain service
  TrackingService trackingService;

  /// Secure router enforcing authorization
  SecureRouter router;

  grpc.Server _grpc;

  /// Logger instance
  @override
  final Logger logger = Logger("SarSysAppServerChannel");

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

      await _loadConfig();
      _initHive();
      _buildValidators();
      _buildRepoManager();
      _buildRepos(
        stopwatch,
        catchError: _terminateOnFailure,
        whenComplete: _buildDomainServices,
      );
      _buildMessageChannel();
      await _buildSecureRouter();
      await _buildGrpcServer();

      if (stopwatch.elapsed.inSeconds > isolateStartupTimeout * 0.8) {
        logger.severe("Approaching maximum duration to wait for each isolate to complete startup");
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
    // TODO: PassCodes - implement ReadModel and validation for all protected Aggregates

    return router
      ..route('/api/*').link(
        () => DocumentController(),
      )
      ..route('/api/healthz/alive').link(() => LivenessController())
      ..route('/api/healthz/ready').link(() => ReadinessController(
            () => manager.isReady,
          ))
      ..secure(
          '/api/messages/connect',
          () => WebSocketController(
                manager,
                messages,
              ))
      ..secure(
          '/api/app-configs[/:uuid]',
          () => AppConfigController(
                manager.get<AppConfigRepository>(),
                manager.get<DeviceRepository>(),
                requestValidator,
              ))
      ..secure(
          '/api/persons[/:uuid]',
          () => PersonController(
                manager.get<PersonRepository>(),
                requestValidator,
              ))
      ..secure(
          '/api/affiliations[/:uuid]',
          () => AffiliationController(
                manager.get<PersonRepository>(),
                manager.get<AffiliationRepository>(),
                requestValidator,
              ))
      ..secure(
          '/api/affiliations/onboard',
          () => AffiliationPersonController(
                manager.get<PersonRepository>(),
                manager.get<AffiliationRepository>(),
                requestValidator,
              ))
      ..secure(
          '/api/incidents[/:uuid]',
          () => IncidentController(
                manager.get<IncidentRepository>(),
                requestValidator,
              ))
      ..secure(
          '/api/incidents/:uuid/subjects',
          () => IncidentSubjectController(
                manager.get<IncidentRepository>(),
                manager.get<SubjectRepository>(),
                requestValidator,
              ))
      ..secure(
          '/api/incidents/:uuid/clues[/:id]',
          () => ClueController(
                manager.get<IncidentRepository>(),
                requestValidator,
              ))
      ..secure(
          '/api/incidents/:uuid/messages[/:id]',
          () => IncidentMessageController(
                manager.get<IncidentRepository>(),
                requestValidator,
              ))
      ..secure(
          '/api/incidents/:uuid/operations',
          () => IncidentOperationsController(
                manager.get<IncidentRepository>(),
                manager.get<OperationRepository>(),
                requestValidator,
              ))
      ..secure(
          '/api/subjects[/:uuid]',
          () => SubjectController(
                manager.get<SubjectRepository>(),
                requestValidator,
              ))
      ..secure(
          '/api/operations[/:uuid]',
          () => OperationController(
                manager.get<OperationRepository>(),
                requestValidator,
              ))
      ..secure(
          '/api/operations/:uuid/objectives[/:id]',
          () => ObjectiveController(
                manager.get<OperationRepository>(),
                requestValidator,
              ))
      ..secure(
          '/api/operations/:uuid/talkgroups[/:id]',
          () => TalkGroupController(
                manager.get<OperationRepository>(),
                requestValidator,
              ))
      ..secure(
          '/api/operations/:uuid/personnels',
          () => OperationPersonnelController(
                manager.get<OperationRepository>(),
                manager.get<PersonnelRepository>(),
                manager.get<PersonRepository>(),
                manager.get<AffiliationRepository>(),
                requestValidator,
              ))
      ..secure(
          '/api/operations/:uuid/missions',
          () => OperationMissionController(
                manager.get<OperationRepository>(),
                manager.get<MissionRepository>(),
                requestValidator,
              ))
      ..secure(
          '/api/operations/:uuid/units',
          () => OperationUnitController(
                manager.get<OperationRepository>(),
                manager.get<UnitRepository>(),
                manager.get<PersonnelRepository>(),
                requestValidator,
              ))
      ..secure(
          '/api/operations/:uuid/trackings',
          () => OperationTrackingController(
                units: manager.get<UnitRepository>(),
                trackings: manager.get<TrackingRepository>(),
                personnels: manager.get<PersonnelRepository>(),
                operations: manager.get<OperationRepository>(),
              ))
      ..secure(
          '/api/operations/:uuid/messages[/:id]',
          () => OperationMessageController(
                manager.get<OperationRepository>(),
                requestValidator,
              ))
      ..secure(
          '/api/missions[/:uuid]',
          () => MissionController(
                manager.get<MissionRepository>(),
                requestValidator,
              ))
      ..secure(
          '/api/missions/:uuid/parts[/:id]',
          () => MissionPartController(
                manager.get<MissionRepository>(),
                requestValidator,
              ))
      ..secure(
          '/api/missions/:uuid/results[/:id]',
          () => MissionResultController(
                manager.get<MissionRepository>(),
                requestValidator,
              ))
      ..secure(
          '/api/missions/:uuid/messages[/:id]',
          () => MissionMessageController(
                manager.get<MissionRepository>(),
                requestValidator,
              ))
      ..secure(
          '/api/personnels[/:uuid]',
          () => PersonnelController(
                manager.get<PersonRepository>(),
                manager.get<AffiliationRepository>(),
                manager.get<PersonnelRepository>(),
                requestValidator,
              ))
      ..secure(
          '/api/personnels/:uuid/messages[/:id]',
          () => PersonnelMessageController(
                manager.get<PersonnelRepository>(),
                requestValidator,
              ))
      ..secure(
          '/api/units[/:uuid]',
          () => UnitController(
                manager.get<UnitRepository>(),
                manager.get<PersonnelRepository>(),
                requestValidator,
              ))
      ..secure(
          '/api/units/:uuid/personnels',
          () => UnitPersonnelController(
                manager.get<UnitRepository>(),
                manager.get<PersonnelRepository>(),
                requestValidator,
              ))
      ..secure(
          '/api/units/:uuid/messages[/:id]',
          () => UnitMessageController(
                manager.get<UnitRepository>(),
                requestValidator,
              ))
      ..secure(
          '/api/organisations[/:uuid]',
          () => OrganisationController(
                manager.get<OrganisationRepository>(),
                requestValidator,
              ))
      ..secure(
          '/api/organisations/:uuid/import',
          () => OrganisationImportController(
                manager.get<OrganisationRepository>(),
                manager.get<DivisionRepository>(),
                manager.get<DepartmentRepository>(),
                requestValidator,
              ))
      ..secure(
          '/api/organisations/:uuid/divisions',
          () => OrganisationDivisionController(
                manager.get<OrganisationRepository>(),
                manager.get<DivisionRepository>(),
                requestValidator,
              ))
      ..secure(
          '/api/divisions[/:uuid]',
          () => DivisionController(
                manager.get<DivisionRepository>(),
                requestValidator,
              ))
      ..secure(
          '/api/divisions/:uuid/departments',
          () => DivisionDepartmentController(
                manager.get<DivisionRepository>(),
                manager.get<DepartmentRepository>(),
                requestValidator,
              ))
      ..secure(
          '/api/departments[/:uuid]',
          () => DepartmentController(
                manager.get<DepartmentRepository>(),
                requestValidator,
              ))
      ..secure(
          '/api/trackings[/:uuid]',
          () => TrackingController(
                manager.get<TrackingRepository>(),
                requestValidator,
              ))
      ..secure(
          '/api/trackings/:uuid/status',
          () => TrackingStatusController(
                manager.get<TrackingRepository>(),
                requestValidator,
              ))
      ..secure(
          '/api/trackings/:tuuid/sources[/:suuid]',
          () => TrackingSourceController(
                manager.get<TrackingRepository>(),
                requestValidator,
              ))
      ..secure(
          '/api/trackings/:uuid/tracks[/:id]',
          () => TrackingTrackController(
                manager.get<TrackingRepository>(),
                requestValidator,
              ))
      ..secure(
          '/api/trackings/:uuid/tracks/:id/positions',
          () => TrackingTrackPositionsController(
                manager.get<TrackingRepository>(),
                requestValidator,
              ))
      ..secure(
          '/api/devices[/:uuid]',
          () => DeviceController(
                manager.get<DeviceRepository>(),
                requestValidator,
              ))
      ..secure(
          '/api/devices/:uuid/position',
          () => DevicePositionController(
                manager.get<DeviceRepository>(),
                requestValidator,
              ))
      ..secure(
          '/api/devices/:uuid/positions',
          () => DevicePositionBatchController(
                manager.get<DeviceRepository>(),
                requestValidator,
              ))
      ..secure(
          '/api/devices/:uuid/messages[/:id]',
          () => DeviceMessageController(
                manager.get<DeviceRepository>(),
                requestValidator,
              ));
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

  Future<void> _loadConfig() async {
    // Parse from config file, given by --config to document.dart or default config.yaml
    config = SarSysAppConfig.fromFile(
      options.configurationFilePath,
    );
    _writeContextOnConfig();
    config.host = Platform.localHostname;
    config.port = server.options.port;
    RequestBody.maxSize = 1024 * 1024 * config.maxBodySize;
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
    logger.info(
      "Server log level set to ${Logger.root.level.name}",
    );
    if (config.logging.sentry != null) {
      _remoteLogger = RemoteLogger(
        config.logging.sentry,
        config.tenant,
      );
      await _remoteLogger.init();
      logger.info("Sentry DSN is ${config.logging.sentry.dsn}");
      logger.info("Sentry log level set to ${_remoteLogger.level}");
    }

    logger.info("SERVER url is ${config.url}");
    logger.info("EVENTSTORE url is ${config.eventstore.url}");
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

  void _writeContextOnConfig() {
    config.debug = _propertyAt<bool>('DEBUG', config.debug);
    config.prefix = _propertyAt<String>('PREFIX', config.prefix);
    config.tenant = _propertyAt<String>('TENANT', config.tenant);
    config.grpc.port = _propertyAt<int>('GRPC_PORT', config.grpc.port);
    config.grpc.enabled = _propertyAt<bool>('GRPC_ENABLED', config.grpc.enabled);
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
    config.data.snapshots.enabled = _propertyAt<bool>(
      'DATA_SNAPSHOTS_ENABLED',
      config.data.snapshots.enabled,
    );
    config.data.snapshots.keep = _propertyAt<int>(
      'DATA_SNAPSHOTS_KEEP',
      config.data.snapshots.keep,
    );
    config.data.snapshots.threshold = _propertyAt<int>(
      'DATA_SNAPSHOTS_THRESHOLD',
      config.data.snapshots.threshold,
    );
    config.data.snapshots.automatic = _propertyAt<bool>(
      'DATA_SNAPSHOTS_AUTOMATIC',
      config.data.snapshots.automatic,
    );

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
  }

  T _propertyAt<T>(String key, T defaultValue) => options.context.elementAt<T>(
        key,
        defaultValue: defaultValue,
      );

  void _buildValidators() {
    final file = File(config.apiSpecPath);
    final spec = file.readAsStringSync();
    final data = json.decode(spec.isEmpty ? '{}' : spec);
    requestValidator = JsonValidation(data as Map<String, dynamic>);
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
        scheme: config.eventstore.scheme,
        credentials: UserCredentials(
          login: config.eventstore.login,
          password: config.eventstore.password,
        ),
        requireMaster: config.eventstore.requireMaster,
      ),
      prefix: namespace,
    );
  }

  void _buildRepos(
    Stopwatch stopwatch, {
    Function() whenComplete,
    Function(Object error, StackTrace stackTrace) catchError,
  }) {
    // Register independent repositories
    register<Incident>((store) => IncidentRepository(store));
    register<Device>((store) => DeviceRepository(store));
    register<Tracking>((store) => TrackingRepository(store));
    register<Affiliation>((store) => AffiliationRepository(store));

    // Register dependent repositories
    register<AppConfig>(
      (store) => AppConfigRepository(
        store,
        devices: manager.get<DeviceRepository>(),
      ),
    );
    register<Subject>(
      (store) => SubjectRepository(
        store,
        incidents: manager.get<IncidentRepository>(),
      ),
    );
    register<sar.Operation>(
      (store) => OperationRepository(
        store,
        incidents: manager.get<IncidentRepository>(),
      ),
    );
    register<Mission>(
      (store) => MissionRepository(
        store,
        operations: manager.get<OperationRepository>(),
      ),
    );
    register<Unit>(
      (store) => UnitRepository(
        store,
        trackings: manager.get<TrackingRepository>(),
        operations: manager.get<OperationRepository>(),
      ),
    );
    register<Personnel>(
      (store) => PersonnelRepository(
        store,
        units: manager.get<UnitRepository>(),
        trackings: manager.get<TrackingRepository>(),
        operations: manager.get<OperationRepository>(),
      ),
    );
    register<Person>(
      (store) => PersonRepository(
        store,
        affiliations: manager.get<AffiliationRepository>(),
      ),
    );
    register<Organisation>(
      (store) => OrganisationRepository(
        store,
        affiliations: manager.get<AffiliationRepository>(),
      ),
    );
    register<Division>(
      (store) => DivisionRepository(
        store,
        organisations: manager.get<OrganisationRepository>(),
        affiliations: manager.get<AffiliationRepository>(),
      ),
    );
    register<Department>(
      (store) => DepartmentRepository(
        store,
        divisions: manager.get<DivisionRepository>(),
        affiliations: manager.get<AffiliationRepository>(),
      ),
    );

    // Defer repository builds so that isolates are
    // not killed on eventstore connection timeouts
    Future.microtask(() => _buildReposAsync(stopwatch))
      ..then((_) => whenComplete())
      ..catchError(catchError);
  }

  void register<T extends AggregateRoot>(
    Repository<Command, T> Function(EventStore store) create, {
    String prefix,
    String stream,
    bool useInstanceStreams = true,
  }) {
    // Context allows for testing to pass these
    final keep = config.data.snapshots.keep;
    final enabled = config.data.snapshots.enabled;
    final automatic = config.data.snapshots.automatic;
    final threshold = config.data.snapshots.threshold;
    final snapshots = enabled
        ? Storage.fromType<T>(
            keep: keep,
            automatic: automatic,
            threshold: threshold,
          )
        : null;
    manager.register<T>(
      create,
      prefix: prefix,
      stream: stream,
      snapshots: snapshots,
      useInstanceStreams: useInstanceStreams,
    );
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

  Future _buildReposAsync(Stopwatch stopwatch) async {
    // Initialize
    await Storage.init();

    await manager.prepare(withProjections: [
      '\$by_category',
      '\$by_event_type',
    ]);
    final count = await manager.build();
    logger.info("Processed $count events!");
    logger.info(
      "Built repositories in ${stopwatch.elapsedMilliseconds}ms => ready for aggregate requests!",
    );
  }

  Future _buildDomainServices() async {
    if (config.standalone) {
      trackingService = TrackingService(
        manager.get<TrackingRepository>(),
        dataPath: config.data.path,
        snapshot: config.data.enabled,
        devices: manager.get<DeviceRepository>(),
      );
      await trackingService.build();
      await trackingService.start();
    }
    return Future.value();
  }

  void _terminateOnFailure(Object error, StackTrace stackTrace) {
    if (!_disposed) {
      if (error is ClientException || error is SocketException) {
        logger.severe(
          "Failed to connect to eventstore with ${manager.connection}",
          error,
          Trace.from(stackTrace),
        );
      } else {
        logger.severe(
          "Failed to build repositories: $error: $stackTrace",
          error,
          Trace.from(stackTrace),
        );
      }
    }
    logger.severe(
      "Terminating server safely...",
      error,
      Trace.from(stackTrace),
    );
    server.close();
  }

  void _buildMessageChannel() {
    messages.register<AppConfigCreated>(manager.bus);
    messages.register<AppConfigUpdated>(manager.bus);
    messages.register<IncidentRegistered>(manager.bus);
    messages.register<IncidentInformationUpdated>(manager.bus);
    messages.register<IncidentRespondedTo>(manager.bus);
    messages.register<IncidentCancelled>(manager.bus);
    messages.register<IncidentResolved>(manager.bus);
    messages.register<DevicePositionChanged>(manager.bus);
    messages.register<DeviceInformationUpdated>(manager.bus);
    messages.register<TrackingTrackChanged>(manager.bus);
    messages.register<TrackingPositionChanged>(manager.bus);
    messages.register<TrackingInformationUpdated>(manager.bus);
    messages.register<IncidentResolved>(manager.bus);
    // TODO: MessageChannel - Add Operation events
    // TODO: MessageChannel - Add Unit events
    messages.build();
  }

  FutureOr<void> _buildGrpcServer() async {
    if (config.grpc.enabled) {
      // Start grpc server
      _grpc = grpc.Server([
        AggregateGrpcService(manager),
        RepositoryGrpcService(manager),
        SnapshotGrpcService(manager, config.data.path),
      ]);

      await _grpc.serve(
        port: config.grpc.port,
        address: InternetAddress.anyIPv4,
      );

      logger.info(
        'GPRC Server running at port ${config.grpc.port}',
      );
    }
  }

  Future _buildSecureRouter() async {
    router = SecureRouter(config.auth, [
      'roles:admin',
      'roles:commander',
      'roles:unit_leader',
      'roles:personnel',
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

  bool get isPaused => manager.isPaused;
  void pause() {
    manager.pause();
  }

  void resume() {
    manager.resume();
  }

  @override
  Future close() async {
    await dispose();
    return super.close();
  }

  bool _disposed = false;
  Future dispose() async {
    if (!_disposed) {
      _disposed = true;
      await _grpc?.shutdown();
      await manager?.dispose();
      await messages?.dispose();
      manager?.connection?.close();
    }
  }

  //////////////////////////////////
  // Documentation
  //////////////////////////////////

  @override
  void documentSecuritySchemas(APIDocumentContext context) => context.securitySchemes
    ..register(
        'OpenId Connect',
        APISecurityScheme.openID(
          Uri.parse(
            '${config.auth?.baseUrl ?? 'https://id.discoos.io/auth/realms/DISCOOS'}/.well-known/openid-configuration',
          ),
        ))
    ..register(
      "Passcode",
      APISecurityScheme.apiKey(
        'X-Passcode',
        APIParameterLocation.header,
      )..description = "Authenticated users with an admin role is granted access to all "
          "objects and all available fields in each of these objects regardless of any "
          "affiliation or 'X-Passcode' given. All other roles are only granted access to "
          "objects if 'X-Passcode' is valid. Requests without header 'X-Passcode' or an invalid "
          "passcode will receive response `403 Forbidden`. Brute-force attacks are banned "
          "for a lmitied time without any feedback. When banned, all request will receive "
          "response `403 Forbidden` regardless of the value in 'X-Passcode'.",
    );

  @override
  void documentSchemas(APIDocumentContext context) {
    super.documentSchemas(context);
    context.schema
      ..register('PassCodes', documentPassCodes())
      ..register('Author', documentAuthor())
      ..register('Coordinates', documentCoordinates(context))
      ..register('Geometry', documentGeometry(context))
      ..register('Point', documentPoint(context))
      ..register('LineString', documentLineString(context))
      ..register('Polygon', documentPolygon(context))
      ..register('MultiPoint', documentMultiPoint(context))
      ..register('MultiLineString', documentMultiLineString(context))
      ..register('MultiPolygon', documentMultiPolygon(context))
      ..register('GeometryCollection', documentGeometryCollection(context))
      ..register('Feature', documentFeature(context))
      ..register('FeatureCollection', documentFeatureCollection(context))
      ..register('Circle', documentCircle(context))
      ..register('Rectangle', documentRectangle(context))
      ..register('Position', documentPosition(context))
      ..register('PositionListResponse', documentPositionListResponse(context))
      ..register('Message', documentMessage(context));
  }
}
