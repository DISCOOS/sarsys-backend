import 'package:sarsys_app_server/eventsource/eventsource.dart';

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
