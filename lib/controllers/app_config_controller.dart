import 'package:sarsys_app_server/domain/tenant/app_config.dart';
import 'package:sarsys_app_server/eventsource/eventsource.dart';
import 'package:sarsys_app_server/sarsys_app_server.dart';

/// A ResourceController that handles
/// [/api/app-config](http://localhost/api/client.html#/AppConfig) [Request]s
class AppConfigController extends ResourceController {
  AppConfigController(this.repository);
  final AppConfigRepository repository;

  // GET /app-config
  @Operation.get()
  Future<Response> getAll({
    @Bind.query('offset') int offset = 0,
    @Bind.query('limit') int limit = 20,
  }) async {
    try {
      final events = repository
          .getAll(
            offset: offset,
            limit: limit,
          )
          .toList();
      return okPaged(repository.count, offset, limit, events);
    } on InvalidOperation catch (e) {
      return Response.badRequest(body: e.message);
    } on Failure catch (e) {
      return Response.serverError(body: e.message);
    }
  }

  // GET /app-config/:id
  @Operation.get('uuid')
  Future<Response> getById(@Bind.path('uuid') String uuid) async {
    if (!repository.contains(uuid)) {
      return Response.notFound();
    }
    try {
      return ok(repository.get(uuid));
    } on InvalidOperation catch (e) {
      return Response.badRequest(body: e.message);
    } on Failure catch (e) {
      return Response.serverError(body: e.message);
    }
  }

  // POST /app-config
  @Operation.post()
  Future<Response> create(@Bind.body() Map<String, dynamic> data) async {
    try {
      await repository.execute(CreateAppConfig(data));
      return Response.created("${toLocation(request)}/${data['uuid']}");
    } on AggregateExists catch (e) {
      return Response.conflict(body: e.message);
    } on UUIDIsNull {
      return Response.badRequest(body: "Field [uuid] in AppConfig is required");
    } on InvalidOperation catch (e) {
      return Response.badRequest(body: e.message);
    } on SocketException catch (e) {
      return serviceUnavailable(body: "Eventstore unavailable: $e");
    } on Failure catch (e) {
      return Response.serverError(body: e.message);
    }
  }

  // PATCH /app-config/:id
  @Operation('PATCH', 'uuid')
  Future<Response> patch(@Bind.path('uuid') String uuid, @Bind.body() Map<String, dynamic> data) async {
    try {
      data['uuid'] = uuid;
      final events = await repository.execute(UpdateAppConfig(data));
      return events.isEmpty ? Response.noContent() : Response.noContent();
    } on AggregateNotFound catch (e) {
      return Response.notFound(body: e.message);
    } on UUIDIsNull {
      return Response.badRequest(body: "Field [uuid] in AppConfig is required");
    } on InvalidOperation catch (e) {
      return Response.badRequest(body: e.message);
    } on SocketException catch (e) {
      return serviceUnavailable(body: "Eventstore unavailable: $e");
    } on Failure catch (e) {
      return Response.serverError(body: e.message);
    }
  }

  //////////////////////////////////
  // Documentation
  //////////////////////////////////

  @override
  String documentOperationSummary(APIDocumentContext context, Operation operation) {
    String summary;
    switch (operation.method) {
      case "GET":
        summary =
            operation.pathVariables.isEmpty ? "Get all application configurations" : "Get application configuration";
        break;
      case "POST":
        summary = "Create new application configuration";
        break;
      case "PATCH":
        summary = "Update application configuration";
        break;
    }
    return summary;
  }

  @override
  String documentOperationDescription(APIDocumentContext context, Operation operation) {
    String desc = "${documentOperationSummary(context, operation)}. ";
    switch (operation.method) {
      case "GET":
        desc += operation.pathVariables.isEmpty
            ? "This operation is only allowed for admin users."
            : "A configuration is unique for each application regardless of which user is logged in.";
        break;
      case "POST":
        desc += "The field [uuid] MUST BE unique for each application. "
            "Use a OS-spesific device id or a [universally unique identifier]"
            "(https://en.wikipedia.org/wiki/Universally_unique_identifier).";
        break;
      case "PATCH":
        desc += "Only fields in request are updated. Existing values WILL BE overwritten, others remain unchanged.";
        break;
    }
    return desc;
  }

  @override
  APIRequestBody documentOperationRequestBody(APIDocumentContext context, Operation operation) {
    switch (operation.method) {
      case "POST":
        return APIRequestBody.schema(
          context.schema["AppConfig"],
          description: "New application configuration",
          required: true,
        );
        break;
      case "PATCH":
        return APIRequestBody.schema(
          context.schema["AppConfig"],
          description: "Updated application configuration. Only fields in request are updated.",
          required: true,
        );
        break;
    }
    return super.documentOperationRequestBody(context, operation);
  }

