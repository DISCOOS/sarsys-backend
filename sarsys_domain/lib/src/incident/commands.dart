import 'package:event_source/event_source.dart';

import 'aggregate.dart';
import 'events.dart';

abstract class IncidentCommand<T extends DomainEvent> extends Command<T> {
  IncidentCommand(
    Action action, {
    String uuid,
    Map<String, dynamic> data = const {},
  }) : super(action, uuid: uuid, data: data);
}

//////////////////////////////////
// Incident aggregate commands
//////////////////////////////////

class RegisterIncident extends IncidentCommand<IncidentRegistered> {
  RegisterIncident(
    Map<String, dynamic> data,
  ) : super(Action.create, data: data);
}

class UpdateIncidentInformation extends IncidentCommand<IncidentInformationUpdated> {
  UpdateIncidentInformation(
    Map<String, dynamic> data,
  ) : super(Action.update, data: data);
}

class AddOperationToIncident extends IncidentCommand<OperationAddedToIncident> {
  AddOperationToIncident(
    Incident incident,
    String ouuid,
  ) : super(
          Action.update,
          uuid: incident.uuid,
          data: Command.addToList<String>(incident.data, 'operations', [ouuid]),
        );
}

class RemoveOperationFromIncident extends IncidentCommand<OperationRemovedFromIncident> {
  RemoveOperationFromIncident(
    Incident incident,
    String ouuid,
  ) : super(
          Action.update,
          uuid: incident.uuid,
          data: Command.removeFromList<String>(incident.data, 'operations', [ouuid]),
        );
}

class AddSubjectToIncident extends IncidentCommand<SubjectAddedToIncident> {
  AddSubjectToIncident(
    Incident incident,
    String suuid,
  ) : super(
          Action.update,
          uuid: incident.uuid,
          data: Command.addToList<String>(incident.data, 'subjects', [suuid]),
        );
}

class RemoveSubjectFromIncident extends IncidentCommand<SubjectRemovedFromIncident> {
  RemoveSubjectFromIncident(
    Incident incident,
    String suuid,
  ) : super(
          Action.update,
          uuid: incident.uuid,
          data: Command.removeFromList<String>(incident.data, 'subjects', [suuid]),
        );
}

class DeleteIncident extends IncidentCommand<IncidentDeleted> {
  DeleteIncident(
    Map<String, dynamic> data,
  ) : super(Action.delete, data: data);
}

//////////////////////////////////
// Clue entity commands
//////////////////////////////////

class ClueCommand<T extends DomainEvent> extends IncidentCommand<T> implements EntityCommand<T> {
  ClueCommand(
    Action action,
    String uuid,
    Map<String, dynamic> data,
  ) : super(action, uuid: uuid, data: data);

  @override
  String get aggregateField => 'clues';

  @override
  String get entityId => data[entityIdFieldName] as String;

  @override
  String get entityIdFieldName => 'id';
}

class AddIncidentClue extends ClueCommand<IncidentClueAdded> {
  AddIncidentClue(
    String uuid,
    Map<String, dynamic> data,
  ) : super(Action.create, uuid, data);
}

class UpdateIncidentClue extends ClueCommand<IncidentClueUpdated> {
  UpdateIncidentClue(
    String uuid,
    Map<String, dynamic> data,
  ) : super(Action.update, uuid, data);
}

class RemoveIncidentClue extends ClueCommand<IncidentClueRemoved> {
  RemoveIncidentClue(
    String uuid,
    Map<String, dynamic> data,
  ) : super(Action.delete, uuid, data);
}

//////////////////////////////////
// Incident Message entity commands
//////////////////////////////////

class IncidentMessageCommand<T extends DomainEvent> extends IncidentCommand<T> implements EntityCommand<T> {
  IncidentMessageCommand(
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

class AddIncidentMessage extends IncidentMessageCommand<IncidentMessageAdded> {
  AddIncidentMessage(
    String uuid,
    Map<String, dynamic> data,
  ) : super(Action.create, uuid, data);
}

class UpdateIncidentMessage extends IncidentMessageCommand<IncidentMessageUpdated> {
  UpdateIncidentMessage(
    String uuid,
    Map<String, dynamic> data,
  ) : super(Action.update, uuid, data);
}

class RemoveIncidentMessage extends IncidentMessageCommand<IncidentMessageRemoved> {
  RemoveIncidentMessage(
    String uuid,
    Map<String, dynamic> data,
  ) : super(Action.delete, uuid, data);
}
