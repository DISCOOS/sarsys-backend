import 'package:event_source/event_source.dart';

import 'events.dart';

abstract class PersonCommand<T extends DomainEvent> extends Command<T> {
  PersonCommand(
    Action action, {
    String uuid,
    Map<String, dynamic> data = const {},
  }) : super(action, uuid: uuid, data: data);
}

//////////////////////////////////
// Person aggregate commands
//////////////////////////////////

class CreatePerson extends PersonCommand<PersonCreated> {
  CreatePerson(
    Map<String, dynamic> data,
  ) : super(Action.create, data: data);
}

class UpdatePersonInformation extends PersonCommand<PersonInformationUpdated> {
  UpdatePersonInformation(
    Map<String, dynamic> data,
  ) : super(Action.update, data: data);
}

class DeletePerson extends PersonCommand<PersonDeleted> {
  DeletePerson(
    Map<String, dynamic> data,
  ) : super(Action.delete, data: data);
}
