import 'package:sarsys_app_server/eventsource/eventsource.dart';
import 'package:uuid/uuid.dart';

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

class Incident extends AggregateRoot {
  Incident(
    String uuid, {
    Map<String, dynamic> data = const {},
  }) : super(uuid, data);

  @override
  DomainEvent created(
    Map<String, dynamic> data, {
    String type,
    DateTime timestamp,
  }) =>
      IncidentRegistered(
        uuid: Uuid().v4(),
        data: data,
        created: timestamp,
      );

  // TODO: Refactor into Read and Write models? Current mapping Event to Read and Command to Write does not feel right.

  @override
  DomainEvent updated(Map<String, dynamic> data, {String type, bool command, DateTime timestamp}) {
    switch (type) {
      case "UpdateIncident":
      case "IncidentInformationUpdated":
        return IncidentInformationUpdated(
          uuid: Uuid().v4(),
          data: data,
          created: timestamp,
        );
      case "IncidentRespondedTo":
        return IncidentRespondedTo(
          uuid: Uuid().v4(),
          data: data,
          created: timestamp,
        );
      case "IncidentCancelled":
        return IncidentCancelled(
          uuid: Uuid().v4(),
          data: data,
          created: timestamp,
        );
      case "IncidentResolved":
        return IncidentResolved(
          uuid: Uuid().v4(),
          data: data,
          created: timestamp,
        );
    }
    throw UnimplementedError("Update type $type not implemented");
  }
}

//////////////////////////////////////
// Incident Commands
//////////////////////////////////////

abstract class IncidentCommand extends Command {
  IncidentCommand(
    Action action, {
    Map<String, dynamic> data = const {},
  }) : super(action, data: data);
}

class CreateIncident extends IncidentCommand {
  CreateIncident(
    Map<String, dynamic> data,
  ) : super(Action.create, data: data);
}

class UpdateIncident extends IncidentCommand {
  UpdateIncident(
    Map<String, dynamic> data,
  ) : super(Action.update, data: data);
}
