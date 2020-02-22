import 'package:event_source/event_source.dart';

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
          OrganisationInfomationUpdated: (event) => OrganisationInfomationUpdated(
                uuid: event.uuid,
                data: event.data,
                created: event.created,
              ),
          DivisionAddedToOrganisation: (event) => DivisionAddedToOrganisation(
                uuid: event.uuid,
                data: event.data,
                created: event.created,
              ),
          DivisionRemovedFromOrganisation: (event) => DivisionRemovedFromOrganisation(
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
