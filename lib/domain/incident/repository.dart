import 'package:sarsys_app_server/eventsource/eventsource.dart';

import 'aggregate.dart';
import 'commands.dart';
import 'events.dart';

class IncidentRepository extends Repository<IncidentCommand, Incident> {
  IncidentRepository(EventStore store)
      : super(store: store, processors: {
          IncidentRegistered: (event) => IncidentRegistered(
                uuid: event.uuid,
                data: event.data,
                created: event.created,
              ),
          IncidentInformationUpdated: (event) => IncidentInformationUpdated(
                uuid: event.uuid,
                data: event.data,
                created: event.created,
              ),
          IncidentRespondedTo: (event) => IncidentRespondedTo(
                uuid: event.uuid,
                data: event.data,
                created: event.created,
              ),
          IncidentResolved: (event) => IncidentResolved(
                uuid: event.uuid,
                data: event.data,
                created: event.created,
              )
        });

  @override
  Incident create(Map<String, Process> processors, String uuid, Map<String, dynamic> data) => Incident(
        uuid,
        processors,
        data: data,
      );
}
