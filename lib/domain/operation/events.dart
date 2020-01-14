import 'package:meta/meta.dart';
import 'package:sarsys_app_server/eventsource/eventsource.dart';

//////////////////////////////////////
// Operation Domain Events
//////////////////////////////////////

class OperationRegistered extends DomainEvent {
  OperationRegistered({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
  }) : super(
          uuid: uuid,
          type: "$OperationRegistered",
          created: created,
          data: data,
        );
}

class OperationInformationUpdated extends DomainEvent {
  OperationInformationUpdated({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
  }) : super(
          uuid: uuid,
          type: "$OperationInformationUpdated",
          created: created,
          data: data,
        );
}

class OperationStarted extends DomainEvent {
  OperationStarted({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
  }) : super(
          uuid: uuid,
          type: "$OperationStarted",
          created: created,
          data: data,
        );
}

class OperationCancelled extends DomainEvent {
  OperationCancelled({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
  }) : super(
          uuid: uuid,
          type: "$OperationCancelled",
          created: created,
          data: data,
        );
}

class OperationFinished extends DomainEvent {
  OperationFinished({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
  }) : super(
          uuid: uuid,
          type: "$OperationFinished",
          created: created,
          data: data,
        );
}

class OperationDeleted extends DomainEvent {
  OperationDeleted({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
  }) : super(
          uuid: uuid,
          type: "$OperationDeleted",
          created: created,
          data: data,
        );
}

//////////////////////////////////////
// Objective Domain Events
//////////////////////////////////////

class ObjectiveAdded extends DomainEvent {
  ObjectiveAdded({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
  }) : super(
          uuid: uuid,
          type: "$ObjectiveAdded",
          created: created,
          data: data,
        );
}

class ObjectiveUpdated extends DomainEvent {
  ObjectiveUpdated({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
  }) : super(
          uuid: uuid,
          type: "$ObjectiveUpdated",
          created: created,
          data: data,
        );
}

class ObjectiveRemoved extends DomainEvent {
  ObjectiveRemoved({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
  }) : super(
          uuid: uuid,
          type: "$ObjectiveRemoved",
          created: created,
          data: data,
        );
}

//////////////////////////////////////
// TalkGroup Domain Events
//////////////////////////////////////

class TalkGroupAdded extends DomainEvent {
  TalkGroupAdded({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
  }) : super(
          uuid: uuid,
          type: "$TalkGroupAdded",
          created: created,
          data: data,
        );
}

class TalkGroupUpdated extends DomainEvent {
  TalkGroupUpdated({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
  }) : super(
          uuid: uuid,
          type: "$TalkGroupUpdated",
          created: created,
          data: data,
        );
}

class TalkGroupRemoved extends DomainEvent {
  TalkGroupRemoved({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
  }) : super(
          uuid: uuid,
          type: "$TalkGroupRemoved",
          created: created,
          data: data,
        );
}

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
          type: "$UnitCreated",
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
          type: "$UnitInformationUpdated",
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
          type: "$UnitMobilized",
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
          type: "$UnitDeployed",
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
          type: "$UnitRetired",
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
          type: "$UnitDeleted",
          created: created,
          data: data,
        );
}
