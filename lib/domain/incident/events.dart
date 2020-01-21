import 'package:meta/meta.dart';
import 'package:sarsys_app_server/eventsource/eventsource.dart';

//////////////////////////////////////
// Incident Domain Events
//////////////////////////////////////

class IncidentRegistered extends DomainEvent {
  IncidentRegistered({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
  }) : super(
          uuid: uuid,
          type: "$IncidentRegistered",
          created: created,
          data: data,
        );
}

class IncidentInformationUpdated extends DomainEvent {
  IncidentInformationUpdated({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
  }) : super(
          uuid: uuid,
          type: "$IncidentInformationUpdated",
          created: created,
          data: data,
        );
}

class OperationAddedToIncident extends DomainEvent {
  OperationAddedToIncident({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
  }) : super(
          uuid: uuid,
          type: "$OperationAddedToIncident",
          created: created,
          data: data,
        );
}

class OperationRemovedFromIncident extends DomainEvent {
  OperationRemovedFromIncident({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
  }) : super(
          uuid: uuid,
          type: "$OperationRemovedFromIncident",
          created: created,
          data: data,
        );
}

class SubjectAddedToIncident extends DomainEvent {
  SubjectAddedToIncident({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
  }) : super(
          uuid: uuid,
          type: "$SubjectAddedToIncident",
          created: created,
          data: data,
        );
}

class SubjectRemovedFromIncident extends DomainEvent {
  SubjectRemovedFromIncident({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
  }) : super(
          uuid: uuid,
          type: "$SubjectRemovedFromIncident",
          created: created,
          data: data,
        );
}

class IncidentRespondedTo extends DomainEvent {
  IncidentRespondedTo({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
  }) : super(
          uuid: uuid,
          type: "$IncidentRespondedTo",
          created: created,
          data: data,
        );
}

class IncidentCancelled extends DomainEvent {
  IncidentCancelled({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
  }) : super(
          uuid: uuid,
          type: "$IncidentCancelled",
          created: created,
          data: data,
        );
}

class IncidentResolved extends DomainEvent {
  IncidentResolved({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
  }) : super(
          uuid: uuid,
          type: "$IncidentResolved",
          created: created,
          data: data,
        );
}

class IncidentDeleted extends DomainEvent {
  IncidentDeleted({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
  }) : super(
          uuid: uuid,
          type: "$IncidentDeleted",
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
  }) : super(
          uuid: uuid,
          type: "$ClueAdded",
          created: created,
          data: data,
        );
}

class ClueUpdated extends DomainEvent {
  ClueUpdated({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
  }) : super(
          uuid: uuid,
          type: "$ClueUpdated",
          created: created,
          data: data,
        );
}

class ClueRemoved extends DomainEvent {
  ClueRemoved({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
  }) : super(
          uuid: uuid,
          type: "$ClueRemoved",
          created: created,
          data: data,
        );
}
