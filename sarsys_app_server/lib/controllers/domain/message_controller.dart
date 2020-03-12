import 'package:sarsys_app_server/controllers/event_source/entity_controller.dart';
import 'package:sarsys_domain/sarsys_domain.dart' hide Operation;
import 'package:sarsys_domain/sarsys_domain.dart' as sar show Operation;
import 'package:sarsys_app_server/sarsys_app_server.dart';
import 'package:sarsys_app_server/validation/validation.dart';

/// A ResourceController that handles
/// [/api/incidents/{uuid}/messages](http://localhost/api/client.html#/Message) requests
class IncidentMessageController extends EntityController<IncidentCommand, Incident> {
  IncidentMessageController(IncidentRepository repository, JsonValidation validation)
      : super(repository, "Message", "messages", validation: validation, tag: "Incidents > Messages");

  @override
  @Operation.get('uuid')
  Future<Response> getAll(@Bind.path('uuid') String uuid) {
    return super.getAll(uuid);
  }

  @override
  @Operation.get('uuid', 'id')
  Future<Response> getById(
    @Bind.path('uuid') String uuid,
    @Bind.path('id') String id,
  ) {
    return super.getById(uuid, id);
  }

  @override
  @Operation.post('uuid')
  Future<Response> create(
    @Bind.path('uuid') String uuid,
    @Bind.body() Map<String, dynamic> data,
  ) {
    return super.create(uuid, data);
  }

  @override
  @Operation('PATCH', 'uuid', 'id')
  Future<Response> update(
    @Bind.path('uuid') String uuid,
    @Bind.path('id') String id,
    @Bind.body() Map<String, dynamic> data,
  ) {
    return super.update(uuid, id, data);
  }

  @override
  @Operation('DELETE', 'uuid', 'id')
  Future<Response> delete(
    @Bind.path('uuid') String uuid,
    @Bind.path('id') String id, {
    @Bind.body() Map<String, dynamic> data,
  }) {
    return super.delete(uuid, id, data: data);
  }

  @override
  IncidentCommand onCreate(String uuid, String type, Map<String, dynamic> data) => AddIncidentMessage(uuid, data);

  @override
  IncidentCommand onUpdate(String uuid, String type, Map<String, dynamic> data) => UpdateIncidentMessage(uuid, data);

  @override
  IncidentCommand onDelete(String uuid, String type, Map<String, dynamic> data) => RemoveIncidentMessage(uuid, data);
}

/// A ResourceController that handles
/// [/api/operations/{uuid}/messages](http://localhost/api/client.html#/Message) requests
class OperationMessageController extends EntityController<OperationCommand, sar.Operation> {
  OperationMessageController(OperationRepository repository, JsonValidation validation)
      : super(repository, "Message", "messages", validation: validation, tag: "Operations > Messages");

  @override
  @Operation.get('uuid')
  Future<Response> getAll(@Bind.path('uuid') String uuid) {
    return super.getAll(uuid);
  }

  @override
  @Operation.get('uuid', 'id')
  Future<Response> getById(
    @Bind.path('uuid') String uuid,
    @Bind.path('id') String id,
  ) {
    return super.getById(uuid, id);
  }

  @override
  @Operation.post('uuid')
  Future<Response> create(
    @Bind.path('uuid') String uuid,
    @Bind.body() Map<String, dynamic> data,
  ) {
    return super.create(uuid, data);
  }

  @override
  @Operation('PATCH', 'uuid', 'id')
  Future<Response> update(
    @Bind.path('uuid') String uuid,
    @Bind.path('id') String id,
    @Bind.body() Map<String, dynamic> data,
  ) {
    return super.update(uuid, id, data);
  }

  @override
  @Operation('DELETE', 'uuid', 'id')
  Future<Response> delete(
    @Bind.path('uuid') String uuid,
    @Bind.path('id') String id, {
    @Bind.body() Map<String, dynamic> data,
  }) {
    return super.delete(uuid, id, data: data);
  }

  @override
  OperationCommand onCreate(String uuid, String type, Map<String, dynamic> data) => AddOperationMessage(uuid, data);

