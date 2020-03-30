import 'package:meta/meta.dart';
import 'package:event_source/event_source.dart';

//////////////////////////////////
// Subject Domain Events
//////////////////////////////////

class SubjectRegistered extends DomainEvent {
  SubjectRegistered({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
    @required bool local,
  }) : super(
          uuid: uuid,
          local: local,
          type: '$SubjectRegistered',
          created: created,
          data: data,
        );
}

class SubjectUpdated extends DomainEvent {
  SubjectUpdated({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
    @required bool local,
  }) : super(
          uuid: uuid,
          local: local,
          type: '$SubjectUpdated',
          created: created,
          data: data,
        );
}

class SubjectDeleted extends DomainEvent {
  SubjectDeleted({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
    @required bool local,
  }) : super(
          uuid: uuid,
          local: local,
          type: '$SubjectDeleted',
          created: created,
          data: data,
        );
}
