import 'package:meta/meta.dart';
import 'package:sarsys_app_server/eventsource/eventsource.dart';

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
          type: "$TrackingCreated",
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
          type: "$TrackingInformationUpdated",
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
          type: "$TrackingDeleted",
          created: created,
          data: data,
        );
}
