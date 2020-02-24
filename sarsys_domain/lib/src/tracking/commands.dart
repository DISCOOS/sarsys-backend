import 'package:event_source/event_source.dart';

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

//////////////////////////////////
// Track entity commands
//////////////////////////////////

class TrackCommand<T extends DomainEvent> extends TrackingCommand<T> implements EntityCommand<T> {
  TrackCommand(
    Action action,
    String uuid,
    Map<String, dynamic> data,
  ) : super(action, uuid: uuid, data: data);

  @override
  String get aggregateField => 'sources';

  @override
  String get entityId => data[entityIdFieldName] as String;

  @override
  String get entityIdFieldName => 'id';
}

class AddSourceToTracking extends TrackCommand<TrackingSourceAdded> {
  AddSourceToTracking(
    String uuid,
    Map<String, dynamic> data,
  ) : super(Action.create, uuid, data);
}

class UpdateTrackingSource extends TrackCommand<TrackingSourceChanged> {
  UpdateTrackingSource(
    String uuid,
    Map<String, dynamic> data,
  ) : super(Action.create, uuid, data);
}

class RemoveSourceFromTracking extends TrackCommand<TrackingSourceRemoved> {
  RemoveSourceFromTracking(
    String uuid,
    Map<String, dynamic> data,
  ) : super(Action.delete, uuid, data);
}
