import 'package:event_source/event_source.dart';

import 'events.dart';
import 'operation.dart';

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
// Operation Mission commands
//////////////////////////////////

class AddMissionToOperation extends OperationCommand<MissionAddedToOperation> {
  AddMissionToOperation(
    Operation operation,
    String muuid,
  ) : super(
          Action.update,
          uuid: operation.uuid,
          data: Command.addToList<String>(operation.data, 'missions', [muuid]),
        );
}

class RemoveMissionFromOperation extends OperationCommand<MissionRemovedFromOperation> {
  RemoveMissionFromOperation(
    Operation incident,
    String muuid,
  ) : super(
          Action.update,
          uuid: incident.uuid,
          data: Command.removeFromList<String>(incident.data, 'missions', [muuid]),
        );
}

//////////////////////////////////
// Operation Personnel commands
//////////////////////////////////

class AddPersonnelToOperation extends OperationCommand<PersonnelAddedToOperation> {
  AddPersonnelToOperation(
    Operation operation,
    String puuid,
  ) : super(
          Action.update,
          uuid: operation.uuid,
          data: Command.addToList<String>(operation.data, 'personnels', [puuid]),
        );
}

class RemovePersonnelFromOperation extends OperationCommand<PersonnelRemovedFromOperation> {
  RemovePersonnelFromOperation(
    Operation operation,
    String puuid,
  ) : super(
          Action.update,
          uuid: operation.uuid,
          data: Command.removeFromList<String>(operation.data, 'personnels', [puuid]),
        );
}

//////////////////////////////////
// Operation Unit commands
//////////////////////////////////

class AddUnitToOperation extends OperationCommand<UnitAddedToOperation> {
  AddUnitToOperation(
    Operation operation,
    String uuuid,
  ) : super(
          Action.update,
          uuid: operation.uuid,
          data: Command.addToList<String>(operation.data, 'units', [uuuid]),
        );
}

class RemoveUnitFromOperation extends OperationCommand<UnitRemovedFromOperation> {
  RemoveUnitFromOperation(
    Operation operation,
    String uuuid,
  ) : super(
          Action.update,
          uuid: operation.uuid,
          data: Command.removeFromList<String>(operation.data, 'units', [uuuid]),
        );
}

class DeleteOperation extends OperationCommand<OperationDeleted> {
  DeleteOperation(
    Map<String, dynamic> data,
  ) : super(Action.delete, data: data);
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
  String get aggregateField => 'objectives';

  @override
  String get entityId => data[entityIdFieldName] as String;

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
  String get aggregateField => 'talkgroups';

  @override
  String get entityId => data[entityIdFieldName] as String;

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

//////////////////////////////////
// Operation Message entity commands
//////////////////////////////////

class OperationMessageCommand<T extends DomainEvent> extends OperationCommand<T> implements EntityCommand<T> {
  OperationMessageCommand(
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

class AddOperationMessage extends OperationMessageCommand<OperationMessageAdded> {
  AddOperationMessage(
    String uuid,
    Map<String, dynamic> data,
  ) : super(Action.create, uuid, data);
}

class UpdateOperationMessage extends OperationMessageCommand<OperationMessageUpdated> {
  UpdateOperationMessage(
    String uuid,
    Map<String, dynamic> data,
  ) : super(Action.update, uuid, data);
}

class RemoveOperationMessage extends OperationMessageCommand<OperationMessageRemoved> {
  RemoveOperationMessage(
    String uuid,
    Map<String, dynamic> data,
  ) : super(Action.delete, uuid, data);
}
