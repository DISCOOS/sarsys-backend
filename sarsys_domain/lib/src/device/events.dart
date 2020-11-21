import 'package:event_source/event_source.dart';
import 'package:sarsys_domain/sarsys_domain.dart';

//////////////////////////////////////
// Device Domain Events
//////////////////////////////////////

class DeviceCreated extends DomainEvent {
  DeviceCreated(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$DeviceCreated',
        );
}

class DeviceInformationUpdated extends DomainEvent {
  DeviceInformationUpdated(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$DeviceInformationUpdated',
        );
}

class DeviceDeleted extends DomainEvent {
  DeviceDeleted(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$DeviceDeleted',
        );
}

//////////////////////////////////
// Device Position Domain Events
//////////////////////////////////

class DevicePositionChanged extends PositionEvent {
  DevicePositionChanged(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: 'DevicePositionChanged',
        );
}

//////////////////////////////////
// Device Message Domain Events
//////////////////////////////////

class DeviceMessageAdded extends DomainEvent {
  DeviceMessageAdded(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$DeviceMessageAdded',
        );
}

class DeviceMessageUpdated extends DomainEvent {
  DeviceMessageUpdated(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$DeviceMessageUpdated',
        );
}

class DeviceMessageRemoved extends DomainEvent {
  DeviceMessageRemoved(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$DeviceMessageRemoved',
        );
}
