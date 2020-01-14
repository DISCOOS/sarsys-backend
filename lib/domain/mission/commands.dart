import 'package:sarsys_app_server/eventsource/eventsource.dart';

import 'events.dart';

abstract class MissionCommand<T extends DomainEvent> extends Command<T> {
  MissionCommand(
    Action action, {
    String uuid,
    Map<String, dynamic> data = const {},
  }) : super(action, uuid: uuid, data: data);
}

//////////////////////////////////
// Mission aggregate commands
//////////////////////////////////

class CreateMission extends MissionCommand<MissionCreated> {
  CreateMission(
    Map<String, dynamic> data,
  ) : super(Action.create, data: data);
}

class UpdateMissionInformation extends MissionCommand<MissionInformationUpdated> {
  UpdateMissionInformation(
    Map<String, dynamic> data,
  ) : super(Action.update, data: data);
}

class DeleteMission extends MissionCommand<MissionAssigned> {
  DeleteMission(
    Map<String, dynamic> data,
  ) : super(Action.update, data: data);
}
