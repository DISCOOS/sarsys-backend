import 'package:sarsys_app_server/eventsource/eventsource.dart';

import 'events.dart';

abstract class PersonnelCommand<T extends DomainEvent> extends Command<T> {
  PersonnelCommand(
    Action action, {
    String uuid,
    Map<String, dynamic> data = const {},
  }) : super(action, uuid: uuid, data: data);
}

//////////////////////////////////
// Personnel aggregate commands
//////////////////////////////////

class CreatePersonnel extends PersonnelCommand<PersonnelCreated> {
  CreatePersonnel(
    Map<String, dynamic> data,
  ) : super(Action.create, data: data);
}

class UpdatePersonnelInformation extends PersonnelCommand<PersonnelInformationUpdated> {
  UpdatePersonnelInformation(
    Map<String, dynamic> data,
  ) : super(Action.update, data: data);
}

class MobilizePersonnel extends PersonnelCommand<PersonnelMobilized> {
  MobilizePersonnel(
    Map<String, dynamic> data,
  ) : super(Action.update, data: data);
}

class RetirePersonnel extends PersonnelCommand<PersonnelRetired> {
  RetirePersonnel(
    Map<String, dynamic> data,
  ) : super(Action.update, data: data);
}

class DeletePersonnel extends PersonnelCommand<PersonnelDeployed> {
  DeletePersonnel(
    Map<String, dynamic> data,
  ) : super(Action.delete, data: data);
}

//////////////////////////////////
// Personnel Message entity commands
//////////////////////////////////

class PersonnelMessageCommand<T extends DomainEvent> extends PersonnelCommand<T> implements EntityCommand<T> {
  PersonnelMessageCommand(
    Action action,
    String uuid,
    Map<String, dynamic> data,
  ) : super(action, uuid: uuid, data: data);

  @override
  String get aggregateField => "messages";

  @override
  int get entityId => data[entityIdFieldName] as int;

  @override
  String get entityIdFieldName => 'id';
}

class AddPersonnelMessage extends PersonnelMessageCommand<PersonnelMessageAdded> {
  AddPersonnelMessage(
    String uuid,
    Map<String, dynamic> data,
  ) : super(Action.create, uuid, data);
}

class UpdatePersonnelMessage extends PersonnelMessageCommand<PersonnelMessageUpdated> {
  UpdatePersonnelMessage(
    String uuid,
    Map<String, dynamic> data,
  ) : super(Action.update, uuid, data);
}

class RemovePersonnelMessage extends PersonnelMessageCommand<PersonnelMessageRemoved> {
  RemovePersonnelMessage(
    String uuid,
    Map<String, dynamic> data,
  ) : super(Action.delete, uuid, data);
}
