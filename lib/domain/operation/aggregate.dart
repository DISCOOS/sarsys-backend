import 'package:sarsys_app_server/eventsource/eventsource.dart';
import 'package:uuid/uuid.dart';

import 'events.dart';

class Operation extends AggregateRoot {
  Operation(
    String uuid, {
    Map<String, dynamic> data = const {},
  }) : super(uuid, data);

  @override
  DomainEvent created(
    Map<String, dynamic> data, {
    String type,
    DateTime timestamp,
  }) =>
      OperationRegistered(
        uuid: Uuid().v4(),
        data: data,
        created: timestamp,
      );

  // TODO: Refactor into Read and Write models? Current mapping Event to Read and Command to Write does not feel right.

  @override
  DomainEvent updated(Map<String, dynamic> data, {String type, bool command, DateTime timestamp}) {
    switch (type) {
      case "UpdateOperation":
      case "OperationInformationUpdated":
        return OperationInformationUpdated(
          uuid: Uuid().v4(),
          data: data,
          created: timestamp,
        );
      case "OperationStarted":
        return OperationStarted(
          uuid: Uuid().v4(),
          data: data,
          created: timestamp,
        );
      case "OperationCancelled":
        return OperationCancelled(
          uuid: Uuid().v4(),
          data: data,
          created: timestamp,
        );
      case "OperationFinished":
        return OperationFinished(
          uuid: Uuid().v4(),
          data: data,
          created: timestamp,
        );
    }
    throw UnimplementedError("Update type $type not implemented");
  }
}
