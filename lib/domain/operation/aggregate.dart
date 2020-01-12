import 'package:sarsys_app_server/eventsource/eventsource.dart';

import 'events.dart';

class Operation extends AggregateRoot<OperationRegistered, OperationDeleted> {
  Operation(
    String uuid,
    Map<String, Process> processors, {
    Map<String, dynamic> data = const {},
  }) : super(uuid, processors, data);
}
