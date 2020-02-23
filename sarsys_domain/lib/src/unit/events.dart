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
  }) : super(
          uuid: uuid,
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
  }) : super(
          uuid: uuid,
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
  }) : super(
          uuid: uuid,
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
  }) : super(
          uuid: uuid,
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
  }) : super(
          uuid: uuid,
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
  }) : super(
          uuid: uuid,
          type: '$UnitDeleted',
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
  }) : super(
          uuid: uuid,
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
  }) : super(
          uuid: uuid,
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
  }) : super(
          uuid: uuid,
          type: '$UnitMessageRemoved',
          created: created,
          data: data,
        );
}
