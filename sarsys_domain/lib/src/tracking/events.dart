import 'package:meta/meta.dart';
import 'package:event_source/event_source.dart';
import 'package:collection_x/collection_x.dart';
import 'package:sarsys_domain/sarsys_domain.dart';

//////////////////////////////////////
// Tracking Domain Events
//////////////////////////////////////

class TrackingCreated extends DomainEvent {
  TrackingCreated(Message message)
      : super(
          data: message.data,
          uuid: message.uuid,
          local: message.local,
          // Ensure status is set
          created: message.created, type: '$TrackingCreated',
        );
  // Map<String, dynamic> get position => changed.elementAt('position');
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

  // String get status => changed['status'] as String;
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
  // Map<String, dynamic> get position => changed['position'];
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
  }) : super(
          idFieldName: 'uuid',
          type: message.type,
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          aggregateField: 'sources',
          index: message.elementAt('index'),
        );

  String toSourceUuid(Map<String, dynamic> data) =>
      toEntity(data).elementAt('uuid') ?? toEntity(previous)?.elementAt('uuid');

  String toSourceType(Map<String, dynamic> data) =>
      toEntity(data).elementAt('type') ?? toEntity(previous)?.elementAt('type');
}

class TrackingSourceAdded extends TrackingSourceEvent {
  TrackingSourceAdded(Message message)
      : super(
          message,
          type: '$TrackingSourceAdded',
        );
}

class TrackingSourceChanged extends TrackingSourceEvent {
  TrackingSourceChanged(Message message)
      : super(
          message,
          type: '$TrackingSourceChanged',
        );
}

class TrackingSourceRemoved extends TrackingSourceEvent {
  TrackingSourceRemoved(
    Message message, {
    int index,
  }) : super(
          message,
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
  }) : super(
          type: message.type,
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          aggregateField: 'tracks',
          index: message.elementAt('index'),
        );

  String toStatus(Map<String, dynamic> data) => toEntity(data).elementAt('status');
  Map<String, dynamic> toSource(Map<String, dynamic> data) => toEntity(data).elementAt('source');
  Map<String, dynamic> toPositions(Map<String, dynamic> data) => toEntity(data).elementAt('positions');
}

class TrackingTrackAdded extends TrackingTrackEvent {
  TrackingTrackAdded(
    Message message, {
    int index,
  }) : super(
          message,
          type: '$TrackingTrackAdded',
        );
}

class TrackingTrackChanged extends TrackingTrackEvent {
  TrackingTrackChanged(
    Message message, {
    int index,
  }) : super(
          message,
          type: '$TrackingTrackChanged',
        );
}

class TrackingTrackRemoved extends TrackingTrackEvent {
  TrackingTrackRemoved(
    Message message, {
    int index,
  }) : super(
          message,
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
