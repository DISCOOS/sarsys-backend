import 'package:meta/meta.dart';
import 'package:event_source/event_source.dart';

//////////////////////////////////////
// Incident Domain Events
//////////////////////////////////////

class IncidentRegistered extends DomainEvent {
  IncidentRegistered({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
    @required bool local,
  }) : super(
          uuid: uuid,
          local: local,
          type: '$IncidentRegistered',
          created: created,
          data: data,
        );
}

class IncidentInformationUpdated extends DomainEvent {
  IncidentInformationUpdated({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
    @required bool local,
  }) : super(
          uuid: uuid,
          local: local,
          type: '$IncidentInformationUpdated',
          created: created,
          data: data,
        );
}

class OperationAddedToIncident extends DomainEvent {
  OperationAddedToIncident({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
    @required bool local,
  }) : super(
          uuid: uuid,
          local: local,
          type: '$OperationAddedToIncident',
          created: created,
          data: data,
        );
}

class OperationRemovedFromIncident extends DomainEvent {
  OperationRemovedFromIncident({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
    @required bool local,
  }) : super(
          uuid: uuid,
          local: local,
          type: '$OperationRemovedFromIncident',
          created: created,
          data: data,
        );
}

class SubjectAddedToIncident extends DomainEvent {
  SubjectAddedToIncident({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
    @required bool local,
  }) : super(
          uuid: uuid,
          local: local,
          type: '$SubjectAddedToIncident',
          created: created,
          data: data,
        );
}

class SubjectRemovedFromIncident extends DomainEvent {
  SubjectRemovedFromIncident({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
    @required bool local,
  }) : super(
          uuid: uuid,
          local: local,
          type: '$SubjectRemovedFromIncident',
          created: created,
          data: data,
        );
}

class IncidentRespondedTo extends DomainEvent {
  IncidentRespondedTo({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
    @required bool local,
  }) : super(
          uuid: uuid,
          local: local,
          type: '$IncidentRespondedTo',
          created: created,
          data: data,
        );
}

class IncidentCancelled extends DomainEvent {
  IncidentCancelled({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
    @required bool local,
  }) : super(
          uuid: uuid,
          local: local,
          type: '$IncidentCancelled',
          created: created,
          data: data,
        );
}

class IncidentResolved extends DomainEvent {
  IncidentResolved({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
    @required bool local,
  }) : super(
          uuid: uuid,
          local: local,
          type: '$IncidentResolved',
          created: created,
          data: data,
        );
}

class IncidentDeleted extends DomainEvent {
  IncidentDeleted({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
    @required bool local,
  }) : super(
          uuid: uuid,
          local: local,
          type: '$IncidentDeleted',
          created: created,
          data: data,
        );
}

//////////////////////////////////
// Clue Domain Events
//////////////////////////////////

class ClueAdded extends DomainEvent {
  ClueAdded({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
    @required bool local,
  }) : super(
          uuid: uuid,
          local: local,
          type: '$ClueAdded',
          created: created,
          data: data,
        );
}

class ClueUpdated extends DomainEvent {
  ClueUpdated({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
    @required bool local,
  }) : super(
          uuid: uuid,
          local: local,
          type: '$ClueUpdated',
          created: created,
          data: data,
        );
}

class ClueRemoved extends DomainEvent {
  ClueRemoved({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
    @required bool local,
  }) : super(
          uuid: uuid,
          local: local,
          type: '$ClueRemoved',
          created: created,
          data: data,
        );
}

//////////////////////////////////
// Incident Message Domain Events
//////////////////////////////////

class IncidentMessageAdded extends DomainEvent {
  IncidentMessageAdded({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
    @required bool local,
  }) : super(
          uuid: uuid,
          local: local,
          type: '$IncidentMessageAdded',
          created: created,
          data: data,
        );
}

class IncidentMessageUpdated extends DomainEvent {
  IncidentMessageUpdated({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
    @required bool local,
  }) : super(
          uuid: uuid,
          local: local,
          type: '$IncidentMessageUpdated',
          created: created,
          data: data,
        );
}

class IncidentMessageRemoved extends DomainEvent {
  IncidentMessageRemoved({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
    @required bool local,
  }) : super(
          uuid: uuid,
          local: local,
          type: '$IncidentMessageRemoved',
          created: created,
          data: data,
        );
}
