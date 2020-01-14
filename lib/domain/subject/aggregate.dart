import 'package:sarsys_app_server/eventsource/eventsource.dart';

import 'events.dart';

class Subject extends AggregateRoot<SubjectRegistered, SubjectDeleted> {
  Subject(
    String uuid,
    Map<String, Process> processors, {
    Map<String, dynamic> data = const {},
  }) : super(uuid, processors, data);
}
