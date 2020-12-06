import 'package:event_source/event_source.dart';
import 'package:sarsys_app_server/controllers/domain/schemas.dart';
import 'package:sarsys_app_server/controllers/event_source/aggregate_controller.dart';
import 'package:sarsys_app_server/sarsys_app_server.dart';
import 'package:sarsys_app_server/validation/validation.dart';
import 'package:sarsys_domain/sarsys_domain.dart' hide Operation;

import 'app_config.dart';

/// A ResourceController that handles
/// [/api/app-config](http://localhost/api/client.html#/AppConfig) [Request]s
class AppConfigController extends AggregateController<AppConfigCommand, AppConfig> {
  AppConfigController(AppConfigRepository repository, this.devices, JsonValidation validation)
      : super(repository, validation: validation, tag: 'Tenant');

  final DeviceRepository devices;

  @override
  @Operation.get()
  Future<Response> getAll({
    @Bind.query('offset') int offset = 0,
    @Bind.query('limit') int limit = 20,
    @Bind.query('deleted') bool deleted = false,
  }) {
    return super.getAll(
      offset: offset,
      limit: limit,
      deleted: deleted,
    );
  }

  @override
  @Operation.get('uuid')
  Future<Response> getByUuid(@Bind.path('uuid') String uuid) {
    return super.getByUuid(uuid);
  }

  @override
  @Operation.post()
  Future<Response> create(@Bind.body() Map<String, dynamic> data) async {
    return withResponseWaitForRuleResult<DeviceCreated>(
      await super.create(data),
      fail: true,
      timeout: const Duration(milliseconds: 1000),
      test: (_) => shouldWaitForDeviceCreated(data),
    );
  }

  @override
  @Operation('PATCH', 'uuid')
  Future<Response> update(
    @Bind.path('uuid') String uuid,
    @Bind.body() Map<String, dynamic> data,
  ) async {
    return withResponseWaitForRuleResult<DeviceCreated>(
      await super.update(uuid, data),
      fail: true,
      timeout: const Duration(milliseconds: 1000),
      test: (_) => shouldWaitForDeviceCreated(
        repository.get(uuid).data,
      ),
    );
  }

  Future<bool> shouldWaitForDeviceCreated(Map<String, dynamic> data) async {
    final duuid = data.elementAt<String>('udid');
    if (!devices.exists(duuid)) {
      await devices.catchup(
        master: true,
        uuids: [duuid],
      );
    }
    return !devices.exists(duuid);
  }

  @override
  @Operation('DELETE', 'uuid')
  Future<Response> delete(
    @Bind.path('uuid') String uuid, {
    @Bind.body() Map<String, dynamic> data,
  }) async {
    final last = shouldWaitForDeviceDeleted(uuid);
    return withResponseWaitForRuleResult<DeviceDeleted>(
      await super.delete(uuid, data: data),
      fail: true,
      test: (_) => Future.value(last),
      timeout: const Duration(milliseconds: 1000),
    );
  }

  bool shouldWaitForDeviceDeleted(String uuid) {
    final aggregate = repository.get(
      uuid,
      createNew: false,
    );
    final udid = aggregate?.data?.elementAt<String>('udid');
    final refs = repository.aggregates
        // Only check app-configs not deleted
        .where((test) => !test.isDeleted)
        // Check for other app-configs referencing  same device
        .where((test) => test.udid == udid);
    return refs.length == 1;
  }

  @override
  AppConfigCommand onCreate(Map<String, dynamic> data) => CreateAppConfig(data);

  @override
  Iterable<AppConfigCommand> onUpdate(Map<String, dynamic> data) => [UpdateAppConfig(data)];

  @override
  AppConfigCommand onDelete(Map<String, dynamic> data) => DeleteAppConfig(data);

  //////////////////////////////////
  // Documentation
  //////////////////////////////////

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

  /// AppConfig - Aggregate root
  @override
  APISchemaObject documentAggregateRoot(APIDocumentContext context) => APISchemaObject.object(
        {
          "uuid": documentUUID()..description = "Unique application configuration id",
          "version": APISchemaObject.integer()
            ..description = "AppConfig version for backwards compatibility"
            ..defaultValue = 1,
          "udid": documentUUID()
            ..description = "Unique device id, typically [ANDROID_ID] "
                "for Android and [identifierForVendor] for iOS platforms",
          "demo": APISchemaObject.boolean()
            ..description = "Use demo-mode (no real data and any login)"
            ..defaultValue = true,
          "demoRole": APISchemaObject.string()
            ..description = "Role of logged in user in demo-mode"
            ..defaultValue = "commander"
            ..enumerated = [
              'oversight',
              'commander',
              'unit_leader',
              'personnel',
            ],
          "onboarded": APISchemaObject.boolean()
            ..description = "Show onboarding before next login"
            ..defaultValue = true,
          "firstSetup": APISchemaObject.boolean()
            ..description = "Show first setup before next login"
            ..defaultValue = true,
          "securityMode": APISchemaObject.string()
            ..description = "Security mode applied to application"
            ..enumerated = ['personal', 'shared'],
          "securityType": APISchemaObject.string()
            ..description = "Security type"
            ..enumerated = ['pin', 'fingerprint'],
          "securityPin": APISchemaObject.string()..description = "Security pin",
          "securityLockAfter": APISchemaObject.integer()
            ..description = "Lock idle device (no user interactions) after in given number of seconds"
            ..defaultValue = 2700, // 45 minutes
          "talkGroups": APISchemaObject.array(ofType: APIType.string)
            ..description = "List of default talk group names"
            ..defaultValue = ["Oslo"],
          "talkGroupCatalog": APISchemaObject.string()
            ..description = "Default talk group catalog name"
            ..defaultValue = "Oslo",
          "idpHints": APISchemaObject.array(ofType: APIType.string)
            ..description = "List of idp hints"
            ..defaultValue = ["google"],
          "trustedDomains": APISchemaObject.array(ofType: APIType.string)
            ..description = "List of trusted domains"
            ..defaultValue = ["rodekors.org", "discoos.org"],
          "units": APISchemaObject.array(ofType: APIType.string)
            ..description = "List of templates for units to create automatically when opening an new operation",
          "storage": APISchemaObject.boolean()
            ..description = "Storage access is granted"
            ..defaultValue = false,
          "locationAlways": APISchemaObject.boolean()
            ..description = "Location access always is is granted"
            ..defaultValue = false,
          "locationWhenInUse": APISchemaObject.boolean()
            ..description = "Location access when app is in use is granted"
            ..defaultValue = false,
          "locationStoreLocally": APISchemaObject.boolean()
            ..description = "Store locations locally"
            ..defaultValue = true,
          "locationAllowSharing": APISchemaObject.boolean()
            ..description = "Share locations with operation when personnel"
            ..defaultValue = true,
          "activityRecognition": APISchemaObject.boolean()
            ..description = "Activity recognition access is granted"
            ..defaultValue = false,
          "mapCacheTTL": APISchemaObject.integer()
            ..description = "Number of days downloaded map tiles are cached locally"
            ..defaultValue = 30,
          "mapRetinaMode": APISchemaObject.boolean()
            ..description = "Show high resolution maps is possible"
            ..defaultValue = false,
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
              'navigation',
              'automatic',
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
        ..description = "SarSys application configuration"
        ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
        ..required = ['uuid'];
}
