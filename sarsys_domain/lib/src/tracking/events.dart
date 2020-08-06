import 'package:meta/meta.dart';
import 'package:event_source/event_source.dart';
import 'package:sarsys_domain/sarsys_domain.dart';

//////////////////////////////////////
// Tracking Domain Events
//////////////////////////////////////

class TrackingCreated extends DomainEvent {
  TrackingCreated({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
    @required bool local,
  }) : super(
          uuid: uuid,
          local: local,
          type: '$TrackingCreated',
          created: created,
          // Ensure status is set
          data: {'status': 'ready'}..addAll(data),
        );
  Map<String, dynamic> get position => changed.elementAt('position');
}

class TrackingStatusChanged extends DomainEvent {
  TrackingStatusChanged({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
    @required bool local,
  }) : super(
          uuid: uuid,
          local: local,
          type: '$TrackingStatusChanged',
          created: created,
          data: data,
        );

  String get status => changed['status'] as String;
}

class TrackingInformationUpdated extends DomainEvent {
  TrackingInformationUpdated({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
    @required bool local,
  }) : super(
          uuid: uuid,
          local: local,
          type: '$TrackingInformationUpdated',
          created: created,
          data: data,
        );
  Map<String, dynamic> get position => changed['position'];
}

class TrackingDeleted extends DomainEvent {
  TrackingDeleted({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
    @required bool local,
  }) : super(
          uuid: uuid,
          local: local,
          type: '$TrackingDeleted',
          created: created,
          data: data,
        );
}

//////////////////////////////////////
// Tracking Source Domain Events
//////////////////////////////////////

class TrackingSourceEvent extends EntityObjectEvent {
  TrackingSourceEvent({
    @required String uuid,
    @required String type,
    @required DateTime created,
    @required Map<String, dynamic> data,
    @required bool local,
    int index,
  }) : super(
          uuid: uuid,
          type: type,
          index: index,
          local: local,
          created: created,
          idFieldName: 'uuid',
          aggregateField: 'sources',
          data: data,
        );

  String get sourceUuid => entity.elementAt('uuid');
  String get sourceType => entity.elementAt('type');
}

class TrackingSourceAdded extends TrackingSourceEvent {
  TrackingSourceAdded({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
    @required bool local,
    int index,
  }) : super(
          uuid: uuid,
          local: local,
          type: '$TrackingSourceAdded',
          created: created,
          data: data,
          index: index,
        );
}

class TrackingSourceChanged extends TrackingSourceEvent {
  TrackingSourceChanged({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
    @required bool local,
    int index,
  }) : super(
          uuid: uuid,
          local: local,
          type: '$TrackingSourceChanged',
          created: created,
          data: data,
          index: index,
        );
}

class TrackingSourceRemoved extends TrackingSourceEvent {
  TrackingSourceRemoved({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
    @required bool local,
    int index,
  }) : super(
          uuid: uuid,
          local: local,
          type: '$TrackingSourceRemoved',
          created: created,
          data: data,
          index: index,
        );
}

//////////////////////////////////////
// Tracking Track Domain Events
//////////////////////////////////////

class TrackingTrackEvent extends EntityObjectEvent {
  TrackingTrackEvent({
    @required String uuid,
    @required String type,
    @required DateTime created,
    @required Map<String, dynamic> data,
    @required bool local,
    int index,
  }) : super(
          uuid: uuid,
          local: local,
          type: type,
          index: index,
          created: created,
          aggregateField: 'tracks',
          data: data,
        );

  String get status => entity.elementAt('status');
  Map<String, dynamic> get source => entity.elementAt('source');
  Map<String, dynamic> get positions => entity.elementAt('positions');
}

class TrackingTrackAdded extends TrackingTrackEvent {
  TrackingTrackAdded({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
    @required bool local,
    int index,
  }) : super(
          uuid: uuid,
          local: local,
          type: '$TrackingTrackAdded',
          created: created,
          data: data,
          index: index,
        );
}

class TrackingTrackChanged extends TrackingTrackEvent {
  TrackingTrackChanged({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
    @required bool local,
    int index,
  }) : super(
          uuid: uuid,
          local: local,
          type: '$TrackingTrackChanged',
          created: created,
          data: data,
          index: index,
        );
}

class TrackingTrackRemoved extends TrackingTrackEvent {
  TrackingTrackRemoved({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
    @required bool local,
    int index,
  }) : super(
          uuid: uuid,
          local: local,
          type: '$TrackingTrackRemoved',
          created: created,
          data: data,
          index: index,
        );
}

//////////////////////////////////
// Tracking Position Domain Events
//////////////////////////////////

class TrackingPositionChanged extends PositionEvent {
  TrackingPositionChanged({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
    @required bool local,
  }) : super(
          uuid: uuid,
          local: local,
          data: data,
          created: created,
          type: 'TrackingPositionChanged',
        );
}
