import 'package:sarsys_app_server/eventsource/eventsource.dart';

import 'aggregate.dart';
import 'commands.dart';
import 'events.dart';

class DeviceRepository extends Repository<DeviceCommand, Device> {
  DeviceRepository(EventStore store)
      : super(store: store, processors: {
          DeviceCreated: (event) => DeviceCreated(
                uuid: event.uuid,
                data: event.data,
                created: event.created,
              ),
          DeviceInformationUpdated: (event) => DeviceInformationUpdated(
                uuid: event.uuid,
                data: event.data,
                created: event.created,
              ),
          DeviceDeleted: (event) => DeviceDeleted(
                uuid: event.uuid,
                data: event.data,
                created: event.created,
              ),
          DeviceMessageAdded: (event) => DeviceMessageAdded(
                uuid: event.uuid,
                data: event.data,
                created: event.created,
              ),
          DeviceMessageUpdated: (event) => DeviceMessageUpdated(
                uuid: event.uuid,
                data: event.data,
                created: event.created,
              ),
          DeviceMessageRemoved: (event) => DeviceMessageRemoved(
                uuid: event.uuid,
                data: event.data,
                created: event.created,
              ),
        });

  @override
  Device create(Map<String, Process> processors, String uuid, Map<String, dynamic> data) => Device(
        uuid,
        processors,
        data: data,
      );
}
