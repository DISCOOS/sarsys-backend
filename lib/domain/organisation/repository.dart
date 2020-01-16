import 'package:sarsys_app_server/eventsource/eventsource.dart';

import 'aggregate.dart';
import 'commands.dart';
import 'events.dart';

class OrganisationRepository extends Repository<OrganisationCommand, Organisation> {
  OrganisationRepository(EventStore store)
      : super(store: store, processors: {
          OrganisationCreated: (event) => OrganisationCreated(
                uuid: event.uuid,
                data: event.data,
                created: event.created,
              ),
          OrganisationUpdated: (event) => OrganisationUpdated(
                uuid: event.uuid,
                data: event.data,
                created: event.created,
              ),
          OrganisationDeleted: (event) => OrganisationDeleted(
                uuid: event.uuid,
                data: event.data,
                created: event.created,
              ),
        });

  @override
  Organisation create(Map<String, Process> processors, String uuid, Map<String, dynamic> data) => Organisation(
        uuid,
        processors,
        data: data,
      );
}
