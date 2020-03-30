import 'package:event_source/event_source.dart';
import 'package:sarsys_domain/src/personnel/events.dart';

import 'aggregate.dart';
import 'commands.dart';
import 'events.dart';

class UnitRepository extends Repository<UnitCommand, Unit> {
  UnitRepository(EventStore store)
      : super(store: store, processors: {
          UnitCreated: (event) => UnitCreated(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
          UnitInformationUpdated: (event) => UnitInformationUpdated(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
          UnitMobilized: (event) => UnitMobilized(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
          UnitDeployed: (event) => UnitDeployed(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
          UnitRetired: (event) => UnitRetired(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
          UnitDeleted: (event) => UnitDeleted(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
          PersonnelAddedToUnit: (event) => PersonnelAddedToUnit(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
          PersonnelRemovedFromUnit: (event) => PersonnelRemovedFromUnit(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
          UnitMessageAdded: (event) => UnitMessageAdded(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
          UnitMessageUpdated: (event) => UnitMessageUpdated(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
          UnitMessageRemoved: (event) => UnitMessageRemoved(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
        });

  @override
  void willStartProcessingEvents() {
    // Remove Mission from 'missions' list when deleted
    rule<PersonnelDeleted>((_) => AggregateListRule(
          'personnels',
          (aggregate, event) => RemovePersonnelFromUnit(
            aggregate,
            toAggregateUuid(event),
          ),
          this,
        ));
    super.willStartProcessingEvents();
  }

  @override
  Unit create(Map<String, Process> processors, String uuid, Map<String, dynamic> data) => Unit(
        uuid,
        processors,
        data: data,
      );
}
