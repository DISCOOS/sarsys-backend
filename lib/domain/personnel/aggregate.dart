import 'package:sarsys_app_server/eventsource/eventsource.dart';

import 'events.dart';

class Personnel extends AggregateRoot<PersonnelCreated, PersonnelDeleted> {
  Personnel(
    String uuid,
    Map<String, Process> processors, {
    Map<String, dynamic> data = const {},
  }) : super(uuid, processors, data);
}
