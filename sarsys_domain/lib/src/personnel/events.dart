import 'package:event_source/event_source.dart';

//////////////////////////////////////
// Personnel Domain Events
//////////////////////////////////////

class PersonnelMobilized extends DomainEvent {
  PersonnelMobilized(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$PersonnelMobilized',
        );
}

class PersonnelInformationUpdated extends DomainEvent {
  PersonnelInformationUpdated(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$PersonnelInformationUpdated',
        );
}

class PersonnelDeployed extends DomainEvent {
  PersonnelDeployed(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$PersonnelDeployed',
        );
}

class PersonnelRetired extends DomainEvent {
  PersonnelRetired(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$PersonnelRetired',
        );
}

class PersonnelDeleted extends DomainEvent {
  PersonnelDeleted(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$PersonnelDeleted',
        );
}

//////////////////////////////////
// Personnel Message Domain Events
//////////////////////////////////

class PersonnelMessageAdded extends DomainEvent {
  PersonnelMessageAdded(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$PersonnelMessageAdded',
        );
}

class PersonnelMessageUpdated extends DomainEvent {
  PersonnelMessageUpdated(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$PersonnelMessageUpdated',
        );
}

class PersonnelMessageRemoved extends DomainEvent {
  PersonnelMessageRemoved(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$PersonnelMessageRemoved',
        );
}
