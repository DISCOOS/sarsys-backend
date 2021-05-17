import 'package:event_source/event_source.dart';

import 'events.dart';

class Unit extends AggregateRoot<UnitCreated, UnitDeleted> {
  Unit(
    String uuid,
    Map<Type, ProcessCallback> processors, {
    Map<String, dynamic> data = const {},
  }) : super(uuid, processors, data);
}
