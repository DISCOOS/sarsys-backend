import 'package:sarsys_app_server/eventsource/eventsource.dart';

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
