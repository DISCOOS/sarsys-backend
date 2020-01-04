import 'package:sarsys_app_server/eventsource/eventsource.dart';

import 'aggregate.dart';
import 'commands.dart';
import 'events.dart';

class IncidentRepository extends Repository<IncidentCommand, Incident> {
  IncidentRepository(EventStore store) : super(store: store);

  @override
  DomainEvent toDomainEvent(Event event) {
    switch (event.type) {
      case "IncidentRegistered":
        return IncidentRegistered(
          uuid: event.uuid,
          data: event.data,
          created: event.created,
        );
      case 'IncidentInformationUpdated':
        return IncidentInformationUpdated(
          uuid: event.uuid,
          data: event.data,
          created: event.created,
        );
      case 'IncidentRespondedTo':
        return IncidentRespondedTo(
          uuid: event.uuid,
          data: event.data,
          created: event.created,
        );
      case 'IncidentResolved':
        return IncidentResolved(
          uuid: event.uuid,
          data: event.data,
          created: event.created,
        );
    }
    throw InvalidOperation("Event type ${event.type} not recognized");
  }

  @override
  Incident create(String uuid, Map<String, dynamic> data) => Incident(uuid, data: data);
}
