import 'package:event_source/event_source.dart';

import 'events.dart';

abstract class SubjectCommand<T extends DomainEvent> extends Command<T> {
  SubjectCommand(
    Action action, {
    String uuid,
    Map<String, dynamic> data = const {},
  }) : super(action, uuid: uuid, data: data);
}

//////////////////////////////////
// Subject aggregate commands
//////////////////////////////////

class RegisterSubject extends SubjectCommand<SubjectRegistered> {
  RegisterSubject(
    Map<String, dynamic> data,
  ) : super(Action.create, data: data);
}

class UpdateSubject extends SubjectCommand<SubjectUpdated> {
  UpdateSubject(
    Map<String, dynamic> data,
  ) : super(Action.update, data: data);
}

class DeleteSubject extends SubjectCommand<SubjectDeleted> {
  DeleteSubject(
    Map<String, dynamic> data,
  ) : super(Action.delete, data: data);
}
