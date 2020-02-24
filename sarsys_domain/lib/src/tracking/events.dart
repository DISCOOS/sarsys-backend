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
}

class TrackingSourceAdded extends DomainEvent {
  TrackingSourceAdded({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
  }) : super(
          uuid: uuid,
          type: '$TrackingSourceAdded',
          created: created,
          data: data,
        );
}

class TrackingSourceChanged extends DomainEvent {
  TrackingSourceChanged({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
  }) : super(
          uuid: uuid,
          type: '$TrackingSourceRemoved',
          created: created,
          data: data,
        );
}

class TrackingSourceRemoved extends DomainEvent {
  TrackingSourceRemoved({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
  }) : super(
          uuid: uuid,
          type: '$TrackingSourceRemoved',
          created: created,
          data: data,
        );
}

class TrackingPositionChanged extends DomainEvent {
  TrackingPositionChanged({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
  }) : super(
          uuid: uuid,
          type: '$TrackingPositionChanged',
          created: created,
          data: data,
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
