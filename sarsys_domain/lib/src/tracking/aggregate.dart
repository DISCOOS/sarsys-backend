import 'package:event_source/event_source.dart';

import 'events.dart';

class Tracking extends AggregateRoot<TrackingCreated, TrackingDeleted> {
  Tracking(
    String uuid,
    Map<String, ProcessCallback> processors, {
    Map<String, dynamic> data = const {},
  }) : super(uuid, processors, data);
}
