import 'package:meta/meta.dart';

import 'package:event_source/event_source.dart';
import 'package:sarsys_domain/sarsys_domain.dart';
import 'package:sarsys_domain/src/tracking/tracking.dart';
import 'package:sarsys_domain/src/unit/repository.dart';

import 'aggregate.dart';
import 'commands.dart';
import 'events.dart';

class PersonnelRepository extends Repository<PersonnelCommand, Personnel> {
  PersonnelRepository(
    EventStore store, {
    @required this.units,
    @required this.trackings,
    @required this.operations,
  }) : super(store: store, processors: {
          PersonnelInformationUpdated: (event) => PersonnelInformationUpdated(event),
          PersonnelMobilized: (event) => PersonnelMobilized(event),
          PersonnelDeployed: (event) => PersonnelDeployed(event),
          PersonnelRetired: (event) => PersonnelRetired(event),
          PersonnelDeleted: (event) => PersonnelDeleted(event),
          PersonnelMessageAdded: (event) => PersonnelMessageAdded(event),
          PersonnelMessageUpdated: (event) => PersonnelMessageUpdated(event),
          PersonnelMessageRemoved: (event) => PersonnelMessageRemoved(event),
        });

  final UnitRepository units;
  final TrackingRepository trackings;
  final OperationRepository operations;

  @override
  void willStartProcessingEvents() {
    // Co-create and co-delete Tracking with Personnel
    rule<PersonnelMobilized>(trackings.newCreateRule);
    rule<PersonnelDeleted>(trackings.newDeleteRule);

    // Remove Personnel from 'personnels' lists when deleted
    rule<PersonnelDeleted>(units.newRemovePersonnelRule);
    rule<PersonnelDeleted>(operations.newRemovePersonnelRule);

    super.willStartProcessingEvents();
  }

  @override
  Personnel create(Map<String, ProcessCallback> processors, String uuid, Map<String, dynamic> data) => Personnel(
        uuid,
        processors,
        data: data,
      );
}
