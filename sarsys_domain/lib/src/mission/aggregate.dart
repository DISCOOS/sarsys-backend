import 'package:event_source/event_source.dart';

import 'events.dart';

class Mission extends AggregateRoot<MissionCreated, MissionDeleted> {
  Mission(
    String uuid,
    Map<String, ProcessCallback> processors, {
    Map<String, dynamic> data = const {},
  }) : super(uuid, processors, data);
}
