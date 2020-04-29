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

  AssociationRule newCreateRule(_) {
    return AssociationRule(
      // Only create if tracking does not exist
      (source, target) => target != null && !exists(target)
          ? CreateTracking(
              {uuidFieldName: target},
            )
          : null,
      target: this,
      sourceField: 'tracking/uuid',
      targetField: uuidFieldName,
      intent: Action.create,
      cardinality: Cardinality.none,
    );
  }

  AssociationRule newDeleteRule(_) {
    return AssociationRule(
      // Only delete if tracking exist
      (source, target) => exists(target)
          ? DeleteTracking(
              {uuidFieldName: target},
            )
          : null,
      target: this,
      sourceField: 'tracking/uuid',
      targetField: uuidFieldName,
      intent: Action.delete,
      cardinality: Cardinality.none,
    );
  }

  @override
  Tracking create(Map<String, Process> processors, String uuid, Map<String, dynamic> data) => Tracking(
        uuid,
        processors,
        data: data,
      );
}
