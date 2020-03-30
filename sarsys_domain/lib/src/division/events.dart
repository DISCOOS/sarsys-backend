import 'package:meta/meta.dart';
import 'package:event_source/event_source.dart';

//////////////////////////////////////
// Division Domain Events
//////////////////////////////////////

class DivisionRegistered extends DomainEvent {
  DivisionRegistered({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
    @required bool local,
  }) : super(
          uuid: uuid,
          local: local,
          type: '$DivisionRegistered',
          created: created,
          data: data,
        );
}

class DivisionInformationUpdated extends DomainEvent {
  DivisionInformationUpdated({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
    @required bool local,
  }) : super(
          uuid: uuid,
          local: local,
          type: '$DivisionInformationUpdated',
          created: created,
          data: data,
        );
}

class DepartmentAddedToDivision extends DomainEvent {
  DepartmentAddedToDivision({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
    @required bool local,
  }) : super(
          uuid: uuid,
          local: local,
          type: '$DepartmentAddedToDivision',
          created: created,
          data: data,
        );
}

class DepartmentRemovedFromDivision extends DomainEvent {
  DepartmentRemovedFromDivision({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
    @required bool local,
  }) : super(
          uuid: uuid,
          local: local,
          type: '$DepartmentRemovedFromDivision',
          created: created,
          data: data,
        );
}

class DivisionStarted extends DomainEvent {
  DivisionStarted({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
    @required bool local,
  }) : super(
          uuid: uuid,
          local: local,
          type: '$DivisionStarted',
          created: created,
          data: data,
        );
}

class DivisionCancelled extends DomainEvent {
  DivisionCancelled({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
    @required bool local,
  }) : super(
          uuid: uuid,
          local: local,
          type: '$DivisionCancelled',
          created: created,
          data: data,
        );
}

class DivisionFinished extends DomainEvent {
  DivisionFinished({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
    @required bool local,
  }) : super(
          uuid: uuid,
          local: local,
          type: '$DivisionFinished',
          created: created,
          data: data,
        );
}

class DivisionDeleted extends DomainEvent {
  DivisionDeleted({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
    @required bool local,
  }) : super(
          uuid: uuid,
          local: local,
          type: '$DivisionDeleted',
          created: created,
          data: data,
        );
}