  @override
  Map<String, APIResponse> documentOperationResponses(APIDocumentContext context, Operation operation) {
    final responses = {
      "401": context.responses.getObject("401"),
      "403": context.responses.getObject("403"),
    };
    switch (operation.method) {
      case "GET":
        if (operation.pathVariables.isEmpty) {
          responses.addAll({
            "200": APIResponse.schema(
              "Successful response.",
              APISchemaObject.array(ofSchema: context.schema["AppConfig"]),
            )
          });
        } else {
          responses.addAll({
            "200": APIResponse.schema("Successful response", context.schema["AppConfig"]),
          });
        }
        break;
      case "POST":
        responses.addAll({
          "201": context.responses.getObject("201"),
          "400": context.responses.getObject("400"),
          "409": context.responses.getObject("409"),
          "409": context.responses.getObject("409"),
          "503": context.responses.getObject("503"),
        });
        break;
      case "PATCH":
        responses.addAll({
          "204": context.responses.getObject("204"),
          "400": context.responses.getObject("400"),
          "409": context.responses.getObject("409"),
          "503": context.responses.getObject("503"),
        });
        break;
    }
    return responses;
  }

  @override
  List<APIParameter> documentOperationParameters(APIDocumentContext context, Operation operation) {
    switch (operation.method) {
      case "GET":
        if (operation.pathVariables.isEmpty) {
          return [
            APIParameter.query('offset')..description = 'Start with [AppConfig] number equal to offset. Default is 0.',
            APIParameter.query('limit')..description = 'Maximum number of [AppConfig] to fetch. Default is 20.',
          ];
        }
        break;
    }
    return super.documentOperationParameters(context, operation);
  }

  @override
  void documentComponents(APIDocumentContext context) {
    super.documentComponents(context);
    context.schema.register(
      "AppConfig",
      APISchemaObject.object(
        {
          "uuid": APISchemaObject.string(format: 'uuid')..description = "Unique application id",
          "demo": APISchemaObject.boolean()
            ..description = "Use demo-mode (no real data and any login)"
            ..defaultValue = true,
          "demoRole": APISchemaObject.string()
            ..description = "Role of logged in user in demo-mode"
            ..defaultValue = "Commander"
            ..enumerated = [
              'Commander',
              'UnitLeader',
              'Personnel',
            ],
          "onboarding": APISchemaObject.boolean()
            ..description = "Show onboarding before next login"
            ..defaultValue = true,
          "organization": APISchemaObject.integer()
            ..description = "Default organization identifier"
            ..defaultValue = "61",
          "division": APISchemaObject.integer()
            ..description = "Default division identifier"
            ..defaultValue = "140",
          "department": APISchemaObject.integer()
            ..description = "Default department identifier"
            ..defaultValue = "141",
          "talkGroupCatalog": APISchemaObject.string()
            ..description = "Default talkgroup name"
            ..defaultValue = "Oslo",
          "storage": APISchemaObject.boolean()
            ..description = "Storage access is granted"
            ..defaultValue = false,
          "locationWhenInUse": APISchemaObject.boolean()
            ..description = "Location access when app is in use is granted"
            ..defaultValue = false,
          "mapCacheTTL": APISchemaObject.integer()
            ..description = "Number of days downloaded map tiles are cached locally"
            ..defaultValue = 30,
          "mapCacheCapacity": APISchemaObject.integer()
            ..description = "Maximum number map tiles cached locally"
            ..defaultValue = 15000,
          "locationAccuracy": APISchemaObject.string()
            ..description = "Requested location accuracy"
            ..defaultValue = 'high'
            ..enumerated = [
              'lowest',
              'low',
              'medium',
              'high',
              'best',
              'bestForNavigation',
            ],
          "locationFastestInterval": APISchemaObject.integer()
            ..description = "Fastest interval between location updates in milliseconds"
            ..defaultValue = 1000,
          "locationSmallestDisplacement": APISchemaObject.integer()
            ..description = "Smallest displacment in meters before update is received"
            ..defaultValue = 3,
          "keepScreenOn": APISchemaObject.boolean()
            ..description = "Keep screen on when maps are displayed"
            ..defaultValue = false,
          "callsignReuse": APISchemaObject.boolean()
            ..description = "Reuse callsigns for retired units"
            ..defaultValue = true,
          "sentryDns": APISchemaObject.string(format: 'uri')
            ..description = "Sentry DNS for remote error reporting"
            ..defaultValue = 'https://2d6130375010466b9652b9e9efc415cc@sentry.io/1523681',
        },
      )
        ..title = "AppConfig"
        ..description = "SarSys application configuration"
        ..required = ['uuid'],
    );
  }
}
