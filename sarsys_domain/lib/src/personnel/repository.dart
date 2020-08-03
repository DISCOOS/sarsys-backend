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
