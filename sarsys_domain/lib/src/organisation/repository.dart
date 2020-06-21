import 'package:meta/meta.dart';

import 'package:event_source/event_source.dart';
import 'package:sarsys_domain/src/affiliation/repository.dart';

import 'aggregate.dart';
import 'commands.dart';
import 'events.dart';

class OrganisationRepository extends Repository<OrganisationCommand, Organisation> {
  OrganisationRepository(
    EventStore store, {
    @required this.affiliations,
  }) : super(store: store, processors: {
          OrganisationCreated: (event) => OrganisationCreated(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
          OrganisationInformationUpdated: (event) => OrganisationInformationUpdated(
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

  final AffiliationRepository affiliations;

  @override
  void willStartProcessingEvents() {
    // Delete all organisation-to-affiliation
    // relations if any exist
    rule<OrganisationDeleted>(affiliations.newDeleteOrganisationRule);

    super.willStartProcessingEvents();
  }

  AggregateRule newRemoveDivisionRule(_) => AssociationRule(
        (source, target) => RemoveDivisionFromOrganisation(
          get(target),
          toAggregateUuid(source),
        ),
        target: this,
        targetField: 'divisions',
        intent: Action.delete,
        //
        // Relation: 'divisions-to-organisation'
        //
        // - will remove division
        //   from 'divisions' list
        //   when deleted
        //
        cardinality: Cardinality.any,
      );

  @override
  Organisation create(Map<String, Process> processors, String uuid, Map<String, dynamic> data) => Organisation(
        uuid,
        processors,
        data: data,
      );
}
