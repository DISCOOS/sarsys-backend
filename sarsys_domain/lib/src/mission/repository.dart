import 'package:meta/meta.dart';

import 'package:event_source/event_source.dart';
import 'package:sarsys_domain/src/operation/repository.dart';

import 'aggregate.dart';
import 'commands.dart';
import 'events.dart';

class MissionRepository extends Repository<MissionCommand, Mission> {
  MissionRepository(
    EventStore store, {
    @required this.operations,
  }) : super(store: store, processors: {
          MissionCreated: (event) => MissionCreated(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
          MissionInformationUpdated: (event) => MissionInformationUpdated(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
          MissionPlanned: (event) => MissionPlanned(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
          MissionAssigned: (event) => MissionAssigned(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
          MissionExecuted: (event) => MissionExecuted(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
          MissionPartAdded: (event) => MissionPartAdded(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
          MissionPartUpdated: (event) => MissionPartUpdated(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
          MissionPartRemoved: (event) => MissionPartRemoved(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
          MissionResultAdded: (event) => MissionResultAdded(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
          MissionResultUpdated: (event) => MissionResultUpdated(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
          MissionResultRemoved: (event) => MissionResultRemoved(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
          MissionDeleted: (event) => MissionDeleted(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
          MissionMessageAdded: (event) => MissionMessageAdded(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
          MissionMessageUpdated: (event) => MissionMessageUpdated(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
          MissionMessageRemoved: (event) => MissionMessageRemoved(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
        });

  final OperationRepository operations;

  @override
  void willStartProcessingEvents() {
    // Remove Mission from 'missions' list when deleted
    rule<MissionDeleted>(operations.newRemoveMissionRule);

    super.willStartProcessingEvents();
  }

  @override
  Mission create(Map<String, Process> processors, String uuid, Map<String, dynamic> data) => Mission(
        uuid,
        processors,
        data: data,
      );
}
