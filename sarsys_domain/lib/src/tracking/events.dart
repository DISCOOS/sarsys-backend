import 'package:meta/meta.dart';
import 'package:event_source/event_source.dart';
import 'package:sarsys_domain/sarsys_domain.dart';

//////////////////////////////////////
// Tracking Domain Events
//////////////////////////////////////

class TrackingCreated extends DomainEvent {
  TrackingCreated(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          // Ensure status is set
          data: {'status': 'ready'}..addAll(message.data),
          created: message.created, type: '$TrackingCreated',
        );
  Map<String, dynamic> get position => changed.elementAt('position');
}

class TrackingStatusChanged extends DomainEvent {
  TrackingStatusChanged(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$TrackingStatusChanged',
        );

  String get status => changed['status'] as String;
}

class TrackingInformationUpdated extends DomainEvent {
  TrackingInformationUpdated(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$TrackingInformationUpdated',
        );
  Map<String, dynamic> get position => changed['position'];
}

class TrackingDeleted extends DomainEvent {
  TrackingDeleted(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$TrackingDeleted',
        );
}

//////////////////////////////////////
// Tracking Source Domain Events
//////////////////////////////////////

class TrackingSourceEvent extends EntityObjectEvent {
  TrackingSourceEvent(
    Message message, {
    @required String type,
    int index,
  }) : super(
          index: index,
          idFieldName: 'uuid',
          type: message.type,
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          aggregateField: 'sources',
        );

  String get sourceUuid => entity.elementAt('uuid');
  String get sourceType => entity.elementAt('type');
}

class TrackingSourceAdded extends TrackingSourceEvent {
  TrackingSourceAdded(
    Message message, {
    int index,
  }) : super(
          message,
          index: index,
          type: '$TrackingSourceAdded',
        );
}

class TrackingSourceChanged extends TrackingSourceEvent {
  TrackingSourceChanged(
    Message message, {
    int index,
  }) : super(
          message,
          index: index,
          type: '$TrackingSourceChanged',
        );
}

class TrackingSourceRemoved extends TrackingSourceEvent {
  TrackingSourceRemoved(
    Message message, {
    int index,
  }) : super(
          message,
          index: index,
          type: '$TrackingSourceRemoved',
        );
}

//////////////////////////////////////
// Tracking Track Domain Events
//////////////////////////////////////

class TrackingTrackEvent extends EntityObjectEvent {
  TrackingTrackEvent(
    Message message, {
    String type,
    int index,
  }) : super(
          index: index,
          type: message.type,
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          aggregateField: 'tracks',
        );

  String get status => entity.elementAt('status');
  Map<String, dynamic> get source => entity.elementAt('source');
  Map<String, dynamic> get positions => entity.elementAt('positions');
}

class TrackingTrackAdded extends TrackingTrackEvent {
  TrackingTrackAdded(
    Message message, {
    int index,
  }) : super(
          message,
          index: index,
          type: '$TrackingTrackAdded',
        );
}

class TrackingTrackChanged extends TrackingTrackEvent {
  TrackingTrackChanged(
    Message message, {
    int index,
  }) : super(
          message,
          index: index,
          type: '$TrackingTrackChanged',
        );
}

class TrackingTrackRemoved extends TrackingTrackEvent {
  TrackingTrackRemoved(
    Message message, {
    int index,
  }) : super(
          message,
          index: index,
          type: '$TrackingTrackRemoved',
        );
}

//////////////////////////////////
// Tracking Position Domain Events
//////////////////////////////////

class TrackingPositionChanged extends PositionEvent {
  TrackingPositionChanged(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$TrackingPositionChanged',
        );
}
