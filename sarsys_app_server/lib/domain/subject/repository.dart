import 'package:event_source/event_source.dart';

import 'aggregate.dart';
import 'commands.dart';
import 'events.dart';

class SubjectRepository extends Repository<SubjectCommand, Subject> {
  SubjectRepository(EventStore store)
      : super(store: store, processors: {
          SubjectRegistered: (event) => SubjectRegistered(
                uuid: event.uuid,
                data: event.data,
                created: event.created,
              ),
          SubjectUpdated: (event) => SubjectUpdated(
                uuid: event.uuid,
                data: event.data,
                created: event.created,
              ),
          SubjectDeleted: (event) => SubjectDeleted(
                uuid: event.uuid,
                data: event.data,
                created: event.created,
              )
        });

  @override
  Subject create(Map<String, Process> processors, String uuid, Map<String, dynamic> data) => Subject(
        uuid,
        processors,
        data: data,
      );
}
