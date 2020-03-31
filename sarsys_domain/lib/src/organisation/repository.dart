import 'package:event_source/event_source.dart';
import 'package:sarsys_domain/src/division/events.dart';

import 'aggregate.dart';
import 'commands.dart';
import 'events.dart';

class OrganisationRepository extends Repository<OrganisationCommand, Organisation> {
  OrganisationRepository(EventStore store)
      : super(store: store, processors: {
          OrganisationCreated: (event) => OrganisationCreated(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
          OrganisationInfomationUpdated: (event) => OrganisationInfomationUpdated(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
          DivisionAddedToOrganisation: (event) => DivisionAddedToOrganisation(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
          DivisionRemovedFromOrganisation: (event) => DivisionRemovedFromOrganisation(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
          OrganisationDeleted: (event) => OrganisationDeleted(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
        });

  @override
  void willStartProcessingEvents() {
    // Remove Division from 'divisions' list when deleted
    rule<DivisionDeleted>((_) => AssociationRule(
          (source, target) => RemoveDivisionFromOrganisation(
            get(target),
            toAggregateUuid(source),
          ),
          target: this,
          targetField: 'divisions',
          intent: Action.delete,
        ));

    super.willStartProcessingEvents();
  }

  @override
  Organisation create(Map<String, Process> processors, String uuid, Map<String, dynamic> data) => Organisation(
        uuid,
        processors,
        data: data,
      );
}
