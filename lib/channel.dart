import 'dart:convert';

import 'package:http/http.dart';
import 'package:sarsys_app_server/controllers/domain/division_department_controller.dart';
import 'package:sarsys_app_server/controllers/domain/organisation_division_controller.dart';

import 'auth/oidc.dart';
import 'controllers/domain/controllers.dart';
import 'controllers/domain/schemas.dart';
import 'controllers/system/controllers.dart';
import 'controllers/tenant/controllers.dart';
import 'controllers/websocket_controller.dart';
import 'domain/department/department.dart';
import 'domain/device/device.dart';
import 'domain/division/division.dart';
import 'domain/incident/incident.dart';
import 'domain/messages.dart';
import 'domain/mission/mission.dart';
import 'domain/operation/operation.dart' as sar;
import 'domain/organisation/organisation.dart';
import 'domain/personnel/personnel.dart';
import 'domain/subject/subject.dart';
import 'domain/tenant/app_config.dart';
import 'domain/tracking/aggregate.dart';
import 'domain/tracking/repository.dart';
import 'domain/unit/unit.dart';
import 'eventsource/eventsource.dart';
import 'sarsys_app_server.dart';
import 'validation/validation.dart';

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
  final OIDCValidator authValidator = OIDCValidator(['id.discoos.org']);

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
    _buildInvariants();
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
        () => DocumentController(),
      )
      ..route('/api/healthz').link(
        () => HealthController(),
      )
      ..route('/api/messages/connect').link(
        () => WebSocketController(messages),
      )
      ..route('/api/app-configs[/:uuid]').link(() => AppConfigController(
            manager.get<AppConfigRepository>(),
            requestValidator,
          ))
      ..route('/api/incidents[/:uuid]').link(() => IncidentController(
            manager.get<IncidentRepository>(),
            requestValidator,
          ))
      ..route('/api/incidents/:uuid/subjects').link(() => IncidentSubjectController(
            manager.get<IncidentRepository>(),
            manager.get<SubjectRepository>(),
            requestValidator,
          ))
      ..route('/api/incidents/:uuid/operations').link(() => IncidentOperationsController(
            manager.get<IncidentRepository>(),
            manager.get<sar.OperationRepository>(),
            requestValidator,
          ))
      ..route('/api/incidents/:uuid/clues[/:id]').link(() => ClueController(
            manager.get<IncidentRepository>(),
            requestValidator,
          ))
      ..route('/api/subjects[/:uuid]').link(() => SubjectController(
            manager.get<SubjectRepository>(),
            requestValidator,
          ))
      ..route('/api/operations[/:uuid]').link(() => OperationController(
            manager.get<sar.OperationRepository>(),
            requestValidator,
          ))
      ..route('/api/operations/:uuid/objectives[/:id]').link(() => ObjectiveController(
            manager.get<sar.OperationRepository>(),
            requestValidator,
          ))
      ..route('/api/operations/:uuid/talkgroups[/:id]').link(() => TalkGroupController(
            manager.get<sar.OperationRepository>(),
            requestValidator,
          ))
      ..route('/api/operations/:uuid/missions').link(() => OperationMissionController(
            manager.get<sar.OperationRepository>(),
            manager.get<MissionRepository>(),
            requestValidator,
          ))
      ..route('/api/operations/:uuid/units').link(() => OperationUnitController(
            manager.get<sar.OperationRepository>(),
            manager.get<UnitRepository>(),
            requestValidator,
          ))
      ..route('/api/missions[/:uuid]').link(() => MissionController(
            manager.get<MissionRepository>(),
            requestValidator,
          ))
      ..route('/api/missions/:uuid/parts[/:id]').link(() => MissionPartController(
            manager.get<MissionRepository>(),
            requestValidator,
          ))
      ..route('/api/missions/:uuid/results[/:id]').link(() => MissionResultController(
            manager.get<MissionRepository>(),
            requestValidator,
          ))
      ..route('/api/personnels[/:uuid]').link(() => PersonnelController(
            manager.get<PersonnelRepository>(),
            requestValidator,
          ))
      ..route('/api/units[/:uuid]').link(() => UnitController(
            manager.get<UnitRepository>(),
            requestValidator,
          ))
      ..route('/api/organisations[/:uuid]').link(() => OrganisationController(
            manager.get<OrganisationRepository>(),
            requestValidator,
          ))
      ..route('/api/organisations/:uuid/divisions').link(() => OrganisationDivisionController(
            manager.get<OrganisationRepository>(),
            manager.get<DivisionRepository>(),
            requestValidator,
          ))
      ..route('/api/divisions[/:uuid]').link(() => DivisionController(
            manager.get<DivisionRepository>(),
            requestValidator,
          ))
      ..route('/api/divisions/:uuid/departments').link(() => DivisionDepartmentController(
            manager.get<DivisionRepository>(),
            manager.get<DepartmentRepository>(),
            requestValidator,
          ))
      ..route('/api/departments[/:uuid]').link(() => DepartmentController(
            manager.get<DepartmentRepository>(),
            requestValidator,
          ))
      ..route('/api/trackings[/:uuid]').link(() => TrackingController(
            manager.get<TrackingRepository>(),
            requestValidator,
          ))
      ..route('/api/devices[/:uuid]').link(() => DeviceController(
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

  void _buildRepos(Stopwatch stopwatch) {
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
    manager.register<sar.Operation>((manager) => sar.OperationRepository(manager));
    manager.register<Tracking>((manager) => TrackingRepository(manager));
    manager.register<Device>((manager) => DeviceRepository(manager));

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

  void _buildInvariants() {
    // IncidentRepository constraints
    manager.get<IncidentRepository>()
      ..constraint<sar.OperationDeleted>((repository) => AggregateListInvariant<IncidentRepository>(
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
    manager.get<sar.OperationRepository>()
      ..constraint<MissionDeleted>((repository) => AggregateListInvariant<sar.OperationRepository>(
            'missions',
            (aggregate, event) => sar.RemoveMissionFromOperation(
              aggregate as sar.Operation,
              repository.toAggregateUuid(event),
            ),
            repository as sar.OperationRepository,
          ))
      ..constraint<UnitDeleted>((repository) => AggregateListInvariant<sar.OperationRepository>(
            'units',
            (aggregate, event) => sar.RemoveUnitFromOperation(
              aggregate as sar.Operation,
              repository.toAggregateUuid(event),
            ),
            repository as sar.OperationRepository,
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

  void _buildMessageChannel() {
    messages.register<AppConfigCreated>(manager.bus);
    messages.register<AppConfigUpdated>(manager.bus);
    messages.register<IncidentRegistered>(manager.bus);
    messages.register<IncidentInformationUpdated>(manager.bus);
    messages.register<IncidentRespondedTo>(manager.bus);
    messages.register<IncidentCancelled>(manager.bus);
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
    ..register('ID', documentID())
    ..register('UUID', documentUUID())
    ..register('PassCodes', documentPassCodes())
    ..register('Coordinates', documentCoordinates(context))
    ..register('Geometry', documentGeometry(context))
    ..register("Point", documentPoint(context))
    ..register("LineString", documentLineString(context))
    ..register("Polygon", documentPolygon(context))
    ..register("MultiPoint", documentMultiPoint(context))
    ..register("MultiLineString", documentMultiLineString(context))
    ..register("MultiPolygon", documentMultiPolygon(context))
    ..register("GeometryCollection", documentGeometryCollection(context))
    ..register("Feature", documentFeature(context))
    ..register("FeatureCollection", documentFeatureCollection(context))
    ..register("Circle", documentCircle(context))
    ..register("Rectangle", documentRectangle(context))
    ..register("Position", documentPosition(context));
}
