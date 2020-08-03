import 'package:meta/meta.dart';

import 'package:event_source/event_source.dart';
import 'package:sarsys_domain/src/incident/repository.dart';

import 'aggregate.dart';
import 'commands.dart';
import 'events.dart';

class SubjectRepository extends Repository<SubjectCommand, Subject> {
  SubjectRepository(
    EventStore store, {
    @required this.incidents,
  }) : super(store: store, processors: {
          SubjectRegistered: (event) => SubjectRegistered(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
          SubjectUpdated: (event) => SubjectUpdated(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
          SubjectDeleted: (event) => SubjectDeleted(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              )
        });

  final IncidentRepository incidents;

  @override
  void willStartProcessingEvents() {
    // Remove Subject from 'subjects' list when deleted
    rule<SubjectDeleted>(incidents.newRemoveSubjectRule);

    super.willStartProcessingEvents();
  }

  @override
  Subject create(Map<String, ProcessCallback> processors, String uuid, Map<String, dynamic> data) => Subject(
        uuid,
        processors,
        data: data,
      );
}
