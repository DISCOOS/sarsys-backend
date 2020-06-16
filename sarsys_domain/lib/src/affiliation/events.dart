import 'package:meta/meta.dart';
import 'package:event_source/event_source.dart';

//////////////////////////////////////
// Affiliation Domain Events
//////////////////////////////////////

class AffiliationCreated extends DomainEvent {
  AffiliationCreated({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
    @required bool local,
  }) : super(
          uuid: uuid,
          local: local,
          type: '$AffiliationCreated',
          created: created,
          data: data,
        );
}

class AffiliationInformationUpdated extends DomainEvent {
  AffiliationInformationUpdated({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
    @required bool local,
  }) : super(
          uuid: uuid,
          local: local,
          type: '$AffiliationInformationUpdated',
          created: created,
          data: data,
        );
}

class DivisionAddedToAffiliation extends DomainEvent {
  DivisionAddedToAffiliation({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
    @required bool local,
  }) : super(
          uuid: uuid,
          local: local,
          type: '$DivisionAddedToAffiliation',
          created: created,
          data: data,
        );
}

class DivisionRemovedFromAffiliation extends DomainEvent {
  DivisionRemovedFromAffiliation({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
    @required bool local,
  }) : super(
          uuid: uuid,
          local: local,
          type: '$DivisionRemovedFromAffiliation',
          created: created,
          data: data,
        );
}

class AffiliationDeleted extends DomainEvent {
  AffiliationDeleted({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
    @required bool local,
  }) : super(
          uuid: uuid,
          local: local,
          type: '$AffiliationDeleted',
          created: created,
          data: data,
        );
}
