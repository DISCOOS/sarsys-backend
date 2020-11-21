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
          TrackingDeleted: (event) => TrackingDeleted(event),
          TrackingSourceAdded: (event) => TrackingSourceAdded(event),
          TrackingSourceChanged: (event) => TrackingSourceChanged(event),
          TrackingSourceRemoved: (event) => TrackingSourceRemoved(event),
          TrackingTrackAdded: (event) => TrackingTrackAdded(event),
          TrackingTrackChanged: (event) => TrackingTrackChanged(event),
          TrackingTrackRemoved: (event) => TrackingTrackRemoved(event),
          TrackingPositionChanged: (event) => TrackingPositionChanged(event),
        });

  AssociationRule newCreateRule(_) => AssociationRule(
        (source, target) => CreateTracking({
          uuidFieldName: target,
        }),
        target: this,
        sourceField: 'tracking/uuid',
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

  AssociationRule newDeleteRule(_) => AssociationRule(
        (source, target) => DeleteTracking({
          uuidFieldName: target,
        }),
        target: this,
        sourceField: 'tracking/uuid',
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
  Tracking create(Map<String, ProcessCallback> processors, String uuid, Map<String, dynamic> data) => Tracking(
        uuid,
        processors,
        data: data,
      );
}
