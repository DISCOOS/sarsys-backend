import 'package:sarsys_app_server/eventsource/eventsource.dart';

import 'aggregate.dart';
import 'commands.dart';
import 'events.dart';

class DepartmentRepository extends Repository<DepartmentCommand, Department> {
  DepartmentRepository(EventStore store)
      : super(store: store, processors: {
          DepartmentCreated: (event) => DepartmentCreated(
                uuid: event.uuid,
                data: event.data,
                created: event.created,
              ),
          DepartmentUpdated: (event) => DepartmentUpdated(
                uuid: event.uuid,
                data: event.data,
                created: event.created,
              ),
          DepartmentDeleted: (event) => DepartmentDeleted(
                uuid: event.uuid,
                data: event.data,
                created: event.created,
              ),
        });

  @override
  Department create(Map<String, Process> processors, String uuid, Map<String, dynamic> data) => Department(
        uuid,
        processors,
        data: data,
      );
}
