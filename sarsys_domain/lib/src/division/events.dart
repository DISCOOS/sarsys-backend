import 'package:event_source/event_source.dart';

//////////////////////////////////////
// Division Domain Events
//////////////////////////////////////

class DivisionRegistered extends DomainEvent {
  DivisionRegistered(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$DivisionRegistered',
        );
}

class DivisionInformationUpdated extends DomainEvent {
  DivisionInformationUpdated(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$DivisionInformationUpdated',
        );
}

class DepartmentAddedToDivision extends DomainEvent {
  DepartmentAddedToDivision(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$DepartmentAddedToDivision',
        );
}

class DepartmentRemovedFromDivision extends DomainEvent {
  DepartmentRemovedFromDivision(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$DepartmentRemovedFromDivision',
        );
}

class DivisionStarted extends DomainEvent {
  DivisionStarted(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$DivisionStarted',
        );
}

class DivisionCancelled extends DomainEvent {
  DivisionCancelled(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$DivisionCancelled',
        );
}

class DivisionFinished extends DomainEvent {
  DivisionFinished(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$DivisionFinished',
        );
}

class DivisionDeleted extends DomainEvent {
  DivisionDeleted(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$DivisionDeleted',
        );
}
