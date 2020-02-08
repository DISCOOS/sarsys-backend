import 'package:sarsys_app_server/eventsource/eventsource.dart';

import 'events.dart';

abstract class TrackingCommand<T extends DomainEvent> extends Command<T> {
  TrackingCommand(
    Action action, {
    String uuid,
    Map<String, dynamic> data = const {},
  }) : super(action, uuid: uuid, data: data);
}

//////////////////////////////////
// Tracking aggregate commands
//////////////////////////////////

class CreateTracking extends TrackingCommand<TrackingCreated> {
  CreateTracking(
    Map<String, dynamic> data,
  ) : super(Action.create, data: data);
}

class UpdateTracking extends TrackingCommand<TrackingInformationUpdated> {
  UpdateTracking(
    Map<String, dynamic> data,
  ) : super(Action.update, data: data);
}

class DeleteTracking extends TrackingCommand<TrackingDeleted> {
  DeleteTracking(
    Map<String, dynamic> data,
  ) : super(Action.delete, data: data);
}
