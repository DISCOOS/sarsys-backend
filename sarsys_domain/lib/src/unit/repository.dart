import 'package:meta/meta.dart';

import 'package:event_source/event_source.dart';
import 'package:sarsys_domain/sarsys_domain.dart';
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
          UnitCreated: (event) => UnitCreated(event),
          UnitInformationUpdated: (event) => UnitInformationUpdated(event),
          UnitMobilized: (event) => UnitMobilized(event),
          UnitDeployed: (event) => UnitDeployed(event),
          UnitRetired: (event) => UnitRetired(event),
          UnitDeleted: (event) => UnitDeleted(event),
          PersonnelAddedToUnit: (event) => PersonnelAddedToUnit(event),
          PersonnelRemovedFromUnit: (event) => PersonnelRemovedFromUnit(event),
          UnitMessageAdded: (event) => UnitMessageAdded(event),
          UnitMessageUpdated: (event) => UnitMessageUpdated(event),
          UnitMessageRemoved: (event) => UnitMessageRemoved(event),
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

  AggregateRule newRemovePersonnelRule(Repository repo) => AssociationRule(
        (source, target) => RemovePersonnelFromUnit(
          get(target),
          toAggregateUuid(source),
        ),
        source: repo,
        sourceField: 'uuid',
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
  Unit create(Map<Type, ProcessCallback> processors, String uuid, Map<String, dynamic> data) => Unit(
        uuid,
        processors,
        data: ensure(data),
      );

  static Map<String, dynamic> ensure(Map<String, dynamic> data) {
    const objects = <Map<String, dynamic>>[];
    return Map.from(data)..update('personnels', (prev) => prev ?? objects, ifAbsent: () => objects);
  }
}
