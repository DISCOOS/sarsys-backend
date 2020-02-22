import 'package:meta/meta.dart';
import 'package:event_source/event_source.dart';

//////////////////////////////////////
// Mission Domain Events
//////////////////////////////////////

class MissionCreated extends DomainEvent {
  MissionCreated({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
  }) : super(
          uuid: uuid,
          type: "$MissionCreated",
          created: created,
          data: data,
        );
}

class MissionInformationUpdated extends DomainEvent {
  MissionInformationUpdated({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
  }) : super(
          uuid: uuid,
          type: "$MissionInformationUpdated",
          created: created,
          data: data,
        );
}

class MissionPlanned extends DomainEvent {
  MissionPlanned({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
  }) : super(
          uuid: uuid,
          type: "$MissionPlanned",
          created: created,
          data: data,
        );
}

class MissionAssigned extends DomainEvent {
  MissionAssigned({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
  }) : super(
          uuid: uuid,
          type: "$MissionAssigned",
          created: created,
          data: data,
        );
}

class MissionExecuted extends DomainEvent {
  MissionExecuted({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
  }) : super(
          uuid: uuid,
          type: "$MissionExecuted",
          created: created,
          data: data,
        );
}

class MissionDeleted extends DomainEvent {
  MissionDeleted({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
  }) : super(
          uuid: uuid,
          type: "$MissionDeleted",
          created: created,
          data: data,
        );
}

//////////////////////////////////
// MissionPart Domain Events
//////////////////////////////////

class MissionPartAdded extends DomainEvent {
  MissionPartAdded({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
  }) : super(
          uuid: uuid,
          type: "$MissionPartAdded",
          created: created,
          data: data,
        );
}

class MissionPartUpdated extends DomainEvent {
  MissionPartUpdated({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
  }) : super(
          uuid: uuid,
          type: "$MissionPartUpdated",
          created: created,
          data: data,
        );
}

class MissionPartRemoved extends DomainEvent {
  MissionPartRemoved({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
  }) : super(
          uuid: uuid,
          type: "$MissionPartRemoved",
          created: created,
          data: data,
        );
}

//////////////////////////////////
// MissionResult Domain Events
//////////////////////////////////

class MissionResultAdded extends DomainEvent {
  MissionResultAdded({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
  }) : super(
          uuid: uuid,
          type: "$MissionResultAdded",
          created: created,
          data: data,
        );
}

class MissionResultUpdated extends DomainEvent {
  MissionResultUpdated({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
  }) : super(
          uuid: uuid,
          type: "$MissionResultUpdated",
          created: created,
          data: data,
        );
}

class MissionResultRemoved extends DomainEvent {
  MissionResultRemoved({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
  }) : super(
          uuid: uuid,
          type: "$MissionResultRemoved",
          created: created,
          data: data,
        );
}

//////////////////////////////////
// Mission Message Domain Events
//////////////////////////////////

class MissionMessageAdded extends DomainEvent {
  MissionMessageAdded({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
  }) : super(
          uuid: uuid,
          type: "$MissionMessageAdded",
          created: created,
          data: data,
        );
}

class MissionMessageUpdated extends DomainEvent {
  MissionMessageUpdated({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
  }) : super(
          uuid: uuid,
          type: "$MissionMessageUpdated",
          created: created,
          data: data,
        );
}

class MissionMessageRemoved extends DomainEvent {
  MissionMessageRemoved({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
  }) : super(
          uuid: uuid,
          type: "$MissionMessageRemoved",
          created: created,
          data: data,
        );
}
