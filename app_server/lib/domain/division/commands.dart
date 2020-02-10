import 'package:event_source/event_source.dart';

import 'aggregate.dart';
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

class AddDepartmentToDivision extends DivisionCommand<DepartmentAddedToDivision> {
  AddDepartmentToDivision(
    Division division,
    String operationUuid,
  ) : super(
          Action.update,
          uuid: division.uuid,
          data: Command.addToList<String>(division.data, 'departments', operationUuid),
        );
}

class RemoveDepartmentFromDivision extends DivisionCommand<DepartmentRemovedFromDivision> {
  RemoveDepartmentFromDivision(
    Division division,
    String operationUuid,
  ) : super(
          Action.update,
          uuid: division.uuid,
          data: Command.removeFromList<String>(division.data, 'departments', operationUuid),
        );
}

class DeleteDivision extends DivisionCommand<DivisionDeleted> {
  DeleteDivision(
    Map<String, dynamic> data,
  ) : super(Action.delete, data: data);
}