  @override
  OperationCommand onUpdate(String uuid, String type, Map<String, dynamic> data) => UpdateOperationMessage(uuid, data);

  @override
  OperationCommand onDelete(String uuid, String type, Map<String, dynamic> data) => RemoveOperationMessage(uuid, data);
}

/// A ResourceController that handles
/// [/api/missions/{uuid}/messages](http://localhost/api/client.html#/Message) requests
class MissionMessageController extends EntityController<MissionCommand, Mission> {
  MissionMessageController(MissionRepository repository, JsonValidation validation)
      : super(repository, "Message", "messages", validation: validation, tag: "Missions > Messages");

  @override
  @Operation.get('uuid')
  Future<Response> getAll(@Bind.path('uuid') String uuid) {
    return super.getAll(uuid);
  }

  @override
  @Operation.get('uuid', 'id')
  Future<Response> getById(
    @Bind.path('uuid') String uuid,
    @Bind.path('id') String id,
  ) {
    return super.getById(uuid, id);
  }

  @override
  @Operation.post('uuid')
  Future<Response> create(
    @Bind.path('uuid') String uuid,
    @Bind.body() Map<String, dynamic> data,
  ) {
    return super.create(uuid, data);
  }

  @override
  @Operation('PATCH', 'uuid', 'id')
  Future<Response> update(
    @Bind.path('uuid') String uuid,
    @Bind.path('id') String id,
    @Bind.body() Map<String, dynamic> data,
  ) {
    return super.update(uuid, id, data);
  }

  @override
  @Operation('DELETE', 'uuid', 'id')
  Future<Response> delete(
    @Bind.path('uuid') String uuid,
    @Bind.path('id') String id, {
    @Bind.body() Map<String, dynamic> data,
  }) {
    return super.delete(uuid, id, data: data);
  }

  @override
  MissionCommand onCreate(String uuid, String type, Map<String, dynamic> data) => AddMissionMessage(uuid, data);

  @override
  MissionCommand onUpdate(String uuid, String type, Map<String, dynamic> data) => UpdateMissionMessage(uuid, data);

  @override
  MissionCommand onDelete(String uuid, String type, Map<String, dynamic> data) => RemoveMissionMessage(uuid, data);
}

/// A ResourceController that handles
/// [/api/personnels/{uuid}/messages](http://localhost/api/client.html#/Message) requests
class PersonnelMessageController extends EntityController<PersonnelCommand, Personnel> {
  PersonnelMessageController(PersonnelRepository repository, JsonValidation validation)
      : super(repository, "Message", "messages", validation: validation, tag: "Personnels > Messages");

  @override
  @Operation.get('uuid')
  Future<Response> getAll(@Bind.path('uuid') String uuid) {
    return super.getAll(uuid);
  }

  @override
  @Operation.get('uuid', 'id')
  Future<Response> getById(
    @Bind.path('uuid') String uuid,
    @Bind.path('id') String id,
  ) {
    return super.getById(uuid, id);
  }

  @override
  @Operation.post('uuid')
  Future<Response> create(
    @Bind.path('uuid') String uuid,
    @Bind.body() Map<String, dynamic> data,
  ) {
    return super.create(uuid, data);
  }

  @override
  @Operation('PATCH', 'uuid', 'id')
  Future<Response> update(
    @Bind.path('uuid') String uuid,
    @Bind.path('id') String id,
    @Bind.body() Map<String, dynamic> data,
  ) {
    return super.update(uuid, id, data);
  }

  @override
  @Operation('DELETE', 'uuid', 'id')
  Future<Response> delete(
    @Bind.path('uuid') String uuid,
    @Bind.path('id') String id, {
    @Bind.body() Map<String, dynamic> data,
  }) {
    return super.delete(uuid, id, data: data);
  }

  @override
  PersonnelCommand onCreate(String uuid, String type, Map<String, dynamic> data) => AddPersonnelMessage(uuid, data);

  @override
  PersonnelCommand onUpdate(String uuid, String type, Map<String, dynamic> data) => UpdatePersonnelMessage(uuid, data);

