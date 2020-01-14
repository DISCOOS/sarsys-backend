import 'package:sarsys_app_server/eventsource/eventsource.dart';

import 'events.dart';

abstract class UnitCommand<T extends DomainEvent> extends Command<T> {
  UnitCommand(
    Action action, {
    String uuid,
    Map<String, dynamic> data = const {},
  }) : super(action, uuid: uuid, data: data);
}

//////////////////////////////////
// Unit aggregate commands
//////////////////////////////////

class CreateUnit extends UnitCommand<UnitCreated> {
  CreateUnit(
    Map<String, dynamic> data,
  ) : super(Action.create, data: data);
}

class UpdateUnitInformation extends UnitCommand<UnitInformationUpdated> {
  UpdateUnitInformation(
    Map<String, dynamic> data,
  ) : super(Action.update, data: data);
}

class MobilizeUnit extends UnitCommand<UnitMobilized> {
  MobilizeUnit(
    Map<String, dynamic> data,
  ) : super(Action.update, data: data);
}

class DeployUnit extends UnitCommand<UnitDeployed> {
  DeployUnit(
    Map<String, dynamic> data,
  ) : super(Action.update, data: data);
}

class RetireUnit extends UnitCommand<UnitMobilized> {
  RetireUnit(
    Map<String, dynamic> data,
  ) : super(Action.update, data: data);
}

class DeleteUnit extends UnitCommand<UnitDeleted> {
  DeleteUnit(
    Map<String, dynamic> data,
  ) : super(Action.delete, data: data);
}
