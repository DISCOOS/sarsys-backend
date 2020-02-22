import 'package:sarsys_app_server/controllers/eventsource/aggregate_controller.dart';
import 'package:sarsys_app_server/domain/device/device.dart';
import 'package:sarsys_app_server/app_server.dart';
import 'package:sarsys_app_server/validation/validation.dart';

/// A ResourceController that handles
/// [/api/incidents/{uuid}/Devices](http://localhost/api/client.html#/Device) requests
class DeviceController extends AggregateController<DeviceCommand, Device> {
  DeviceController(DeviceRepository repository, JsonValidation validation)
      : super(repository,
            validation: validation,
            readOnly: const [
              'division',
              'messages',
              'transitions',
            ],
            tag: "Devices");

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
        "assignedTo": context.schema['UUID']..description = "Uuid of unit assigned to mission",
        "transitions": documentTransitions(),
        "messages": APISchemaObject.array(ofSchema: context.schema['Message'])
          ..isReadOnly = true
          ..description = "List of messages added to Device",
      })
        ..description = "Device Schema (aggregate root)"
        ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
        ..required = [
          'uuid',
        ];

  /// DeviceStatus - Value Object
  APISchemaObject documentStatus() => APISchemaObject.string()
    ..description = "Device status"
    ..defaultValue = "unavailable"
    ..isReadOnly = true
    ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
    ..enumerated = [
      'available',
      'unavailable',
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

  /// Device transitions - Value Object
  APISchemaObject documentTransitions() => APISchemaObject.array(ofType: APIType.object)
    ..items = APISchemaObject.object({
      "status": documentStatus(),
      "timestamp": APISchemaObject.string()
        ..description = "When transition occured"
        ..format = 'date-time',
    })
    ..isReadOnly = true
    ..description = "State transitions (read only)"
    ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed;
}
