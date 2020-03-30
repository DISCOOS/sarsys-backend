import 'package:event_source/event_source.dart';

import 'aggregate.dart';
import 'commands.dart';
import 'events.dart';

class PersonnelRepository extends Repository<PersonnelCommand, Personnel> {
  PersonnelRepository(EventStore store)
      : super(store: store, processors: {
          PersonnelCreated: (event) => PersonnelCreated(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
          PersonnelInformationUpdated: (event) => PersonnelInformationUpdated(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
          PersonnelMobilized: (event) => PersonnelMobilized(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
          PersonnelDeployed: (event) => PersonnelDeployed(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
          PersonnelRetired: (event) => PersonnelRetired(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
          PersonnelDeleted: (event) => PersonnelDeleted(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
          PersonnelMessageAdded: (event) => PersonnelMessageAdded(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
          PersonnelMessageUpdated: (event) => PersonnelMessageUpdated(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
          PersonnelMessageRemoved: (event) => PersonnelMessageRemoved(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
        });

  @override
  Personnel create(Map<String, Process> processors, String uuid, Map<String, dynamic> data) => Personnel(
        uuid,
        processors,
        data: data,
      );
}
