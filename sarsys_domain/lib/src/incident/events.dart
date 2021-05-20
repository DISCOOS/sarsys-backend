import 'package:event_source/event_source.dart';

//////////////////////////////////////
// Incident Domain Events
//////////////////////////////////////

class IncidentRegistered extends DomainEvent {
  IncidentRegistered(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$IncidentRegistered',
        );
}

class IncidentInformationUpdated extends DomainEvent {
  IncidentInformationUpdated(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$IncidentInformationUpdated',
        );
}

class OperationAddedToIncident extends DomainEvent {
  OperationAddedToIncident(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$OperationAddedToIncident',
        );
}

class OperationRemovedFromIncident extends DomainEvent {
  OperationRemovedFromIncident(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$OperationRemovedFromIncident',
        );
}

class SubjectAddedToIncident extends DomainEvent {
  SubjectAddedToIncident(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$SubjectAddedToIncident',
        );
}

class SubjectRemovedFromIncident extends DomainEvent {
  SubjectRemovedFromIncident(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$SubjectRemovedFromIncident',
        );
}

class IncidentRespondedTo extends DomainEvent {
  IncidentRespondedTo(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$IncidentRespondedTo',
        );
}

class IncidentCancelled extends DomainEvent {
  IncidentCancelled(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$IncidentCancelled',
        );
}

class IncidentResolved extends DomainEvent {
  IncidentResolved(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$IncidentResolved',
        );
}

class IncidentDeleted extends DomainEvent {
  IncidentDeleted(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$IncidentDeleted',
        );
}

//////////////////////////////////
// Clue Domain Events
//////////////////////////////////

class IncidentClueAdded extends DomainEvent {
  IncidentClueAdded(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$IncidentClueAdded',
        );
}

class IncidentClueUpdated extends DomainEvent {
  IncidentClueUpdated(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$IncidentClueUpdated',
        );
}

class IncidentClueRemoved extends DomainEvent {
  IncidentClueRemoved(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$IncidentClueRemoved',
        );
}

//////////////////////////////////
// Incident Message Domain Events
//////////////////////////////////

class IncidentMessageAdded extends DomainEvent {
  IncidentMessageAdded(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$IncidentMessageAdded',
        );
}

class IncidentMessageUpdated extends DomainEvent {
  IncidentMessageUpdated(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$IncidentMessageUpdated',
        );
}

class IncidentMessageRemoved extends DomainEvent {
  IncidentMessageRemoved(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$IncidentMessageRemoved',
        );
}
