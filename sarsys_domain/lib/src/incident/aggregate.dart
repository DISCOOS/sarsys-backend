import 'package:event_source/event_source.dart';

import 'events.dart';

class Incident extends AggregateRoot<IncidentRegistered, IncidentDeleted> {
  Incident(
    String uuid,
    Map<String, ProcessCallback> processors, {
    Map<String, dynamic> data = const {},
  }) : super(uuid, processors, data);
}
