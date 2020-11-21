import 'package:event_source/event_source.dart';

//////////////////////////////////////
// Mission Domain Events
//////////////////////////////////////

class MissionCreated extends DomainEvent {
  MissionCreated(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$MissionCreated',
        );
}

class MissionInformationUpdated extends DomainEvent {
  MissionInformationUpdated(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$MissionInformationUpdated',
        );
}

class MissionPlanned extends DomainEvent {
  MissionPlanned(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$MissionPlanned',
        );
}

class MissionAssigned extends DomainEvent {
  MissionAssigned(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$MissionAssigned',
        );
}

class MissionExecuted extends DomainEvent {
  MissionExecuted(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$MissionExecuted',
        );
}

class MissionDeleted extends DomainEvent {
  MissionDeleted(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$MissionDeleted',
        );
}

//////////////////////////////////
// MissionPart Domain Events
//////////////////////////////////

class MissionPartAdded extends DomainEvent {
  MissionPartAdded(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$MissionPartAdded',
        );
}

class MissionPartUpdated extends DomainEvent {
  MissionPartUpdated(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$MissionPartUpdated',
        );
}

class MissionPartRemoved extends DomainEvent {
  MissionPartRemoved(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$MissionPartRemoved',
        );
}

//////////////////////////////////
// MissionResult Domain Events
//////////////////////////////////

class MissionResultAdded extends DomainEvent {
  MissionResultAdded(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$MissionResultAdded',
        );
}

class MissionResultUpdated extends DomainEvent {
  MissionResultUpdated(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$MissionResultUpdated',
        );
}

class MissionResultRemoved extends DomainEvent {
  MissionResultRemoved(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$MissionResultRemoved',
        );
}

//////////////////////////////////
// Mission Message Domain Events
//////////////////////////////////

class MissionMessageAdded extends DomainEvent {
  MissionMessageAdded(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$MissionMessageAdded',
        );
}

class MissionMessageUpdated extends DomainEvent {
  MissionMessageUpdated(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$MissionMessageUpdated',
        );
}

class MissionMessageRemoved extends DomainEvent {
  MissionMessageRemoved(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$MissionMessageRemoved',
        );
}
