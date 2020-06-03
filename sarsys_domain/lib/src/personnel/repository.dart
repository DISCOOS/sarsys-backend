import 'package:meta/meta.dart';

import 'package:event_source/event_source.dart';
import 'package:sarsys_domain/src/tracking/tracking.dart';

import 'aggregate.dart';
import 'commands.dart';
import 'events.dart';

class PersonnelRepository extends Repository<PersonnelCommand, Personnel> {
  PersonnelRepository(
    EventStore store, {
    @required this.trackings,
  }) : super(store: store, processors: {
          PersonnelRegistered: (event) => PersonnelRegistered(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
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

  final TrackingRepository trackings;

  @override
  void willStartProcessingEvents() {
    // Co-create Tracking with Personnel
    rule<PersonnelRegistered>(trackings.newCreateRule);

    // Co-delete Tracking with Personnel
    rule<PersonnelDeleted>(trackings.newDeleteRule);

    super.willStartProcessingEvents();
  }

  @override
  Personnel create(Map<String, Process> processors, String uuid, Map<String, dynamic> data) => Personnel(
        uuid,
        processors,
        data: data,
      );
}
