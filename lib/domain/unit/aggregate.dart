import 'package:sarsys_app_server/eventsource/eventsource.dart';
import 'package:uuid/uuid.dart';

import 'events.dart';

class Unit extends AggregateRoot {
  Unit(
    String uuid, {
    Map<String, dynamic> data = const {},
  }) : super(uuid, data);

  @override
  DomainEvent created(
    Map<String, dynamic> data, {
    String type,
    DateTime timestamp,
  }) =>
      UnitCreated(
        uuid: Uuid().v4(),
        data: data,
        created: timestamp,
      );

  // TODO: Refactor into Read and Write models? Current mapping Event to Read and Command to Write does not feel right.

  @override
  DomainEvent updated(Map<String, dynamic> data, {String type, bool command, DateTime timestamp}) {
    switch (type) {
      case "UpdateUnit":
      case "UnitInformationUpdated":
        return UnitInformationUpdated(
          uuid: Uuid().v4(),
          data: data,
          created: timestamp,
        );
      case "UnitMobilized":
        return UnitMobilized(
          uuid: Uuid().v4(),
          data: data,
          created: timestamp,
        );
      case "UnitDeployed":
        return UnitDeployed(
          uuid: Uuid().v4(),
          data: data,
          created: timestamp,
        );
      case "UnitRetired":
        return UnitRetired(
          uuid: Uuid().v4(),
          data: data,
          created: timestamp,
        );
    }
    throw UnimplementedError("Update type $type not implemented");
  }
}
