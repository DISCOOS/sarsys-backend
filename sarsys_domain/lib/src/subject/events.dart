import 'package:event_source/event_source.dart';

//////////////////////////////////
// Subject Domain Events
//////////////////////////////////

class SubjectRegistered extends DomainEvent {
  SubjectRegistered(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$SubjectRegistered',
        );
}

class SubjectUpdated extends DomainEvent {
  SubjectUpdated(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$SubjectUpdated',
        );
}

class SubjectDeleted extends DomainEvent {
  SubjectDeleted(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$SubjectDeleted',
        );
}
