import 'package:meta/meta.dart';
import 'package:sarsys_app_server/eventsource/eventsource.dart';

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
