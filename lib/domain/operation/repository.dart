import 'package:sarsys_app_server/eventsource/eventsource.dart';

import 'aggregate.dart';
import 'commands.dart';
import 'events.dart';

class OperationRepository extends Repository<OperationCommand, Operation> {
  OperationRepository(EventStore store) : super(store: store);

  @override
  DomainEvent toDomainEvent(Event event) {
    switch (event.type) {
      case "OperationRegistered":
        return OperationRegistered(
          uuid: event.uuid,
          data: event.data,
          created: event.created,
        );
      case 'OperationInformationUpdated':
        return OperationInformationUpdated(
          uuid: event.uuid,
          data: event.data,
          created: event.created,
        );
      case 'OperationStarted':
        return OperationStarted(
          uuid: event.uuid,
          data: event.data,
          created: event.created,
        );
      case 'OperationCancelled':
        return OperationCancelled(
          uuid: event.uuid,
          data: event.data,
          created: event.created,
        );
      case 'OperationFinished':
        return OperationFinished(
          uuid: event.uuid,
          data: event.data,
          created: event.created,
        );
    }
    throw InvalidOperation("Event type ${event.type} not recognized");
  }

  @override
  Operation create(String uuid, Map<String, dynamic> data) => Operation(uuid, data: data);
}
