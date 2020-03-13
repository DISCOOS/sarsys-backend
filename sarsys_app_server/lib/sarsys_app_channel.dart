import 'dart:convert';

import 'package:http/http.dart';
import 'package:event_source/event_source.dart';
import 'package:sarsys_app_server/auth/any.dart';
import 'package:sarsys_app_server/controllers/domain/position_controller.dart';
import 'package:sarsys_app_server/sarsys_app_server.dart';
import 'package:sarsys_app_server/controllers/messages.dart';
import 'package:sarsys_domain/sarsys_domain.dart' hide Operation;
import 'package:sarsys_domain/sarsys_domain.dart' as sar show Operation;

import 'auth/auth.dart';
import 'controllers/domain/controllers.dart';
import 'controllers/domain/schemas.dart';
import 'controllers/domain/track_controller.dart';
import 'controllers/system/controllers.dart';
import 'controllers/tenant/app_config.dart';
import 'controllers/tenant/controllers.dart';
import 'controllers/websocket_controller.dart';
import 'sarsys_app_server.dart';
import 'validation/validation.dart';

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
  /// Authorizes requests
  Controller authorizer;

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
    _configureAuth();
    _buildValidators();
    _buildRepoManager();
    _buildRepos(stopwatch, _buildDomainServices);
    _buildInvariants();
    _buildMessageChannel();

    if (stopwatch.elapsed.inSeconds > isolateStartupTimeout * 0.8) {
      logger.severe("Approaching maximum duration to wait for each isolate to complete startup");
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

    return SecureRouter(authorizer)
      ..secure('/', () => DocumentController())
      ..route('/api/*').link(() => DocumentController())
      ..route('/api/healthz').link(() => HealthController())
      ..secure('/api/messages/connect', () => WebSocketController(messages))
      ..secure(
          '/api/app-configs[/:uuid]',
          () => AppConfigController(
                manager.get<AppConfigRepository>(),
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
                requestValidator,
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
          '/api/trackings/:tuuid/sources[/:suuid]',
          () => SourceController(
                manager.get<TrackingRepository>(),
                requestValidator,
              ))
      ..secure(
          '/api/trackings/:uuid/tracks[/:id]',
          () => TrackController(
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

  void _configureAuth() {
    if (config.auth.enabled) {
      authorizer = Authorizer.bearer(
        OIDCValidator(['id.discoos.org']),
        scopes: config.auth.required,
      );
    } else {
      authorizer = AnyAuthorizer(config.auth.required, [
        'roles:admin',
        'roles:commander',
        'roles:unit_leader',
        'roles:personnel',
      ]);
    }
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
      ),
      prefix: namespace,
    );
  }

  void _buildRepos(Stopwatch stopwatch, void whenComplete()) {
    // Register repositories
    manager.register<AppConfig>((manager) => AppConfigRepository(manager));
    manager.register<Incident>((manager) => IncidentRepository(manager));
    manager.register<Subject>((manager) => SubjectRepository(manager));
    manager.register<Personnel>((manager) => PersonnelRepository(manager));
    manager.register<Unit>((manager) => UnitRepository(manager));
    manager.register<Mission>((manager) => MissionRepository(manager));
    manager.register<Organisation>((manager) => OrganisationRepository(manager));
    manager.register<Department>((manager) => DepartmentRepository(manager));
    manager.register<Division>((manager) => DivisionRepository(manager));
    manager.register<sar.Operation>((manager) => OperationRepository(manager));
    manager.register<Tracking>((manager) => TrackingRepository(manager));
    manager.register<Device>((manager) => DeviceRepository(manager));

    // Defer repository builds so that isolates are not killed on eventstore connection timeouts
    Future.delayed(
      const Duration(milliseconds: 1),
      () => _buildReposWithRetries(stopwatch),
    ).whenComplete(whenComplete);
  }

  Future _buildReposWithRetries(Stopwatch stopwatch) async {
    /// Build resources
    try {
      await manager.build(
        withProjections: [
          '\$by_category',
          '\$by_event_type',
        ],
      );
      logger.info("Built repositories in ${stopwatch.elapsedMilliseconds}ms => ready for aggregate requests!");
      return;
    } on ClientException catch (e) {
      logger.severe("Failed to connect to eventstore with ${manager.connection} with: $e => retrying in 2 seconds");
    } on SocketException catch (e) {
      logger.severe("Failed to connect to eventstore with ${manager.connection} with: $e => retrying in 2 seconds");
    }
    return Future.delayed(const Duration(seconds: 2), () => _buildReposWithRetries(stopwatch));
  }

  void _buildInvariants() {
    // IncidentRepository constraints
    manager.get<IncidentRepository>()
      ..constraint<OperationDeleted>((repository) => AggregateListInvariant<IncidentRepository>(
            'operations',
            (aggregate, event) => RemoveOperationFromIncident(
              aggregate as Incident,
              repository.toAggregateUuid(event),
            ),
            repository as IncidentRepository,
          ))
      ..constraint<SubjectDeleted>((repository) => AggregateListInvariant<IncidentRepository>(
            'subjects',
            (aggregate, event) => RemoveSubjectFromIncident(
              aggregate as Incident,
              repository.toAggregateUuid(event),
            ),
            repository as IncidentRepository,
          ));

    // OperationRepository constraints
    manager.get<OperationRepository>()
      ..constraint<MissionDeleted>((repository) => AggregateListInvariant<OperationRepository>(
            'missions',
            (aggregate, event) => RemoveMissionFromOperation(
              aggregate as sar.Operation,
              repository.toAggregateUuid(event),
            ),
            repository as OperationRepository,
          ))
      ..constraint<UnitDeleted>((repository) => AggregateListInvariant<OperationRepository>(
            'units',
            (aggregate, event) => RemoveUnitFromOperation(
              aggregate as sar.Operation,
              repository.toAggregateUuid(event),
            ),
            repository as OperationRepository,
          ));

    // OrganisationRepository constraints
    manager
        .get<OrganisationRepository>()
        .constraint<DivisionDeleted>((repository) => AggregateListInvariant<OrganisationRepository>(
              'divisions',
              (aggregate, event) => RemoveDivisionFromOrganisation(
                aggregate as Organisation,
                repository.toAggregateUuid(event),
              ),
              repository as OrganisationRepository,
            ));

    // DivisionRepository constraints
    manager
        .get<DivisionRepository>()
        .constraint<DepartmentDeleted>((repository) => AggregateListInvariant<DivisionRepository>(
              'departments',
              (aggregate, event) => RemoveDepartmentFromDivision(
                aggregate as Division,
                repository.toAggregateUuid(event),
              ),
              repository as DivisionRepository,
            ));
  }

  Future _buildDomainServices() async {
    trackingService = TrackingService(manager.get<TrackingRepository>());
    await trackingService.build();
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
    messages.register<IncidentResolved>(manager.bus);
    messages.register<IncidentResolved>(manager.bus);
    messages.register<IncidentResolved>(manager.bus);
    // TODO: MessageChannel - Add Operation events
    // TODO: MessageChannel - Add Unit events
    messages.build();
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

  void documentSecuritySchemas(APIDocumentContext context) => context.securitySchemes
    ..register(
      "id.discoos.org",
      APISecurityScheme.openID(
        Uri.parse("https://id.discoos.io/auth/realms/DISCOOS/.well-known/openid-configuration"),
      )..description = "This endpoint requires an identity token issed from https://id.discoos.io passed as a "
          "[Bearer token](https://swagger.io/docs/specification/authentication/bearer-authentication/) issued by "
          "in an [Authorization header](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Authorization).",
    )
    ..register(
      "Passcode",
      APISecurityScheme.apiKey(
        'X-Passcode',
        APIParameterLocation.header,
      )..description = "Authenticed users with an admin role is granted access to all "
          "objects and all available fields in each of these objects regardless of any "
          "affiliation or 'X-Passcode' given. All other roles are only granted access to "
          "objects if 'X-Passcode' is valid. Requests without header 'X-Passcode' or an invalid "
          "passcode will receive response `403 Forbidden`. Brute-force attacks are banned "
          "for a lmitied time without any feedback. When banned, all request will receive "
          "response `403 Forbidden` regardless of the value in 'X-Passcode'.",
    );

  void documentSchemas(APIDocumentContext context) => context.schema
    ..register('AggregateResponse', documentAggregateResponse(context))
    ..register('EntityResponse', documentEntityResponse(context))
    ..register('EntityPageResponse', documentEntityPageResponse(context))
    ..register('ValueResponse', documentValueResponse(context))
    ..register('AggregateRootRef', documentAggregateRef(context))
    ..register('ID', documentID())
    ..register('UUID', documentUUID())
    ..register('PassCodes', documentPassCodes())
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
    ..register('Message', documentMessage(context));
}

class SecureRouter extends Router {
  SecureRouter(this.authorizer);
  final Controller authorizer;

  void secure(String pattern, Controller creator()) {
    super.route(pattern).link(() => authorizer).link(creator);
  }
}
