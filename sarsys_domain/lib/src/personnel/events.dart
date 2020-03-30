import 'package:meta/meta.dart';
import 'package:event_source/event_source.dart';

//////////////////////////////////////
// Personnel Domain Events
//////////////////////////////////////

class PersonnelCreated extends DomainEvent {
  PersonnelCreated({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
    @required bool local,
  }) : super(
          uuid: uuid,
          local: local,
          type: '$PersonnelCreated',
          created: created,
          data: data,
        );
}

class PersonnelInformationUpdated extends DomainEvent {
  PersonnelInformationUpdated({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
    @required bool local,
  }) : super(
          uuid: uuid,
          local: local,
          type: '$PersonnelInformationUpdated',
          created: created,
          data: data,
        );
}

class PersonnelMobilized extends DomainEvent {
  PersonnelMobilized({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
    @required bool local,
  }) : super(
          uuid: uuid,
          local: local,
          type: '$PersonnelMobilized',
          created: created,
          data: data,
        );
}

class PersonnelDeployed extends DomainEvent {
  PersonnelDeployed({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
    @required bool local,
  }) : super(
          uuid: uuid,
          local: local,
          type: '$PersonnelDeployed',
          created: created,
          data: data,
        );
}

class PersonnelRetired extends DomainEvent {
  PersonnelRetired({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
    @required bool local,
  }) : super(
          uuid: uuid,
          local: local,
          type: '$PersonnelRetired',
          created: created,
          data: data,
        );
}

class PersonnelDeleted extends DomainEvent {
  PersonnelDeleted({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
    @required bool local,
  }) : super(
          uuid: uuid,
          local: local,
          type: '$PersonnelDeleted',
          created: created,
          data: data,
        );
}

//////////////////////////////////
// Personnel Message Domain Events
//////////////////////////////////

class PersonnelMessageAdded extends DomainEvent {
  PersonnelMessageAdded({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
    @required bool local,
  }) : super(
          uuid: uuid,
          local: local,
          type: '$PersonnelMessageAdded',
          created: created,
          data: data,
        );
}

class PersonnelMessageUpdated extends DomainEvent {
  PersonnelMessageUpdated({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
    @required bool local,
  }) : super(
          uuid: uuid,
          local: local,
          type: '$PersonnelMessageUpdated',
          created: created,
          data: data,
        );
}

class PersonnelMessageRemoved extends DomainEvent {
  PersonnelMessageRemoved({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
    @required bool local,
  }) : super(
          uuid: uuid,
          local: local,
          type: '$PersonnelMessageRemoved',
          created: created,
          data: data,
        );
}
