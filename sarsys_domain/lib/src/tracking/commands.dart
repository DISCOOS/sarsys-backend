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

class UpdateTrackingInformation extends TrackingCommand<TrackingInformationUpdated> {
  UpdateTrackingInformation(
    Map<String, dynamic> data,
  ) : super(Action.update, data: data);
}

class UpdateTrackingStatus extends TrackingCommand<TrackingStatusChanged> {
  UpdateTrackingStatus(
    Map<String, dynamic> data,
  ) : super(Action.update, data: data);
}

class DeleteTracking extends TrackingCommand<TrackingDeleted> {
  DeleteTracking(
    Map<String, dynamic> data,
  ) : super(Action.delete, data: data);
}

//////////////////////////////////
// Source entity commands
//////////////////////////////////

class SourceCommand<T extends TrackingSourceEvent> extends TrackingCommand<T> implements EntityCommand<T> {
  SourceCommand(
    Action action,
    String uuid,
    Map<String, dynamic> data,
  ) : super(action, uuid: uuid, data: data);

  @override
  String get aggregateField => 'sources';

  @override
  String get entityId => data[entityIdFieldName] as String;

  @override
  String get entityIdFieldName => 'uuid';
}

class AddSourceToTracking extends SourceCommand<TrackingSourceAdded> {
  AddSourceToTracking(
    String uuid,
    Map<String, dynamic> data,
  ) : super(Action.create, uuid, data);
}

class UpdateTrackingSource extends SourceCommand<TrackingSourceChanged> {
  UpdateTrackingSource(
    String uuid,
    Map<String, dynamic> data,
  ) : super(Action.update, uuid, data);
}

class RemoveSourceFromTracking extends SourceCommand<TrackingSourceRemoved> {
  RemoveSourceFromTracking(
    String uuid,
    Map<String, dynamic> data,
  ) : super(Action.delete, uuid, data);
}

//////////////////////////////////
// Track entity commands
//////////////////////////////////

class TrackCommand<T extends TrackingTrackEvent> extends TrackingCommand<T> implements EntityCommand<T> {
  TrackCommand(
    Action action,
    String uuid,
    Map<String, dynamic> data,
  ) : super(action, uuid: uuid, data: data);

  @override
  String get aggregateField => 'tracks';

  @override
  String get entityId => data[entityIdFieldName] as String;

  @override
  String get entityIdFieldName => 'id';
}

class AddTrackToTracking extends TrackCommand<TrackingTrackAdded> {
  AddTrackToTracking(
    String uuid,
    Map<String, dynamic> data,
  ) : super(Action.create, uuid, data);
}

class UpdateTrackingTrack extends TrackCommand<TrackingTrackChanged> {
  UpdateTrackingTrack(
    String uuid,
    Map<String, dynamic> data,
  ) : super(Action.update, uuid, data);
}

class RemoveTrackFromTracking extends TrackCommand<TrackingTrackRemoved> {
  RemoveTrackFromTracking(
    String uuid,
    Map<String, dynamic> data,
  ) : super(Action.delete, uuid, data);
}

//////////////////////////////////
// Track Position commands
//////////////////////////////////

class UpdateTrackingPosition extends TrackingCommand<TrackingPositionChanged> {
  UpdateTrackingPosition(
    Map<String, dynamic> data,
  ) : super(Action.update, data: data);
}
