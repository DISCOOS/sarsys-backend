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
