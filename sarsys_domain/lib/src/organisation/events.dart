import 'package:meta/meta.dart';
import 'package:event_source/event_source.dart';

//////////////////////////////////////
// Organisation Domain Events
//////////////////////////////////////

class OrganisationCreated extends DomainEvent {
  OrganisationCreated({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
    @required bool local,
  }) : super(
          uuid: uuid,
          local: local,
          type: '$OrganisationCreated',
          created: created,
          data: data,
        );
}

class OrganisationInformationUpdated extends DomainEvent {
  OrganisationInformationUpdated({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
    @required bool local,
  }) : super(
          uuid: uuid,
          local: local,
          type: '$OrganisationInformationUpdated',
          created: created,
          data: data,
        );
}

class DivisionAddedToOrganisation extends DomainEvent {
  DivisionAddedToOrganisation({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
    @required bool local,
  }) : super(
          uuid: uuid,
          local: local,
          type: '$DivisionAddedToOrganisation',
          created: created,
          data: data,
        );
}

class DivisionRemovedFromOrganisation extends DomainEvent {
  DivisionRemovedFromOrganisation({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
    @required bool local,
  }) : super(
          uuid: uuid,
          local: local,
          type: '$DivisionRemovedFromOrganisation',
          created: created,
          data: data,
        );
}

class OrganisationDeleted extends DomainEvent {
  OrganisationDeleted({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
    @required bool local,
  }) : super(
          uuid: uuid,
          local: local,
          type: '$OrganisationDeleted',
          created: created,
          data: data,
        );
}
