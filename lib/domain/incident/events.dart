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

class SubjectAdded extends DomainEvent {
  SubjectAdded({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
  }) : super(
          uuid: uuid,
          type: "$SubjectAdded",
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

class SubjectRemoved extends DomainEvent {
  SubjectRemoved({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
  }) : super(
          uuid: uuid,
          type: "$SubjectRemoved",
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
