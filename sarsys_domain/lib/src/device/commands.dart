import 'package:event_source/event_source.dart';

import 'events.dart';

abstract class DeviceCommand<T extends DomainEvent> extends Command<T> {
  DeviceCommand(
    Action action, {
    String uuid,
    Map<String, dynamic> data = const {},
  }) : super(action, uuid: uuid, data: data);
}

//////////////////////////////////
// Device aggregate commands
//////////////////////////////////

class CreateDevice extends DeviceCommand<DeviceCreated> {
  CreateDevice(
    Map<String, dynamic> data,
  ) : super(Action.create, data: data);
}

class UpdateDevice extends DeviceCommand<DeviceInformationUpdated> {
  UpdateDevice(
    Map<String, dynamic> data,
  ) : super(Action.update, data: data);
}

class DeleteDevice extends DeviceCommand<DeviceDeleted> {
  DeleteDevice(
    Map<String, dynamic> data,
  ) : super(Action.delete, data: data);
}

//////////////////////////////////
// Device Message entity commands
//////////////////////////////////

class DeviceMessageCommand<T extends DomainEvent> extends DeviceCommand<T> implements EntityCommand<T> {
  DeviceMessageCommand(
    Action action,
    String uuid,
    Map<String, dynamic> data,
  ) : super(action, uuid: uuid, data: data);

  @override
  String get aggregateField => 'messages';

  @override
  String get entityId => data[entityIdFieldName] as String;

  @override
  String get entityIdFieldName => 'id';
}

class AddDeviceMessage extends DeviceMessageCommand<DeviceMessageAdded> {
  AddDeviceMessage(
    String uuid,
    Map<String, dynamic> data,
  ) : super(Action.create, uuid, data);
}

class UpdateDeviceMessage extends DeviceMessageCommand<DeviceMessageUpdated> {
  UpdateDeviceMessage(
    String uuid,
    Map<String, dynamic> data,
  ) : super(Action.update, uuid, data);
}

class RemoveDeviceMessage extends DeviceMessageCommand<DeviceMessageRemoved> {
  RemoveDeviceMessage(
    String uuid,
    Map<String, dynamic> data,
  ) : super(Action.delete, uuid, data);
}

//////////////////////////////////
// Device Position commands
//////////////////////////////////

class UpdateDevicePosition extends DeviceCommand<DevicePositionChanged> {
  UpdateDevicePosition(
    Map<String, dynamic> data,
  ) : super(Action.update, data: data);
}
