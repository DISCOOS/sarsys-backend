import 'package:sarsys_app_server/eventsource/eventsource.dart';

import 'events.dart';

class Mission extends AggregateRoot<MissionCreated, MissionDeleted> {
  Mission(
    String uuid,
    Map<String, Process> processors, {
    Map<String, dynamic> data = const {},
  }) : super(uuid, processors, data);
}
