import 'package:event_source/event_source.dart';
import 'package:collection_x/collection_x.dart';
import 'package:sarsys_domain/sarsys_domain.dart';

import 'aggregate.dart';
import 'commands.dart';
import 'events.dart';

class AffiliationRepository extends Repository<AffiliationCommand, Affiliation> {
  AffiliationRepository(EventStore store)
      : super(store: store, processors: {
          AffiliationCreated: (event) => AffiliationCreated(event),
          AffiliationInformationUpdated: (event) => AffiliationInformationUpdated(event),
          AffiliationDeleted: (event) => AffiliationDeleted(event),
        });

  AggregateRule newOrganisationDeletedRule(Repository repo) => AssociationRule(
        (source, target) => DeleteAffiliation(
          get(target).data,
        ),
        source: repo,
        sourceField: 'uuid',
        target: this,
        targetField: 'org/uuid',
        intent: Action.delete,
        //
        // Relation: 'organisation-to-affiliations'
        //
        // - will remove affiliation
        //   when organisation is deleted
        //
        cardinality: Cardinality.o2m,
      );

  AggregateRule newDeletePersonRule(Repository repo) => AssociationRule(
        (source, target) => DeleteAffiliation(
          get(target).data,
        ),
        source: repo,
        sourceField: 'uuid',
        target: this,
        targetField: 'person/uuid',
        intent: Action.delete,
        //
        // Relation: 'person-to-affiliation'
        //
        // - will remove affiliation
        //   when person is deleted
        //
        cardinality: Cardinality.o2m,
      );

  AggregateRule newDepartmentDeletedRule(Repository repo) => AssociationRule(
        (source, target) => DeleteAffiliation(
          get(target).data,
        ),
        source: repo,
        sourceField: 'uuid',
        target: this,
        targetField: 'dep/uuid',
        intent: Action.delete,
        //
        // Relation: 'department-to-affiliations'
        //
        // - will remove affiliation
        //   when organisation is deleted
        //
        cardinality: Cardinality.o2m,
      );

  AggregateRule newDivisionDeletedRule(Repository repo) => AssociationRule(
        (source, target) => DeleteAffiliation(
          get(target).data,
        ),
        source: repo,
        sourceField: 'uuid',
        target: this,
        targetField: 'div/uuid',
        intent: Action.delete,
        //
        // Relation: 'division-to-affiliations'
        //
        // - will remove affiliation
        //   when organisation is deleted
        //
        cardinality: Cardinality.o2m,
      );

  @override
  Affiliation create(Map<String, ProcessCallback> processors, String uuid, Map<String, dynamic> data) => Affiliation(
        uuid,
        processors,
        data: data,
      );

  Iterable<Affiliation> findPerson(String uuid) {
    return aggregates.where((element) => element.data.elementAt('person/uuid') == uuid);
  }

  Iterable<Affiliation> findOrganisation(String uuid) {
    return aggregates.where((element) => element.data.elementAt('org/uuid') == uuid);
  }

  Iterable<Affiliation> findDivision(String uuid) {
    return aggregates.where((element) => element.data.elementAt('div/uuid') == uuid);
  }

  Iterable<Affiliation> findDepartment(String uuid) {
    return aggregates.where((element) => element.data.elementAt('dep/uuid') == uuid);
  }
}
