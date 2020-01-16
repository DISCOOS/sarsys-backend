import 'package:sarsys_app_server/eventsource/eventsource.dart';

import 'events.dart';

abstract class DivisionCommand<T extends DomainEvent> extends Command<T> {
  DivisionCommand(
    Action action, {
    String uuid,
    Map<String, dynamic> data = const {},
  }) : super(action, uuid: uuid, data: data);
}

//////////////////////////////////
// Division aggregate commands
//////////////////////////////////

class CreateDivision extends DivisionCommand<DivisionRegistered> {
  CreateDivision(
    Map<String, dynamic> data,
  ) : super(Action.create, data: data);
}

class UpdateDivisionInformation extends DivisionCommand<DivisionInformationUpdated> {
  UpdateDivisionInformation(
    Map<String, dynamic> data,
  ) : super(Action.update, data: data);
}

class DeleteDivision extends DivisionCommand<DivisionDeleted> {
  DeleteDivision(
    Map<String, dynamic> data,
  ) : super(Action.update, data: data);
}
