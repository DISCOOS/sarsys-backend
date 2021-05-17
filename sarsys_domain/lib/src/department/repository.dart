import 'package:meta/meta.dart';

import 'package:event_source/event_source.dart';
import 'package:sarsys_domain/src/affiliation/repository.dart';
import 'package:sarsys_domain/src/division/repository.dart';

import 'aggregate.dart';
import 'commands.dart';
import 'events.dart';

class DepartmentRepository extends Repository<DepartmentCommand, Department> {
  DepartmentRepository(
    EventStore store, {
    @required this.divisions,
    @required this.affiliations,
  }) : super(store: store, processors: {
          DepartmentCreated: (event) => DepartmentCreated(event),
          DepartmentInformationUpdated: (event) => DepartmentInformationUpdated(event),
          DepartmentDeleted: (event) => DepartmentDeleted(event),
        });

  final DivisionRepository divisions;
  final AffiliationRepository affiliations;

  @override
  void willStartProcessingEvents() {
    // Remove department from 'departments' list when deleted
    rule<DepartmentDeleted>(divisions.newRemoveDepartmentRule);

    // Delete all department-to-affiliation
    // relations if any exist
    rule<DepartmentDeleted>(affiliations.newDepartmentDeletedRule);

    super.willStartProcessingEvents();
  }

  @override
  Department create(Map<Type, ProcessCallback> processors, String uuid, Map<String, dynamic> data) => Department(
        uuid,
        processors,
        data: data,
      );
}
