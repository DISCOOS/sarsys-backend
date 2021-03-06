import 'package:event_source/event_source.dart';

import 'events.dart';

abstract class DepartmentCommand<T extends DomainEvent> extends Command<T> {
  DepartmentCommand(
    Action action, {
    String uuid,
    Map<String, dynamic> data = const {},
  }) : super(action, uuid: uuid, data: data);
}

//////////////////////////////////
// Department aggregate commands
//////////////////////////////////

class CreateDepartment extends DepartmentCommand<DepartmentCreated> {
  CreateDepartment(
    Map<String, dynamic> data,
  ) : super(Action.create, data: data);
}

class UpdateDepartmentInformation extends DepartmentCommand<DepartmentInformationUpdated> {
  UpdateDepartmentInformation(
    Map<String, dynamic> data,
  ) : super(Action.update, data: data);
}

class DeleteDepartment extends DepartmentCommand<DepartmentDeleted> {
  DeleteDepartment(
    Map<String, dynamic> data,
  ) : super(Action.delete, data: data);
}
