import 'package:event_source/event_source.dart';

import 'events.dart';

class Department extends AggregateRoot<DepartmentCreated, DepartmentDeleted> {
  Department(
    String uuid,
    Map<String, Process> processors, {
    Map<String, dynamic> data = const {},
  }) : super(uuid, processors, data);
}
