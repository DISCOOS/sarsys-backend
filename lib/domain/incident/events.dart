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
