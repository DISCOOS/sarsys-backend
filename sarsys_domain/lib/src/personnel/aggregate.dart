import 'package:event_source/event_source.dart';

import 'events.dart';

class Personnel extends AggregateRoot<PersonnelMobilized, PersonnelDeleted> {
  Personnel(
    String uuid,
    Map<Type, ProcessCallback> processors, {
    Map<String, dynamic> data = const {},
  }) : super(uuid, processors, data);
}
