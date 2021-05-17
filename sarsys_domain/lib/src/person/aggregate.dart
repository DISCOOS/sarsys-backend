import 'package:event_source/event_source.dart';

import 'events.dart';

class Person extends AggregateRoot<PersonCreated, PersonDeleted> {
  Person(
    String uuid,
    Map<Type, ProcessCallback> processors, {
    Map<String, dynamic> data = const {},
  }) : super(uuid, processors, data);
}
