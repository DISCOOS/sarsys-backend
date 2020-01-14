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
// Subject Domain Events
//////////////////////////////////

class SubjectCreated extends DomainEvent {
  SubjectCreated({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
  }) : super(
          uuid: uuid,
          type: "$SubjectCreated",
          created: created,
          data: data,
        );
}

class SubjectUpdated extends DomainEvent {
  SubjectUpdated({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
  }) : super(
          uuid: uuid,
          type: "$SubjectUpdated",
          created: created,
          data: data,
        );
}

class SubjectDeleted extends DomainEvent {
  SubjectDeleted({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
  }) : super(
          uuid: uuid,
          type: "$SubjectDeleted",
          created: created,
          data: data,
        );
}

//////////////////////////////////
// Clue Domain Events
//////////////////////////////////

class ClueCreated extends DomainEvent {
  ClueCreated({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
  }) : super(
          uuid: uuid,
          type: "$ClueCreated",
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

class ClueDeleted extends DomainEvent {
  ClueDeleted({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
  }) : super(
          uuid: uuid,
          type: "$ClueDeleted",
          created: created,
          data: data,
        );
}