  @override
  PersonnelCommand onDelete(String uuid, String type, Map<String, dynamic> data) => RemovePersonnelMessage(uuid, data);
}

/// A ResourceController that handles
/// [/api/units/{uuid}/messages](http://localhost/api/client.html#/Message) requests
class UnitMessageController extends EntityController<UnitCommand, Unit> {
  UnitMessageController(UnitRepository repository, JsonValidation validation)
      : super(repository, "Message", "messages", validation: validation, tag: "Units > Messages");

  @override
  @Operation.get('uuid')
  Future<Response> getAll(@Bind.path('uuid') String uuid) {
    return super.getAll(uuid);
  }

  @override
  @Operation.get('uuid', 'id')
  Future<Response> getById(
    @Bind.path('uuid') String uuid,
    @Bind.path('id') String id,
  ) {
    return super.getById(uuid, id);
  }

  @override
  @Operation.post('uuid')
  Future<Response> create(
    @Bind.path('uuid') String uuid,
    @Bind.body() Map<String, dynamic> data,
  ) {
    return super.create(uuid, data);
  }

  @override
  @Operation('PATCH', 'uuid', 'id')
  Future<Response> update(
    @Bind.path('uuid') String uuid,
    @Bind.path('id') String id,
    @Bind.body() Map<String, dynamic> data,
  ) {
    return super.update(uuid, id, data);
  }

  @override
  @Operation('DELETE', 'uuid', 'id')
  Future<Response> delete(
    @Bind.path('uuid') String uuid,
    @Bind.path('id') String id, {
    @Bind.body() Map<String, dynamic> data,
  }) {
    return super.delete(uuid, id, data: data);
  }

  @override
  UnitCommand onCreate(String uuid, String type, Map<String, dynamic> data) => AddUnitMessage(uuid, data);

  @override
  UnitCommand onUpdate(String uuid, String type, Map<String, dynamic> data) => UpdateUnitMessage(uuid, data);

  @override
  UnitCommand onDelete(String uuid, String type, Map<String, dynamic> data) => RemoveUnitMessage(uuid, data);
}

/// A ResourceController that handles
/// [/api/devices/{uuid}/messages](http://localhost/api/client.html#/Message) requests
class DeviceMessageController extends EntityController<DeviceCommand, Device> {
  DeviceMessageController(DeviceRepository repository, JsonValidation validation)
      : super(repository, "Message", "messages", validation: validation, tag: "Devices > Messages");

  @override
  @Operation.get('uuid')
  Future<Response> getAll(@Bind.path('uuid') String uuid) {
    return super.getAll(uuid);
  }

  @override
  @Operation.get('uuid', 'id')
  Future<Response> getById(
    @Bind.path('uuid') String uuid,
    @Bind.path('id') String id,
  ) {
    return super.getById(uuid, id);
  }

  @override
  @Operation.post('uuid')
  Future<Response> create(
    @Bind.path('uuid') String uuid,
    @Bind.body() Map<String, dynamic> data,
  ) {
    return super.create(uuid, data);
  }

  @override
  @Operation('PATCH', 'uuid', 'id')
  Future<Response> update(
    @Bind.path('uuid') String uuid,
    @Bind.path('id') String id,
    @Bind.body() Map<String, dynamic> data,
  ) {
    return super.update(uuid, id, data);
  }

  @override
  @Operation('DELETE', 'uuid', 'id')
  Future<Response> delete(
    @Bind.path('uuid') String uuid,
    @Bind.path('id') String id, {
    @Bind.body() Map<String, dynamic> data,
  }) {
    return super.delete(uuid, id, data: data);
  }

  @override
  DeviceCommand onCreate(String uuid, String type, Map<String, dynamic> data) => AddDeviceMessage(uuid, data);

  @override
  DeviceCommand onUpdate(String uuid, String type, Map<String, dynamic> data) => UpdateDeviceMessage(uuid, data);

  @override
  DeviceCommand onDelete(String uuid, String type, Map<String, dynamic> data) => RemoveDeviceMessage(uuid, data);
}
