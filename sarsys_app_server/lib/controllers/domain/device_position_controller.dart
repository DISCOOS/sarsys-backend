import 'package:sarsys_domain/sarsys_domain.dart' hide Operation;
import 'package:sarsys_app_server/sarsys_app_server.dart';

class DevicePositionController extends DevicePositionControllerBase {
  DevicePositionController(DeviceRepository repository, JsonValidation validation)
      : super(
          repository,
          validation,
        );

  @override
  @Operation.get('uuid')
  Future<Response> get(@Bind.path('uuid') String uuid) {
    return super.get(uuid);
  }

  @override
  @Operation('PATCH', 'uuid')
  Future<Response> update(
    @Bind.path('uuid') String uuid,
    @Bind.body() Map<String, dynamic> data,
  ) =>
      super.update(
        uuid,
        data,
      );
}

class DevicePositionControllerBase extends ValueController<DeviceCommand, Device> {
  DevicePositionControllerBase(DeviceRepository repository, JsonValidation validation)
      : super(
          repository,
          "Position",
          "position",
          validation: validation,
          tag: "Device > Position",
        );

  @override
  Future<Response> update(
    @Bind.path('uuid') String uuid,
    @Bind.body() Map<String, dynamic> data,
  ) async {
    if (!await exists(uuid)) {
      return Response.notFound(body: "$aggregateType $uuid not found");
    }
    return super.update(
      uuid,
      process(uuid, data),
    );
  }

  Map<String, dynamic> process(String uuid, Map<String, dynamic> data) {
    final aggregate = repository.get(uuid);
    final currProps = aggregate.data.elementAt('$aggregateField/properties');
    final nextProps = data.mapAt<String, dynamic>('properties', defaultMap: {});

    // Enforce defaults?
    if (currProps == null) {
      nextProps['timestamp'] ??= DateTime.now().toIso8601String();
    }
    nextProps['source'] ??= 'manual';

    // TODO: Remove when confidence bug in Background Geolocation is resolved
    final confidence = nextProps.elementAt('activity/confidence');
    if (confidence is double) {
      nextProps['activity']['confidence'] = confidence.toInt();
    }

    // Update properties
    data['properties'] = nextProps;

    // TODO: Remove when provider bug in Background Geolocation is resolved
    data.remove('provider');

    return data;
  }

  @override
  DeviceCommand onUpdate(String uuid, String type, Map<String, dynamic> data) => UpdateDevicePosition(data);
}
