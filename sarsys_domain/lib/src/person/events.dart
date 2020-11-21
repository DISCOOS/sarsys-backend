import 'package:event_source/event_source.dart';

//////////////////////////////////////
// Person Domain Events
//////////////////////////////////////

class PersonCreated extends DomainEvent {
  PersonCreated(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$PersonCreated',
        );
}

class PersonInformationUpdated extends DomainEvent {
  PersonInformationUpdated(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$PersonInformationUpdated',
        );
}

class PersonDeleted extends DomainEvent {
  PersonDeleted(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$PersonDeleted',
        );
}
