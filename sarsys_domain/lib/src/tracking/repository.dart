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
                created: event.created,
              ),
          TrackingInformationUpdated: (event) => TrackingInformationUpdated(
                uuid: event.uuid,
                data: event.data,
                created: event.created,
              ),
          TrackingSourceAdded: (event) => TrackingSourceAdded(
                uuid: event.uuid,
                data: event.data,
                created: event.created,
              ),
          TrackingSourceChanged: (event) => TrackingSourceChanged(
                uuid: event.uuid,
                data: event.data,
                created: event.created,
              ),
          TrackingSourceRemoved: (event) => TrackingSourceRemoved(
                uuid: event.uuid,
                data: event.data,
                created: event.created,
              ),
          TrackingDeleted: (event) => TrackingDeleted(
                uuid: event.uuid,
                data: event.data,
                created: event.created,
              ),
        });

  @override
  Tracking create(Map<String, Process> processors, String uuid, Map<String, dynamic> data) => Tracking(
        uuid,
        processors,
        data: data,
      );
}
