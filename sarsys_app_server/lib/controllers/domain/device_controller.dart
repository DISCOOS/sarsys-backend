import 'package:sarsys_app_server/controllers/domain/schemas.dart';
import 'package:sarsys_domain/sarsys_domain.dart' hide Operation;
import 'package:sarsys_app_server/sarsys_app_server.dart';

/// A ResourceController that handles
/// [/api/incidents/{uuid}/Devices](http://localhost/api/client.html#/Device) requests
class DeviceController extends AggregateController<DeviceCommand, Device> {
  DeviceController(DeviceRepository repository, JsonValidation validation)
      : super(repository,
            validation: validation,
            readOnly: const [
              'position',
              'messages',
              'transitions',
            ],
            tag: "Devices");

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
  Future<Response> create(@Bind.body() Map<String, dynamic> data) {
    return super.create(data);
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
  @Operation('DELETE', 'uuid')
  Future<Response> delete(
    @Bind.path('uuid') String uuid, {
    @Bind.body() Map<String, dynamic> data,
  }) {
    return super.delete(uuid, data: data);
  }

  @override
  DeviceCommand onCreate(Map<String, dynamic> data) => CreateDevice(data);

  @override
  Iterable<DeviceCommand> onUpdate(Map<String, dynamic> data) => [
        UpdateDevice(data),
      ];

  @override
  DeviceCommand onDelete(Map<String, dynamic> data) => DeleteDevice(data);

  //////////////////////////////////
  // Documentation
  //////////////////////////////////

  @override
  APISchemaObject documentAggregateRoot(APIDocumentContext context) => APISchemaObject.object({
        "uuid": context.schema['UUID']..description = "Unique device id",
        "type": documentType(),
        "status": documentStatus(),
        "alias": APISchemaObject.string()..description = "Device alias",
        "number": APISchemaObject.string()..description = "Device number",
        "network": APISchemaObject.string()..description = "Device network name",
        "networkId": APISchemaObject.string()..description = "Device identifier on network",
        "manual": APISchemaObject.boolean()
          ..description = "Device registered manually"
          ..defaultValue = true,
        "trackable": APISchemaObject.boolean()
          ..description = "Must be true for tracking"
          ..defaultValue = true,
        "position": documentPosition(context)
          ..description = "Current position"
          // Use PUT /api/device/{duuid}/position
          ..isReadOnly = true,
        "allocatedTo": documentAggregateRef(
          context,
          description: "Operation which device is allocated to",
          defaultType: 'Operation',
        ),
        "transitions": APISchemaObject.array(ofSchema: documentTransition())
          ..description = "State transitions (read only)"
          ..isReadOnly = true,
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
  APISchemaObject documentTransition() => APISchemaObject.object({
        "status": documentStatus(),
        "timestamp": APISchemaObject.string()
          ..description = "When transition occurred"
          ..format = 'date-time',
      })
        ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed;
}
