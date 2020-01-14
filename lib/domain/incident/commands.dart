import 'package:sarsys_app_server/domain/incident/events.dart';
import 'package:sarsys_app_server/eventsource/eventsource.dart';

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

//////////////////////////////////
// Subject entity commands
//////////////////////////////////

class SubjectCommand<T extends DomainEvent> extends IncidentCommand<T> implements EntityCommand<T> {
  SubjectCommand(
    Action action,
    String uuid,
    Map<String, dynamic> data,
  ) : super(action, uuid: uuid, data: data);

  @override
  String get aggregateField => "subjects";

  @override
  int get entityId => data[entityIdFieldName] as int;

  @override
  String get entityIdFieldName => 'id';
}

class AddSubject extends SubjectCommand<SubjectAdded> {
  AddSubject(
    String uuid,
    Map<String, dynamic> data,
  ) : super(Action.create, uuid, data);
}

class UpdateSubject extends SubjectCommand<SubjectUpdated> {
  UpdateSubject(
    String uuid,
    Map<String, dynamic> data,
  ) : super(Action.update, uuid, data);
}

class RemoveSubject extends SubjectCommand<SubjectRemoved> {
  RemoveSubject(
    String uuid,
    Map<String, dynamic> data,
  ) : super(Action.delete, uuid, data);
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
