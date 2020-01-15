import 'package:sarsys_app_server/eventsource/eventsource.dart';

import 'aggregate.dart';
import 'commands.dart';
import 'events.dart';

class OperationRepository extends Repository<OperationCommand, Operation> {
  OperationRepository(EventStore store)
      : super(store: store, processors: {
          OperationRegistered: (event) => OperationRegistered(
                uuid: event.uuid,
                data: event.data,
                created: event.created,
              ),
          OperationInformationUpdated: (event) => OperationInformationUpdated(
                uuid: event.uuid,
                data: event.data,
                created: event.created,
              ),
          OperationStarted: (event) => OperationStarted(
                uuid: event.uuid,
                data: event.data,
                created: event.created,
              ),
          OperationCancelled: (event) => OperationCancelled(
                uuid: event.uuid,
                data: event.data,
                created: event.created,
              ),
          OperationFinished: (event) => OperationFinished(
                uuid: event.uuid,
                data: event.data,
                created: event.created,
              ),
          OperationDeleted: (event) => OperationDeleted(
                uuid: event.uuid,
                data: event.data,
                created: event.created,
              ),
          ObjectiveAdded: (event) => ObjectiveAdded(
                uuid: event.uuid,
                data: event.data,
                created: event.created,
              ),
          ObjectiveUpdated: (event) => ObjectiveUpdated(
                uuid: event.uuid,
                data: event.data,
                created: event.created,
              ),
          ObjectiveRemoved: (event) => ObjectiveRemoved(
                uuid: event.uuid,
                data: event.data,
                created: event.created,
              ),
          TalkGroupAdded: (event) => TalkGroupAdded(
                uuid: event.uuid,
                data: event.data,
                created: event.created,
              ),
          TalkGroupUpdated: (event) => TalkGroupUpdated(
                uuid: event.uuid,
                data: event.data,
                created: event.created,
              ),
          TalkGroupRemoved: (event) => TalkGroupRemoved(
                uuid: event.uuid,
                data: event.data,
                created: event.created,
              ),
        });

  @override
  Operation create(Map<String, Process> processors, String uuid, Map<String, dynamic> data) => Operation(
        uuid,
        processors,
        data: data,
      );
}
