import 'package:meta/meta.dart';
import 'package:event_source/event_source.dart';

//////////////////////////////////////
// Person Domain Events
//////////////////////////////////////

class PersonCreated extends DomainEvent {
  PersonCreated({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
    @required bool local,
  }) : super(
          uuid: uuid,
          local: local,
          type: '$PersonCreated',
          created: created,
          data: data,
        );
}

class PersonInformationUpdated extends DomainEvent {
  PersonInformationUpdated({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
    @required bool local,
  }) : super(
          uuid: uuid,
          local: local,
          type: '$PersonInformationUpdated',
          created: created,
          data: data,
        );
}

class PersonDeleted extends DomainEvent {
  PersonDeleted({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
    @required bool local,
  }) : super(
          uuid: uuid,
          local: local,
          type: '$PersonDeleted',
          created: created,
          data: data,
        );
}
