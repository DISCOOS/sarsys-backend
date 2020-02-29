import 'package:meta/meta.dart';
import 'package:event_source/event_source.dart';

//////////////////////////////////////
// Tracking Domain Events
//////////////////////////////////////

class TrackingCreated extends DomainEvent {
  TrackingCreated({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
  }) : super(
          uuid: uuid,
          type: '$TrackingCreated',
          created: created,
          data: data,
        );
  Map<String, dynamic> get position => changed.elementAt('position');
}

class TrackingInformationUpdated extends DomainEvent {
  TrackingInformationUpdated({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
  }) : super(
          uuid: uuid,
          type: '$TrackingInformationUpdated',
          created: created,
          data: data,
        );
  Map<String, dynamic> get position => changed['position'];
}

class TrackingSourceEvent extends EntityObjectEvent {
  TrackingSourceEvent({
    @required String uuid,
    @required String type,
    @required DateTime created,
    @required Map<String, dynamic> data,
    int index,
  }) : super(
          uuid: uuid,
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

class TrackingSourceAdded extends TrackingSourceEvent {
  TrackingSourceAdded({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
    int index,
  }) : super(
          uuid: uuid,
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
    int index,
  }) : super(
          uuid: uuid,
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
    int index,
  }) : super(
          uuid: uuid,
          type: '$TrackingSourceRemoved',
          created: created,
          data: data,
          index: index,
        );
}

class TrackingDeleted extends DomainEvent {
  TrackingDeleted({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
  }) : super(
          uuid: uuid,
          type: '$TrackingDeleted',
          created: created,
          data: data,
        );
}
