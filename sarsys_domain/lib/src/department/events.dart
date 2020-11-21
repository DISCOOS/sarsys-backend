import 'package:event_source/event_source.dart';

//////////////////////////////////////
// Department Domain Events
//////////////////////////////////////

class DepartmentCreated extends DomainEvent {
  DepartmentCreated(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$DepartmentCreated',
        );
}

class DepartmentInformationUpdated extends DomainEvent {
  DepartmentInformationUpdated(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$DepartmentInformationUpdated',
        );
}

class DepartmentDeleted extends DomainEvent {
  DepartmentDeleted(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$DepartmentDeleted',
        );
}
