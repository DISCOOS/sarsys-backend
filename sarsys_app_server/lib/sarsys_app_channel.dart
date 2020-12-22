import 'dart:convert';

import 'package:event_source/event_source.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart';
import 'package:jose/jose.dart';
import 'package:meta/meta.dart';
import 'package:aqueduct/aqueduct.dart' as aq;
import 'package:stack_trace/stack_trace.dart';
import 'package:uuid/uuid.dart';

import 'package:sarsys_domain/sarsys_domain.dart' hide Operation;
import 'package:sarsys_domain/sarsys_domain.dart' as sar show Operation;

import 'package:sarsys_http_core/sarsys_http_core.dart';
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

/// Path to SarSys OpenAPI specification file
const String apiSpecPath = 'web/sarsys.json';

/// This type initializes an application.
///
/// Override methods in this class to set up routes and initialize services like
/// database connections. See http://aqueduct.io/docs/http/channel/.
class SarSysAppServerChannel extends ApplicationChannel {
  /// Channel responsible for distributing messages to client applications
  final MessageChannel messages = MessageChannel(
    handler: WebSocketMessageProcessor(),
  );

  /// Loaded in [prepare]
  SarSysConfig config;

  /// Validates requests against current open api specification
  JsonValidation requestValidator;

  /// Manages an [Repository] for each registered [AggregateRoot]
  RepositoryManager manager;

  /// Tracking domain service
  TrackingService trackingService;

  /// Secure router enforcing authorization
  SecureRouter router;

  /// Logger instance
  @override
  final Logger logger = Logger("SarSysAppServerChannel");

  static RemoteLogger _remoteLogger;

  /// Print [LogRecord] formatted
  static void printRecord(LogRecord rec, {bool debug = false, bool stdout = false}) {
    final message = "${rec.time}: ${rec.level.name}: "
        "${debug ? '${rec.loggerName}: ' : ''}"
        "${debug && Platform.environment.containsKey('POD-NAME') ? '${Platform.environment['POD-NAME']}: ' : ''}"
        "${rec.message}"
        "${rec.error != null ? ':\nerror: ${rec.error}' : ''}"
        "${rec.stackTrace != null ? ':\nstackTrace: ${rec.stackTrace}' : ''}";
    if (stdout) {
      print(message);
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
      _buildRepoManager();
      _buildRepos(
        stopwatch,
        catchError: _terminateOnFailure,
        whenComplete: _buildDomainServices,
      );
      _buildMessageChannel();
      await _buildSecureRouter();

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
      ..route('/api/healthz').link(() => HealthController(
            manager,
          ))
      ..secure(
          '/api/messages/connect',
          () => WebSocketController(
                manager,
                messages,
              ))
      ..secure(
          '/api/repositories/:type',
          () => RepositoryOperationsController(
                manager,
                tag: 'System',
              ))
      ..secure(
          '/api/aggregates/:type/:uuid',
          () => AggregateOperationsController(
                manager,
                tag: 'System',
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

  void _loadConfig() {
    // Parse from config file, given by --config to main.dart or default config.yaml
    config = SarSysConfig(options.configurationFilePath);
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

  void _buildValidators() {
    final file = File(apiSpecPath);
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
    final keep = options.context.elementAt<int>(
      'snapshot_keep',
      defaultValue: config.data.snapshots.keep,
    );
    final enabled = options.context.elementAt<bool>(
      'snapshots_enabled',
      defaultValue: config.data.snapshots.enabled,
    );
    final automatic = options.context.elementAt<bool>(
      'snapshot_automatic',
      defaultValue: config.data.snapshots.automatic,
    );
    final threshold = options.context.elementAt<int>(
      'snapshot_threshold',
      defaultValue: config.data.snapshots.threshold,
    );
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
    if (config.tracking) {
      trackingService = TrackingService(
        manager.get<TrackingRepository>(),
        dataPath: config.data.path,
        snapshot: config.data.enabled,
        devices: manager.get<DeviceRepository>(),
      );
      await trackingService.build();
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

  bool get isPaused => manager.isPaused;
  void pause() {
    manager.pause();
    trackingService?.pause();
  }

  void resume() {
    manager.resume();
    trackingService?.resume();
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
      await manager?.dispose();
      await messages?.dispose();
      await trackingService?.dispose();
      manager?.connection?.close();
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

  void documentSchemas(APIDocumentContext context) => context.schema
    ..register('AggregateResponse', documentAggregateResponse(context))
    ..register('AggregatePageResponse', documentAggregatePageResponse(context))
    ..register('EntityResponse', documentEntityResponse(context))
    ..register('EntityPageResponse', documentEntityPageResponse(context))
    ..register('ValueResponse', documentValueResponse(context))
    ..register('ValuePageResponse', documentValuePageResponse(context))
    ..register('AggregateRef', documentAggregateRef(context))
    ..register('AggregateList', documentAggregateList(context))
    ..register('ID', documentID())
    ..register('UUID', documentUUID())
    ..register('Conflict', documentConflict(context))
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
      'roles:commander',
      'roles:unit_leader',
      'roles:personnel',
    ]);
  }
}
