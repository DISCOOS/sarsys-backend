import 'package:sarsys_app_server/controllers/eventsource/aggregate_controller.dart';
import 'package:sarsys_app_server/domain/device/device.dart';
import 'package:sarsys_app_server/sarsys_app_server.dart';
import 'package:sarsys_app_server/validation/validation.dart';

/// A ResourceController that handles
/// [/api/incidents/{uuid}/Devices](http://localhost/api/client.html#/Device) requests
class DeviceController extends AggregateController<DeviceCommand, Device> {
  DeviceController(DeviceRepository repository, JsonValidation validation)
      : super(repository, validation: validation, readOnly: const ['division'], tag: "Devices");

  @override
  DeviceCommand onCreate(Map<String, dynamic> data) => CreateDevice(data);

  @override
  DeviceCommand onUpdate(Map<String, dynamic> data) => UpdateDevice(data);

  @override
  DeviceCommand onDelete(Map<String, dynamic> data) => DeleteDevice(data);

  //////////////////////////////////
  // Documentation
  //////////////////////////////////

  @override
  APISchemaObject documentAggregateRoot(APIDocumentContext context) => APISchemaObject.object({
        "uuid": context.schema['UUID']..description = "Unique device id",
        "type": documentType()..isReadOnly = true,
        "status": documentStatus()..isReadOnly = true,
        "name": APISchemaObject.string()..description = "Device name",
        "alias": APISchemaObject.string()..description = "Device alias",
        "network": APISchemaObject.string()..description = "Device network name",
        "networkId": APISchemaObject.string()..description = "Device identifier on network",
        "position": context.schema['Position']..description = "Current position",
      })
        ..description = "Device Schema (aggregate root)"
        ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
        ..required = [
          'uuid',
          'name',
        ];

  /// DeviceStatus - Value Object
  APISchemaObject documentStatus() => APISchemaObject.string()
    ..description = "Device status"
    ..defaultValue = "none"
    ..isReadOnly = true
    ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
    ..enumerated = [
      'attached',
      'detached',
    ];

  /// DeviceType - Value Object
  APISchemaObject documentType() => APISchemaObject.string()
    ..description = "Device type"
    ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
    ..enumerated = [
      'tetra',
      'app',
      'aprs',
      'ais',
      'spot',
      'inreach',
    ];
}
