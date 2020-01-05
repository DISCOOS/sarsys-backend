import 'package:sarsys_app_server/eventsource/eventsource.dart';

import 'aggregate.dart';
import 'commands.dart';
import 'events.dart';

class UnitRepository extends Repository<UnitCommand, Unit> {
  UnitRepository(EventStore store) : super(store: store);

  @override
  DomainEvent toDomainEvent(Event event) {
    switch (event.type) {
      case "UnitCreated":
        return UnitCreated(
          uuid: event.uuid,
          data: event.data,
          created: event.created,
        );
      case 'UnitInformationUpdated':
        return UnitInformationUpdated(
          uuid: event.uuid,
          data: event.data,
          created: event.created,
        );
      case 'UnitMobilized':
        return UnitMobilized(
          uuid: event.uuid,
          data: event.data,
          created: event.created,
        );
      case 'UnitRetired':
        return UnitRetired(
          uuid: event.uuid,
          data: event.data,
          created: event.created,
        );
    }
    throw InvalidOperation("Event type ${event.type} not recognized");
  }

  @override
  Unit create(String uuid, Map<String, dynamic> data) => Unit(uuid, data: data);
}
