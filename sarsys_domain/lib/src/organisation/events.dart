import 'package:event_source/event_source.dart';

//////////////////////////////////////
// Organisation Domain Events
//////////////////////////////////////

class OrganisationCreated extends DomainEvent {
  OrganisationCreated(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$OrganisationCreated',
        );
}

class OrganisationInformationUpdated extends DomainEvent {
  OrganisationInformationUpdated(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$OrganisationInformationUpdated',
        );
}

class DivisionAddedToOrganisation extends DomainEvent {
  DivisionAddedToOrganisation(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$DivisionAddedToOrganisation',
        );
}

class DivisionRemovedFromOrganisation extends DomainEvent {
  DivisionRemovedFromOrganisation(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$DivisionRemovedFromOrganisation',
        );
}

class OrganisationDeleted extends DomainEvent {
  OrganisationDeleted(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$OrganisationDeleted',
        );
}
