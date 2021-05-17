import 'package:event_source/event_source.dart';

import 'aggregate.dart';
import 'commands.dart';
import 'events.dart';

class TrackingRepository extends Repository<TrackingCommand, Tracking> {
  TrackingRepository(EventStore store)
      : super(store: store, processors: {
          TrackingCreated: (event) => TrackingCreated(event),
          TrackingStatusChanged: (event) => TrackingStatusChanged(event),
          TrackingInformationUpdated: (event) => TrackingInformationUpdated(event),
          TrackingPositionChanged: (event) => TrackingPositionChanged(event),
          TrackingDeleted: (event) => TrackingDeleted(event),
          TrackingSourceAdded: (event) => TrackingSourceAdded(event),
          TrackingSourceChanged: (event) => TrackingSourceChanged(event),
          TrackingSourceRemoved: (event) => TrackingSourceRemoved(event),
          TrackingTrackAdded: (event) => TrackingTrackAdded(event),
          TrackingTrackChanged: (event) => TrackingTrackChanged(event),
          TrackingTrackRemoved: (event) => TrackingTrackRemoved(event),
        });

  AssociationRule newCreateRule(Repository repo) => AssociationRule(
        (source, target) => CreateTracking({
          uuidFieldName: target,
        }),
        source: repo,
        sourceField: 'tracking/uuid',
        target: this,
        targetField: uuidFieldName,
        intent: Action.create,
        //
        // Relation: 'aggregate-to-tracking'
        //
        // - will only create tracking
        //   when aggregate is created
        //
        cardinality: Cardinality.o2o,
      );

  AssociationRule newDeleteRule(Repository repo) => AssociationRule(
        (source, target) => DeleteTracking({
          uuidFieldName: target,
        }),
        source: repo,
        sourceField: 'tracking/uuid',
        target: this,
        targetField: uuidFieldName,
        intent: Action.delete,
        //
        // Relation: 'aggregate-to-tracking'
        //
        // - will only delete tracking
        //   when aggregate is deleted
        //
        cardinality: Cardinality.o2o,
      );

  @override
  Tracking create(Map<Type, ProcessCallback> processors, String uuid, Map<String, dynamic> data) => Tracking(
        uuid,
        processors,
        data: ensure(data),
      );

  static Map<String, dynamic> ensure(Map<String, dynamic> data) {
    const objects = <Map<String, dynamic>>[];
    return Map.from(data)
      ..update('tracks', (prev) => prev ?? objects, ifAbsent: () => objects)
      ..update('sources', (prev) => prev ?? objects, ifAbsent: () => objects);
  }
}
