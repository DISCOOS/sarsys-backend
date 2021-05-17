import 'package:event_source/event_source.dart';

import 'events.dart';

class Division extends AggregateRoot<DivisionRegistered, DivisionDeleted> {
  Division(
    String uuid,
    Map<Type, ProcessCallback> processors, {
    Map<String, dynamic> data = const {},
  }) : super(uuid, processors, data);
}
