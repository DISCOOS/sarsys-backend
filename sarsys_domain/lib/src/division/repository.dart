import 'package:meta/meta.dart';

import 'package:event_source/event_source.dart';
import 'package:sarsys_domain/src/affiliation/repository.dart';
import 'package:sarsys_domain/src/organisation/repository.dart';

import 'aggregate.dart';
import 'commands.dart';
import 'events.dart';

class DivisionRepository extends Repository<DivisionCommand, Division> {
  DivisionRepository(
    EventStore store, {
    @required this.organisations,
    @required this.affiliations,
  }) : super(store: store, processors: {
          DivisionRegistered: (event) => DivisionRegistered(event),
          DivisionInformationUpdated: (event) => DivisionInformationUpdated(event),
          DepartmentAddedToDivision: (event) => DepartmentAddedToDivision(event),
          DepartmentRemovedFromDivision: (event) => DepartmentRemovedFromDivision(event),
          DivisionStarted: (event) => DivisionStarted(event),
          DivisionCancelled: (event) => DivisionCancelled(event),
          DivisionFinished: (event) => DivisionFinished(event),
          DivisionDeleted: (event) => DivisionDeleted(event),
        });

  final OrganisationRepository organisations;
  final AffiliationRepository affiliations;

  @override
  void willStartProcessingEvents() {
    // Remove division from 'divisions' list when deleted
    rule<DivisionDeleted>(organisations.newRemoveDivisionRule);

    // Delete all division-to-affiliation
    // relations if any exist
    rule<DivisionDeleted>(affiliations.newDeleteDivisionRule);

    super.willStartProcessingEvents();
  }

  AggregateRule newRemoveDepartmentRule(_) => AssociationRule(
        (source, target) => RemoveDepartmentFromDivision(
          get(target),
          toAggregateUuid(source),
        ),
        target: this,
        targetField: 'departments',
        intent: Action.delete,
        //
        // Relation: 'departments-to-division'
        //
        // - will remove department
        //   from 'departments' list
        //   when deleted
        //
        cardinality: Cardinality.any,
      );

  @override
  Division create(Map<String, ProcessCallback> processors, String uuid, Map<String, dynamic> data) => Division(
        uuid,
        processors,
        data: data,
      );
}
