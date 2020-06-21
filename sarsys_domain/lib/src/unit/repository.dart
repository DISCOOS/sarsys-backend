import 'package:meta/meta.dart';

import 'package:event_source/event_source.dart';
import 'package:sarsys_domain/src/operation/repository.dart';
import 'package:sarsys_domain/src/tracking/tracking.dart';

import 'aggregate.dart';
import 'commands.dart';
import 'events.dart';

class UnitRepository extends Repository<UnitCommand, Unit> {
  UnitRepository(
    EventStore store, {
    @required this.trackings,
    @required this.operations,
  }) : super(store: store, processors: {
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

  final TrackingRepository trackings;
  final OperationRepository operations;

  @override
  void willStartProcessingEvents() {
    // Co-create and co-created Tracking with Unit
    rule<UnitCreated>(trackings.newCreateRule);
    rule<UnitDeleted>(trackings.newDeleteRule);

    // Remove Unit from 'units' list in Operation when deleted
    rule<UnitDeleted>(operations.newRemoveUnitRule);

    super.willStartProcessingEvents();
  }

  AggregateRule newRemovePersonnelRule(_) => AssociationRule(
        (source, target) => RemovePersonnelFromUnit(
          get(target),
          toAggregateUuid(source),
        ),
        target: this,
        intent: Action.delete,
        targetField: 'personnels',
        //
        // Relation: 'personnels-to-unit'
        //
        // - will remove personnel
        //   from 'personnels' list
        //   when deleted
        //
        cardinality: Cardinality.any,
      );

  @override
  Unit create(Map<String, Process> processors, String uuid, Map<String, dynamic> data) => Unit(
        uuid,
        processors,
        data: data,
      );
}
