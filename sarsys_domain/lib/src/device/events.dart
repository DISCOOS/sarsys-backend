import 'package:meta/meta.dart';
import 'package:event_source/event_source.dart';
import 'package:sarsys_domain/sarsys_domain.dart';

//////////////////////////////////////
// Device Domain Events
//////////////////////////////////////

class DeviceCreated extends DomainEvent {
  DeviceCreated({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
    @required bool local,
  }) : super(
          uuid: uuid,
          local: local,
          type: '$DeviceCreated',
          created: created,
          data: data,
        );
}

class DeviceInformationUpdated extends DomainEvent {
  DeviceInformationUpdated({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
    @required bool local,
  }) : super(
          uuid: uuid,
          local: local,
          type: '$DeviceInformationUpdated',
          created: created,
          data: data,
        );
}

class DeviceDeleted extends DomainEvent {
  DeviceDeleted({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
    @required bool local,
  }) : super(
          uuid: uuid,
          local: local,
          type: '$DeviceDeleted',
          created: created,
          data: data,
        );
}

//////////////////////////////////
// Device Position Domain Events
//////////////////////////////////

class DevicePositionChanged extends PositionEvent {
  DevicePositionChanged({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
    @required bool local,
  }) : super(
          uuid: uuid,
          local: local,
          data: data,
          created: created,
          type: 'DevicePositionChanged',
        );
}

//////////////////////////////////
// Device Message Domain Events
//////////////////////////////////

class DeviceMessageAdded extends DomainEvent {
  DeviceMessageAdded({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
    @required bool local,
  }) : super(
          uuid: uuid,
          local: local,
          type: '$DeviceMessageAdded',
          created: created,
          data: data,
        );
}

class DeviceMessageUpdated extends DomainEvent {
  DeviceMessageUpdated({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
    @required bool local,
  }) : super(
          uuid: uuid,
          local: local,
          type: '$DeviceMessageUpdated',
          created: created,
          data: data,
        );
}

class DeviceMessageRemoved extends DomainEvent {
  DeviceMessageRemoved({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
    @required bool local,
  }) : super(
          uuid: uuid,
          local: local,
          type: '$DeviceMessageRemoved',
          created: created,
          data: data,
        );
}
