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

class ObjectiveAdded extends DomainEvent {
  ObjectiveAdded(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$ObjectiveAdded',
        );
}

class ObjectiveUpdated extends DomainEvent {
  ObjectiveUpdated(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$ObjectiveUpdated',
        );
}

class ObjectiveRemoved extends DomainEvent {
  ObjectiveRemoved(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$ObjectiveRemoved',
        );
}

//////////////////////////////////////
// TalkGroup Domain Events
//////////////////////////////////////

class TalkGroupAdded extends DomainEvent {
  TalkGroupAdded(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$TalkGroupAdded',
        );
}

class TalkGroupUpdated extends DomainEvent {
  TalkGroupUpdated(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$TalkGroupUpdated',
        );
}

class TalkGroupRemoved extends DomainEvent {
  TalkGroupRemoved(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$TalkGroupRemoved',
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
