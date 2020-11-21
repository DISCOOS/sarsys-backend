import 'package:event_source/event_source.dart';

//////////////////////////////////////
// Unit Domain Events
//////////////////////////////////////

class UnitCreated extends DomainEvent {
  UnitCreated(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$UnitCreated',
        );
}

class UnitInformationUpdated extends DomainEvent {
  UnitInformationUpdated(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$UnitInformationUpdated',
        );
}

class UnitMobilized extends DomainEvent {
  UnitMobilized(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$UnitMobilized',
        );
}

class UnitDeployed extends DomainEvent {
  UnitDeployed(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$UnitDeployed',
        );
}

class UnitRetired extends DomainEvent {
  UnitRetired(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$UnitRetired',
        );
}

class UnitDeleted extends DomainEvent {
  UnitDeleted(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$UnitDeleted',
        );
}

//////////////////////////////////////
// Unit Personnel Domain Events
//////////////////////////////////////

class PersonnelAddedToUnit extends DomainEvent {
  PersonnelAddedToUnit(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$PersonnelAddedToUnit',
        );
}

class PersonnelRemovedFromUnit extends DomainEvent {
  PersonnelRemovedFromUnit(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$PersonnelRemovedFromUnit',
        );
}

//////////////////////////////////
// Unit Message Domain Events
//////////////////////////////////

class UnitMessageAdded extends DomainEvent {
  UnitMessageAdded(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$UnitMessageAdded',
        );
}

class UnitMessageUpdated extends DomainEvent {
  UnitMessageUpdated(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$UnitMessageUpdated',
        );
}

class UnitMessageRemoved extends DomainEvent {
  UnitMessageRemoved(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$UnitMessageRemoved',
        );
}
