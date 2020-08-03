import 'package:event_source/event_source.dart';

import 'events.dart';

class Device extends AggregateRoot<DeviceCreated, DeviceDeleted> {
  Device(
    String uuid,
    Map<String, ProcessCallback> processors, {
    Map<String, dynamic> data = const {},
  }) : super(uuid, processors, data);
}
