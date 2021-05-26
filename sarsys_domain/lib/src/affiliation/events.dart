import 'package:event_source/event_source.dart';

//////////////////////////////////////
// Affiliation Domain Events
//////////////////////////////////////

class AffiliationCreated extends DomainEvent {
  AffiliationCreated(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$AffiliationCreated',
        );
}

class AffiliationInformationUpdated extends DomainEvent {
  AffiliationInformationUpdated(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$AffiliationInformationUpdated',
        );
}

class AffiliationDeleted extends DomainEvent {
  AffiliationDeleted(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$AffiliationDeleted',
        );
}
