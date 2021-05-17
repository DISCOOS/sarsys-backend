import 'package:event_source/event_source.dart';

import 'events.dart';

class Subject extends AggregateRoot<SubjectRegistered, SubjectDeleted> {
  Subject(
    String uuid,
    Map<Type, ProcessCallback> processors, {
    Map<String, dynamic> data = const {},
  }) : super(uuid, processors, data);
}
