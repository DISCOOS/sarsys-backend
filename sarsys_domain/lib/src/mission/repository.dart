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
          MissionCreated: (event) => MissionCreated(event),
          MissionInformationUpdated: (event) => MissionInformationUpdated(event),
          MissionPlanned: (event) => MissionPlanned(event),
          MissionAssigned: (event) => MissionAssigned(event),
          MissionExecuted: (event) => MissionExecuted(event),
          MissionPartAdded: (event) => MissionPartAdded(event),
          MissionPartUpdated: (event) => MissionPartUpdated(event),
          MissionPartRemoved: (event) => MissionPartRemoved(event),
          MissionResultAdded: (event) => MissionResultAdded(event),
          MissionResultUpdated: (event) => MissionResultUpdated(event),
          MissionResultRemoved: (event) => MissionResultRemoved(event),
          MissionDeleted: (event) => MissionDeleted(event),
          MissionMessageAdded: (event) => MissionMessageAdded(event),
          MissionMessageUpdated: (event) => MissionMessageUpdated(event),
          MissionMessageRemoved: (event) => MissionMessageRemoved(event),
        });

  final OperationRepository operations;

  @override
  void willStartProcessingEvents() {
    // Remove Mission from 'missions' list when deleted
    rule<MissionDeleted>(operations.newRemoveMissionRule);

    super.willStartProcessingEvents();
  }

  @override
  Mission create(Map<String, ProcessCallback> processors, String uuid, Map<String, dynamic> data) => Mission(
        uuid,
        processors,
        data: data,
      );
}
