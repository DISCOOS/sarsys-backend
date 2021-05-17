import 'package:event_source/event_source.dart';

import 'events.dart';

class Operation extends AggregateRoot<OperationRegistered, OperationDeleted> {
  Operation(
    String uuid,
    Map<Type, ProcessCallback> processors, {
    Map<String, dynamic> data = const {},
  }) : super(uuid, processors, data);
}
