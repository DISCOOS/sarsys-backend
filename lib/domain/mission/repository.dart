import 'package:sarsys_app_server/eventsource/eventsource.dart';

import 'aggregate.dart';
import 'commands.dart';
import 'events.dart';

class MissionRepository extends Repository<MissionCommand, Mission> {
  MissionRepository(EventStore store)
      : super(store: store, processors: {
          MissionCreated: (event) => MissionCreated(
                uuid: event.uuid,
                data: event.data,
                created: event.created,
              ),
          MissionInformationUpdated: (event) => MissionInformationUpdated(
                uuid: event.uuid,
                data: event.data,
                created: event.created,
              ),
          MissionPlanned: (event) => MissionPlanned(
                uuid: event.uuid,
                data: event.data,
                created: event.created,
              ),
          MissionAssigned: (event) => MissionAssigned(
                uuid: event.uuid,
                data: event.data,
                created: event.created,
              ),
          MissionExecuted: (event) => MissionExecuted(
                uuid: event.uuid,
                data: event.data,
                created: event.created,
              ),
          MissionPartAdded: (event) => MissionPartAdded(
                uuid: event.uuid,
                data: event.data,
                created: event.created,
              ),
          MissionPartUpdated: (event) => MissionPartUpdated(
                uuid: event.uuid,
                data: event.data,
                created: event.created,
              ),
          MissionPartRemoved: (event) => MissionPartRemoved(
                uuid: event.uuid,
                data: event.data,
                created: event.created,
              ),
          MissionResultAdded: (event) => MissionResultAdded(
                uuid: event.uuid,
                data: event.data,
                created: event.created,
              ),
          MissionResultUpdated: (event) => MissionResultUpdated(
                uuid: event.uuid,
                data: event.data,
                created: event.created,
              ),
          MissionResultRemoved: (event) => MissionResultRemoved(
                uuid: event.uuid,
                data: event.data,
                created: event.created,
              ),
          MissionDeleted: (event) => MissionDeleted(
                uuid: event.uuid,
                data: event.data,
                created: event.created,
              ),
        });

  @override
  Mission create(Map<String, Process> processors, String uuid, Map<String, dynamic> data) => Mission(
        uuid,
        processors,
        data: data,
      );
}
