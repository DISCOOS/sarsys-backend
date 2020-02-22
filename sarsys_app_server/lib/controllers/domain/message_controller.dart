import 'package:sarsys_app_server/controllers/eventsource/entity_controller.dart';
import 'package:sarsys_domain/sarsys_domain.dart' as sar;
import 'package:sarsys_app_server/sarsys_app_server.dart';
import 'package:sarsys_app_server/validation/validation.dart';

/// A ResourceController that handles
/// [/api/incidents/{uuid}/messages](http://localhost/api/client.html#/Message) requests
class IncidentMessageController extends EntityController<sar.IncidentCommand, sar.Incident> {
  IncidentMessageController(sar.IncidentRepository repository, JsonValidation validation)
      : super(repository, "Message", "messages", validation: validation, tag: "Incidents > Messages");

  @override
  sar.IncidentCommand onCreate(String uuid, String type, Map<String, dynamic> data) =>
      sar.AddIncidentMessage(uuid, data);

  @override
  sar.IncidentCommand onUpdate(String uuid, String type, Map<String, dynamic> data) =>
      sar.UpdateIncidentMessage(uuid, data);

  @override
  sar.IncidentCommand onDelete(String uuid, String type, Map<String, dynamic> data) =>
      sar.RemoveIncidentMessage(uuid, data);

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
class MissionMessageController extends EntityController<sar.MissionCommand, sar.Mission> {
  MissionMessageController(sar.MissionRepository repository, JsonValidation validation)
      : super(repository, "Message", "messages", validation: validation, tag: "Missions > Messages");

  @override
  sar.MissionCommand onCreate(String uuid, String type, Map<String, dynamic> data) => sar.AddMissionMessage(uuid, data);

  @override
  sar.MissionCommand onUpdate(String uuid, String type, Map<String, dynamic> data) =>
      sar.UpdateMissionMessage(uuid, data);

  @override
  sar.MissionCommand onDelete(String uuid, String type, Map<String, dynamic> data) =>
      sar.RemoveMissionMessage(uuid, data);

  //////////////////////////////////
  // Documentation
  //////////////////////////////////

  /// Message - Entity object
  @override
  APISchemaObject documentEntityObject(APIDocumentContext context) => context.schema[entityType];
}

/// A ResourceController that handles
/// [/api/personnels/{uuid}/messages](http://localhost/api/client.html#/Message) requests
class PersonnelMessageController extends EntityController<sar.PersonnelCommand, sar.Personnel> {
  PersonnelMessageController(sar.PersonnelRepository repository, JsonValidation validation)
      : super(repository, "Message", "messages", validation: validation, tag: "Personnels > Messages");

  @override
  sar.PersonnelCommand onCreate(String uuid, String type, Map<String, dynamic> data) =>
      sar.AddPersonnelMessage(uuid, data);

  @override
  sar.PersonnelCommand onUpdate(String uuid, String type, Map<String, dynamic> data) =>
      sar.UpdatePersonnelMessage(uuid, data);

  @override
  sar.PersonnelCommand onDelete(String uuid, String type, Map<String, dynamic> data) =>
      sar.RemovePersonnelMessage(uuid, data);

  //////////////////////////////////
  // Documentation
  //////////////////////////////////

  /// Message - Entity object
  @override
  APISchemaObject documentEntityObject(APIDocumentContext context) => context.schema[entityType];
}

/// A ResourceController that handles
/// [/api/units/{uuid}/messages](http://localhost/api/client.html#/Message) requests
class UnitMessageController extends EntityController<sar.UnitCommand, sar.Unit> {
  UnitMessageController(sar.UnitRepository repository, JsonValidation validation)
      : super(repository, "Message", "messages", validation: validation, tag: "Units > Messages");

  @override
  sar.UnitCommand onCreate(String uuid, String type, Map<String, dynamic> data) => sar.AddUnitMessage(uuid, data);

  @override
  sar.UnitCommand onUpdate(String uuid, String type, Map<String, dynamic> data) => sar.UpdateUnitMessage(uuid, data);

  @override
  sar.UnitCommand onDelete(String uuid, String type, Map<String, dynamic> data) => sar.RemoveUnitMessage(uuid, data);

  //////////////////////////////////
  // Documentation
  //////////////////////////////////

  /// Message - Entity object
  @override
  APISchemaObject documentEntityObject(APIDocumentContext context) => context.schema[entityType];
}

/// A ResourceController that handles
/// [/api/devices/{uuid}/messages](http://localhost/api/client.html#/Message) requests
class DeviceMessageController extends EntityController<sar.DeviceCommand, sar.Device> {
  DeviceMessageController(sar.DeviceRepository repository, JsonValidation validation)
      : super(repository, "Message", "messages", validation: validation, tag: "Devices > Messages");

  @override
  sar.DeviceCommand onCreate(String uuid, String type, Map<String, dynamic> data) => sar.AddDeviceMessage(uuid, data);

  @override
  sar.DeviceCommand onUpdate(String uuid, String type, Map<String, dynamic> data) =>
      sar.UpdateDeviceMessage(uuid, data);

  @override
  sar.DeviceCommand onDelete(String uuid, String type, Map<String, dynamic> data) =>
      sar.RemoveDeviceMessage(uuid, data);

  //////////////////////////////////
  // Documentation
  //////////////////////////////////

  /// Message - Entity object
  @override
  APISchemaObject documentEntityObject(APIDocumentContext context) => context.schema[entityType];
}
