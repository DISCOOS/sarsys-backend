import 'package:event_source/event_source.dart';

import 'aggregate.dart';
import 'commands.dart';
import 'events.dart';

class TrackingRepository extends Repository<TrackingCommand, Tracking> {
  TrackingRepository(EventStore store)
      : super(store: store, processors: {
          TrackingCreated: (event) => TrackingCreated(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
          TrackingStatusChanged: (event) => TrackingStatusChanged(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
          TrackingInformationUpdated: (event) => TrackingInformationUpdated(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
          TrackingDeleted: (event) => TrackingDeleted(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
          TrackingSourceAdded: (event) => TrackingSourceAdded(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
          TrackingSourceChanged: (event) => TrackingSourceChanged(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
          TrackingSourceRemoved: (event) => TrackingSourceRemoved(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
          TrackingTrackAdded: (event) => TrackingTrackAdded(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
          TrackingTrackChanged: (event) => TrackingTrackChanged(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
          TrackingTrackRemoved: (event) => TrackingTrackRemoved(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
          TrackingPositionChanged: (event) => TrackingPositionChanged(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
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
