import 'package:event_source/event_source.dart';

//////////////////////////////////////
// Operation Domain Events
//////////////////////////////////////

class OperationRegistered extends DomainEvent {
  OperationRegistered(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$OperationRegistered',
        );
}

class OperationInformationUpdated extends DomainEvent {
  OperationInformationUpdated(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$OperationInformationUpdated',
        );
}

class OperationStarted extends DomainEvent {
  OperationStarted(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$OperationStarted',
        );
}

class OperationCancelled extends DomainEvent {
  OperationCancelled(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$OperationCancelled',
        );
}

class OperationFinished extends DomainEvent {
  OperationFinished(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$OperationFinished',
        );
}

class OperationDeleted extends DomainEvent {
  OperationDeleted(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$OperationDeleted',
        );
}

//////////////////////////////////////
// Personnel Domain Events
//////////////////////////////////////

class PersonnelAddedToOperation extends DomainEvent {
  PersonnelAddedToOperation(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$PersonnelAddedToOperation',
        );
}

class PersonnelRemovedFromOperation extends DomainEvent {
  PersonnelRemovedFromOperation(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$PersonnelRemovedFromOperation',
        );
}

//////////////////////////////////////
// Mission Domain Events
//////////////////////////////////////

class MissionAddedToOperation extends DomainEvent {
  MissionAddedToOperation(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$MissionAddedToOperation',
        );
}

class MissionRemovedFromOperation extends DomainEvent {
  MissionRemovedFromOperation(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$MissionRemovedFromOperation',
        );
}

//////////////////////////////////////
// Unit Domain Events
//////////////////////////////////////

class UnitAddedToOperation extends DomainEvent {
  UnitAddedToOperation(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$UnitAddedToOperation',
        );
}

class UnitRemovedFromOperation extends DomainEvent {
  UnitRemovedFromOperation(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$UnitRemovedFromOperation',
        );
}

//////////////////////////////////////
// Objective Domain Events
//////////////////////////////////////

class OperationObjectiveAdded extends DomainEvent {
  OperationObjectiveAdded(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$OperationObjectiveAdded',
        );
}

class OperationObjectiveUpdated extends DomainEvent {
  OperationObjectiveUpdated(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$OperationObjectiveUpdated',
        );
}

class OperationObjectiveRemoved extends DomainEvent {
  OperationObjectiveRemoved(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$OperationObjectiveRemoved',
        );
}

//////////////////////////////////////
// TalkGroup Domain Events
//////////////////////////////////////

class OperationTalkGroupAdded extends DomainEvent {
  OperationTalkGroupAdded(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$OperationTalkGroupAdded',
        );
}

class OperationTalkGroupUpdated extends DomainEvent {
  OperationTalkGroupUpdated(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$OperationTalkGroupUpdated',
        );
}

class OperationTalkGroupRemoved extends DomainEvent {
  OperationTalkGroupRemoved(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$OperationTalkGroupRemoved',
        );
}

//////////////////////////////////
// Operation Message Domain Events
//////////////////////////////////

class OperationMessageAdded extends DomainEvent {
  OperationMessageAdded(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$OperationMessageAdded',
        );
}

class OperationMessageUpdated extends DomainEvent {
  OperationMessageUpdated(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$OperationMessageUpdated',
        );
}

class OperationMessageRemoved extends DomainEvent {
  OperationMessageRemoved(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$OperationMessageRemoved',
        );
}
