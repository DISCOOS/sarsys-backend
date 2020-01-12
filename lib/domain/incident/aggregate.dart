import 'package:sarsys_app_server/eventsource/eventsource.dart';

import 'events.dart';

class Incident extends AggregateRoot<IncidentRegistered, IncidentDeleted> {
  Incident(
    String uuid,
    Map<String, Process> processors, {
    Map<String, dynamic> data = const {},
  }) : super(uuid, processors, data);
}
