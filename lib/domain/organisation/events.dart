import 'package:meta/meta.dart';
import 'package:sarsys_app_server/eventsource/eventsource.dart';

//////////////////////////////////////
// Organisation Domain Events
//////////////////////////////////////

class OrganisationCreated extends DomainEvent {
  OrganisationCreated({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
  }) : super(
          uuid: uuid,
          type: "$OrganisationCreated",
          created: created,
          data: data,
        );
}

class OrganisationUpdated extends DomainEvent {
  OrganisationUpdated({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
  }) : super(
          uuid: uuid,
          type: "$OrganisationUpdated",
          created: created,
          data: data,
        );
}

class OrganisationDeleted extends DomainEvent {
  OrganisationDeleted({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
  }) : super(
          uuid: uuid,
          type: "$OrganisationDeleted",
          created: created,
          data: data,
        );
}
