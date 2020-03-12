import 'package:sarsys_app_server/controllers/event_source/controllers.dart';
import 'package:sarsys_domain/sarsys_domain.dart' hide Operation;
import 'package:sarsys_app_server/sarsys_app_server.dart';
import 'package:sarsys_app_server/validation/validation.dart';

/// A ResourceController that handles
/// [/api/incidents/{uuid}/messages](http://localhost/api/client.html#/Message) requests
class DevicePositionController extends ValueController<DeviceCommand, Device> {
  DevicePositionController(DeviceRepository repository, JsonValidation validation)
      : super(
          repository,
          "Position",
          "position",
          validation: validation,
          tag: "Device > Position",
          validators: [
            ValueValidator(
              '/properties/type',
              ['manual'],
            )
          ],
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
  ) {
    return super.update(uuid, data);
  }

  @override
  DeviceCommand onUpdate(String uuid, String type, Map<String, dynamic> data) => UpdateDevicePosition(data);
}
