import 'package:sarsys_app_server/eventsource/eventsource.dart';
import 'package:uuid/uuid.dart';

import 'events.dart';

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
