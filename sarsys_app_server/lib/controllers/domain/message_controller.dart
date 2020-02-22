import 'package:sarsys_app_server/controllers/eventsource/entity_controller.dart';
import 'package:sarsys_app_server/domain/device/device.dart';
import 'package:sarsys_app_server/domain/incident/incident.dart';
import 'package:sarsys_app_server/domain/mission/mission.dart';
import 'package:sarsys_app_server/domain/operation/operation.dart' as sar;
import 'package:sarsys_app_server/domain/personnel/personnel.dart';
import 'package:sarsys_app_server/domain/unit/unit.dart';
import 'package:sarsys_app_server/app_server.dart';
import 'package:sarsys_app_server/validation/validation.dart';

/// A ResourceController that handles
/// [/api/incidents/{uuid}/messages](http://localhost/api/client.html#/Message) requests
class IncidentMessageController extends EntityController<IncidentCommand, Incident> {
  IncidentMessageController(IncidentRepository repository, JsonValidation validation)
      : super(repository, "Message", "messages", validation: validation, tag: "Incidents > Messages");

  @override
  IncidentCommand onCreate(String uuid, String type, Map<String, dynamic> data) => AddIncidentMessage(uuid, data);

  @override
  IncidentCommand onUpdate(String uuid, String type, Map<String, dynamic> data) => UpdateIncidentMessage(uuid, data);

  @override
  IncidentCommand onDelete(String uuid, String type, Map<String, dynamic> data) => RemoveIncidentMessage(uuid, data);

  //////////////////////////////////
  // Documentation
  //////////////////////////////////

  /// Message - Entity object
  @override
  APISchemaObject documentEntityObject(APIDocumentContext context) => context.schema[entityType];
}

/// A ResourceController that handles
/// [/api/operations/{uuid}/messages](http://localhost/api/client.html#/Message) requests
class OperationMessageController extends EntityController<sar.OperationCommand, sar.Operation> {
  OperationMessageController(sar.OperationRepository repository, JsonValidation validation)
      : super(repository, "Message", "messages", validation: validation, tag: "Operations > Messages");

  @override
  sar.OperationCommand onCreate(String uuid, String type, Map<String, dynamic> data) =>
      sar.AddOperationMessage(uuid, data);

  @override
  sar.OperationCommand onUpdate(String uuid, String type, Map<String, dynamic> data) =>
      sar.UpdateOperationMessage(uuid, data);

  @override
  sar.OperationCommand onDelete(String uuid, String type, Map<String, dynamic> data) =>
      sar.RemoveOperationMessage(uuid, data);

  //////////////////////////////////
  // Documentation
  //////////////////////////////////

  /// Message - Entity object
  @override
  APISchemaObject documentEntityObject(APIDocumentContext context) => context.schema[entityType];
}

/// A ResourceController that handles
/// [/api/missions/{uuid}/messages](http://localhost/api/client.html#/Message) requests
class MissionMessageController extends EntityController<MissionCommand, Mission> {
  MissionMessageController(MissionRepository repository, JsonValidation validation)
      : super(repository, "Message", "messages", validation: validation, tag: "Missions > Messages");

  @override
  MissionCommand onCreate(String uuid, String type, Map<String, dynamic> data) => AddMissionMessage(uuid, data);

  @override
  MissionCommand onUpdate(String uuid, String type, Map<String, dynamic> data) => UpdateMissionMessage(uuid, data);

  @override
  MissionCommand onDelete(String uuid, String type, Map<String, dynamic> data) => RemoveMissionMessage(uuid, data);

  //////////////////////////////////
  // Documentation
  //////////////////////////////////

  /// Message - Entity object
  @override
  APISchemaObject documentEntityObject(APIDocumentContext context) => context.schema[entityType];
}

/// A ResourceController that handles
/// [/api/personnels/{uuid}/messages](http://localhost/api/client.html#/Message) requests
class PersonnelMessageController extends EntityController<PersonnelCommand, Personnel> {
  PersonnelMessageController(PersonnelRepository repository, JsonValidation validation)
      : super(repository, "Message", "messages", validation: validation, tag: "Personnels > Messages");

  @override
  PersonnelCommand onCreate(String uuid, String type, Map<String, dynamic> data) => AddPersonnelMessage(uuid, data);

  @override
  PersonnelCommand onUpdate(String uuid, String type, Map<String, dynamic> data) => UpdatePersonnelMessage(uuid, data);

  @override
  PersonnelCommand onDelete(String uuid, String type, Map<String, dynamic> data) => RemovePersonnelMessage(uuid, data);

  //////////////////////////////////
  // Documentation
  //////////////////////////////////

  /// Message - Entity object
  @override
  APISchemaObject documentEntityObject(APIDocumentContext context) => context.schema[entityType];
}

/// A ResourceController that handles
/// [/api/units/{uuid}/messages](http://localhost/api/client.html#/Message) requests
class UnitMessageController extends EntityController<UnitCommand, Unit> {
  UnitMessageController(UnitRepository repository, JsonValidation validation)
      : super(repository, "Message", "messages", validation: validation, tag: "Units > Messages");

  @override
  UnitCommand onCreate(String uuid, String type, Map<String, dynamic> data) => AddUnitMessage(uuid, data);

  @override
  UnitCommand onUpdate(String uuid, String type, Map<String, dynamic> data) => UpdateUnitMessage(uuid, data);

  @override
  UnitCommand onDelete(String uuid, String type, Map<String, dynamic> data) => RemoveUnitMessage(uuid, data);

  //////////////////////////////////
  // Documentation
  //////////////////////////////////

  /// Message - Entity object
  @override
  APISchemaObject documentEntityObject(APIDocumentContext context) => context.schema[entityType];
}

/// A ResourceController that handles
/// [/api/devices/{uuid}/messages](http://localhost/api/client.html#/Message) requests
class DeviceMessageController extends EntityController<DeviceCommand, Device> {
  DeviceMessageController(DeviceRepository repository, JsonValidation validation)
      : super(repository, "Message", "messages", validation: validation, tag: "Devices > Messages");

  @override
  DeviceCommand onCreate(String uuid, String type, Map<String, dynamic> data) => AddDeviceMessage(uuid, data);

  @override
  DeviceCommand onUpdate(String uuid, String type, Map<String, dynamic> data) => UpdateDeviceMessage(uuid, data);

  @override
  DeviceCommand onDelete(String uuid, String type, Map<String, dynamic> data) => RemoveDeviceMessage(uuid, data);

  //////////////////////////////////
  // Documentation
  //////////////////////////////////

  /// Message - Entity object
  @override
  APISchemaObject documentEntityObject(APIDocumentContext context) => context.schema[entityType];
}
