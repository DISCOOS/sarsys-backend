import 'package:meta/meta.dart';
import 'package:event_source/event_source.dart';

//////////////////////////////////////
// Unit Domain Events
//////////////////////////////////////

class UnitCreated extends DomainEvent {
  UnitCreated({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
    @required bool local,
  }) : super(
          uuid: uuid,
          local: local,
          type: '$UnitCreated',
          created: created,
          data: data,
        );
}

class UnitInformationUpdated extends DomainEvent {
  UnitInformationUpdated({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
    @required bool local,
  }) : super(
          uuid: uuid,
          local: local,
          type: '$UnitInformationUpdated',
          created: created,
          data: data,
        );
}

class UnitMobilized extends DomainEvent {
  UnitMobilized({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
    @required bool local,
  }) : super(
          uuid: uuid,
          local: local,
          type: '$UnitMobilized',
          created: created,
          data: data,
        );
}

class UnitDeployed extends DomainEvent {
  UnitDeployed({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
    @required bool local,
  }) : super(
          uuid: uuid,
          local: local,
          type: '$UnitDeployed',
          created: created,
          data: data,
        );
}

class UnitRetired extends DomainEvent {
  UnitRetired({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
    @required bool local,
  }) : super(
          uuid: uuid,
          local: local,
          type: '$UnitRetired',
          created: created,
          data: data,
        );
}

class UnitDeleted extends DomainEvent {
  UnitDeleted({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
    @required bool local,
  }) : super(
          uuid: uuid,
          local: local,
          type: '$UnitDeleted',
          created: created,
          data: data,
        );
}

//////////////////////////////////////
// Unit Personnel Domain Events
//////////////////////////////////////

class PersonnelAddedToUnit extends DomainEvent {
  PersonnelAddedToUnit({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
    @required bool local,
  }) : super(
          uuid: uuid,
          local: local,
          type: '$PersonnelAddedToUnit',
          created: created,
          data: data,
        );
}

class PersonnelRemovedFromUnit extends DomainEvent {
  PersonnelRemovedFromUnit({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
    @required bool local,
  }) : super(
          uuid: uuid,
          local: local,
          type: '$PersonnelRemovedFromUnit',
          created: created,
          data: data,
        );
}

//////////////////////////////////
// Unit Message Domain Events
//////////////////////////////////

class UnitMessageAdded extends DomainEvent {
  UnitMessageAdded({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
    @required bool local,
  }) : super(
          uuid: uuid,
          local: local,
          type: '$UnitMessageAdded',
          created: created,
          data: data,
        );
}

class UnitMessageUpdated extends DomainEvent {
  UnitMessageUpdated({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
    @required bool local,
  }) : super(
          uuid: uuid,
          local: local,
          type: '$UnitMessageUpdated',
          created: created,
          data: data,
        );
}

class UnitMessageRemoved extends DomainEvent {
  UnitMessageRemoved({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
    @required bool local,
  }) : super(
          uuid: uuid,
          local: local,
          type: '$UnitMessageRemoved',
          created: created,
          data: data,
        );
}
