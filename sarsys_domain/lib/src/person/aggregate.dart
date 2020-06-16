import 'package:event_source/event_source.dart';

import 'events.dart';

class Person extends AggregateRoot<PersonCreated, PersonDeleted> {
  Person(
    String uuid,
    Map<String, Process> processors, {
    Map<String, dynamic> data = const {},
  }) : super(uuid, processors, data);
}
