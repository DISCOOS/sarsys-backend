import 'package:sarsys_app_server/eventsource/eventsource.dart';

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
    String operationUuid,
  ) : super(
          Action.update,
          uuid: incident.uuid,
          data: Command.addToList<String>(incident.data, 'operations', operationUuid),
        );
}

class RemoveOperationFromIncident extends IncidentCommand<OperationRemovedFromIncident> {
  RemoveOperationFromIncident(
    Incident incident,
    String operationUuid,
  ) : super(
          Action.update,
          uuid: incident.uuid,
          data: Command.removeFromList<String>(incident.data, 'operations', operationUuid),
        );
}

class DeleteIncident extends IncidentCommand<IncidentDeleted> {
  DeleteIncident(
    Map<String, dynamic> data,
  ) : super(Action.update, data: data);
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
  String get aggregateField => "clues";

  @override
  int get entityId => data[entityIdFieldName] as int;

  @override
  String get entityIdFieldName => 'id';
}

class AddClue extends ClueCommand<ClueAdded> {
  AddClue(
    String uuid,
    Map<String, dynamic> data,
  ) : super(Action.create, uuid, data);
}

class UpdateClue extends ClueCommand<ClueUpdated> {
  UpdateClue(
    String uuid,
    Map<String, dynamic> data,
  ) : super(Action.update, uuid, data);
}

class RemoveClue extends ClueCommand<ClueRemoved> {
  RemoveClue(
    String uuid,
    Map<String, dynamic> data,
  ) : super(Action.delete, uuid, data);
}
