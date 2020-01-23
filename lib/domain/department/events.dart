import 'package:meta/meta.dart';
import 'package:sarsys_app_server/eventsource/eventsource.dart';

//////////////////////////////////////
// Department Domain Events
//////////////////////////////////////

class DepartmentCreated extends DomainEvent {
  DepartmentCreated({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
  }) : super(
          uuid: uuid,
          type: "$DepartmentCreated",
          created: created,
          data: data,
        );
}

class DepartmentInformationUpdated extends DomainEvent {
  DepartmentInformationUpdated({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
  }) : super(
          uuid: uuid,
          type: "$DepartmentInformationUpdated",
          created: created,
          data: data,
        );
}

class DepartmentDeleted extends DomainEvent {
  DepartmentDeleted({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
  }) : super(
          uuid: uuid,
          type: "$DepartmentDeleted",
          created: created,
          data: data,
        );
}
