import 'package:event_source/event_source.dart';

import 'aggregate.dart';
import 'commands.dart';
import 'events.dart';

class DeviceRepository extends Repository<DeviceCommand, Device> {
  DeviceRepository(EventStore store)
      : super(store: store, processors: {
          DeviceCreated: (event) => DeviceCreated(event),
          DeviceInformationUpdated: (event) => DeviceInformationUpdated(event),
          DevicePositionChanged: (event) => DevicePositionChanged(event),
          DeviceDeleted: (event) => DeviceDeleted(event),
          DeviceMessageAdded: (event) => DeviceMessageAdded(event),
          DeviceMessageUpdated: (event) => DeviceMessageUpdated(event),
          DeviceMessageRemoved: (event) => DeviceMessageRemoved(event),
        });

  @override
  Device create(Map<String, ProcessCallback> processors, String uuid, Map<String, dynamic> data) => Device(
        uuid,
        processors,
        data: data,
      );
}
