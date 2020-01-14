import 'package:sarsys_app_server/domain/operation/events.dart';
import 'package:sarsys_app_server/eventsource/eventsource.dart';

abstract class OperationCommand<T extends DomainEvent> extends Command<T> {
  OperationCommand(
    Action action, {
    String uuid,
    Map<String, dynamic> data = const {},
  }) : super(action, uuid: uuid, data: data);
}

//////////////////////////////////
// Operation aggregate commands
//////////////////////////////////

class RegisterOperation extends OperationCommand<OperationRegistered> {
  RegisterOperation(
    Map<String, dynamic> data,
  ) : super(Action.create, data: data);
}

class UpdateOperationInformation extends OperationCommand<OperationInformationUpdated> {
  UpdateOperationInformation(
    Map<String, dynamic> data,
  ) : super(Action.update, data: data);
}

//////////////////////////////////
// Objective entity commands
//////////////////////////////////

class ObjectiveCommand<T extends DomainEvent> extends OperationCommand<T> implements EntityCommand<T> {
  ObjectiveCommand(
    Action action,
    String uuid,
    Map<String, dynamic> data,
  ) : super(action, uuid: uuid, data: data);

  @override
  String get aggregateField => "objectives";

  @override
  int get entityId => data[entityIdFieldName] as int;

  @override
  String get entityIdFieldName => 'id';
}

class AddObjective extends ObjectiveCommand<ObjectiveAdded> {
  AddObjective(
    String uuid,
    Map<String, dynamic> data,
  ) : super(Action.create, uuid, data);
}

class UpdateObjective extends ObjectiveCommand<ObjectiveUpdated> {
  UpdateObjective(
    String uuid,
    Map<String, dynamic> data,
  ) : super(Action.update, uuid, data);
}

class RemoveObjective extends ObjectiveCommand<ObjectiveRemoved> {
  RemoveObjective(
    String uuid,
    Map<String, dynamic> data,
  ) : super(Action.delete, uuid, data);
}

//////////////////////////////////
// TalkGroup entity commands
//////////////////////////////////

class TalkGroupCommand<T extends DomainEvent> extends OperationCommand<T> implements EntityCommand<T> {
  TalkGroupCommand(
    Action action,
    String uuid,
    Map<String, dynamic> data,
  ) : super(action, uuid: uuid, data: data);

  @override
  String get aggregateField => "talkgroups";

  @override
  int get entityId => data[entityIdFieldName] as int;

  @override
  String get entityIdFieldName => 'id';
}

class AddTalkGroup extends TalkGroupCommand<TalkGroupAdded> {
  AddTalkGroup(
    String uuid,
    Map<String, dynamic> data,
  ) : super(Action.create, uuid, data);
}

class UpdateTalkGroup extends TalkGroupCommand<TalkGroupUpdated> {
  UpdateTalkGroup(
    String uuid,
    Map<String, dynamic> data,
  ) : super(Action.update, uuid, data);
}

class RemoveTalkGroup extends TalkGroupCommand<TalkGroupRemoved> {
  RemoveTalkGroup(
    String uuid,
    Map<String, dynamic> data,
  ) : super(Action.delete, uuid, data);
}
