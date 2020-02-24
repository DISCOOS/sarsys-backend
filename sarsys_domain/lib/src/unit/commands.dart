import 'package:event_source/event_source.dart';

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

//////////////////////////////////
// Unit Message entity commands
//////////////////////////////////

class UnitMessageCommand<T extends DomainEvent> extends UnitCommand<T> implements EntityCommand<T> {
  UnitMessageCommand(
    Action action,
    String uuid,
    Map<String, dynamic> data,
  ) : super(action, uuid: uuid, data: data);

  @override
  String get aggregateField => 'messages';

  @override
  int get entityId => data[entityIdFieldName] as int;

  @override
  String get entityIdFieldName => 'id';
}

class AddUnitMessage extends UnitMessageCommand<UnitMessageAdded> {
  AddUnitMessage(
    String uuid,
    Map<String, dynamic> data,
  ) : super(Action.create, uuid, data);
}

class UpdateUnitMessage extends UnitMessageCommand<UnitMessageUpdated> {
  UpdateUnitMessage(
    String uuid,
    Map<String, dynamic> data,
  ) : super(Action.update, uuid, data);
}

class RemoveUnitMessage extends UnitMessageCommand<UnitMessageRemoved> {
  RemoveUnitMessage(
    String uuid,
    Map<String, dynamic> data,
  ) : super(Action.delete, uuid, data);
}