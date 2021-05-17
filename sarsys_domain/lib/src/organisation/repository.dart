import 'package:meta/meta.dart';

import 'package:event_source/event_source.dart';
import 'package:sarsys_domain/sarsys_domain.dart';
import 'package:sarsys_domain/src/affiliation/repository.dart';

import 'aggregate.dart';
import 'commands.dart';
import 'events.dart';

class OrganisationRepository extends Repository<OrganisationCommand, Organisation> {
  OrganisationRepository(
    EventStore store, {
    @required this.affiliations,
  }) : super(store: store, processors: {
          OrganisationCreated: (event) => OrganisationCreated(event),
          OrganisationInformationUpdated: (event) => OrganisationInformationUpdated(event),
          DivisionAddedToOrganisation: (event) => DivisionAddedToOrganisation(event),
          DivisionRemovedFromOrganisation: (event) => DivisionRemovedFromOrganisation(event),
          OrganisationDeleted: (event) => OrganisationDeleted(event),
        });

  final AffiliationRepository affiliations;

  @override
  void willStartProcessingEvents() {
    // Delete all organisation-to-affiliation
    // relations if any exist
    rule<OrganisationDeleted>(affiliations.newOrganisationDeletedRule);

    super.willStartProcessingEvents();
  }

  AggregateRule newRemoveDivisionRule(Repository repo) => AssociationRule(
        (source, target) => RemoveDivisionFromOrganisation(
          get(target),
          toAggregateUuid(source),
        ),
        source: repo,
        sourceField: 'uuid',
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
  Organisation create(Map<Type, ProcessCallback> processors, String uuid, Map<String, dynamic> data) => Organisation(
        uuid,
        processors,
        data: ensure(data),
      );

  static Map<String, dynamic> ensure(Map<String, dynamic> data) {
    const objects = <Map<String, dynamic>>[];
    return Map.from(data)
      ..update('divisions', (prev) => prev ?? objects, ifAbsent: () => objects)
      ..update('departments', (prev) => prev ?? objects, ifAbsent: () => objects);
  }
}
