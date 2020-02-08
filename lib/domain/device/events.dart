import 'package:meta/meta.dart';
import 'package:sarsys_app_server/eventsource/eventsource.dart';

//////////////////////////////////////
// Device Domain Events
//////////////////////////////////////

class DeviceCreated extends DomainEvent {
  DeviceCreated({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
  }) : super(
          uuid: uuid,
          type: "$DeviceCreated",
          created: created,
          data: data,
        );
}

class DeviceInformationUpdated extends DomainEvent {
  DeviceInformationUpdated({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
  }) : super(
          uuid: uuid,
          type: "$DeviceInformationUpdated",
          created: created,
          data: data,
        );
}

class DeviceDeleted extends DomainEvent {
  DeviceDeleted({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
  }) : super(
          uuid: uuid,
          type: "$DeviceDeleted",
          created: created,
          data: data,
        );
}
