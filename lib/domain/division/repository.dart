import 'package:sarsys_app_server/eventsource/eventsource.dart';

import 'aggregate.dart';
import 'commands.dart';
import 'events.dart';

class DivisionRepository extends Repository<DivisionCommand, Division> {
  DivisionRepository(EventStore store)
      : super(store: store, processors: {
          DivisionRegistered: (event) => DivisionRegistered(
                uuid: event.uuid,
                data: event.data,
                created: event.created,
              ),
          DivisionInformationUpdated: (event) => DivisionInformationUpdated(
                uuid: event.uuid,
                data: event.data,
                created: event.created,
              ),
          DivisionStarted: (event) => DivisionStarted(
                uuid: event.uuid,
                data: event.data,
                created: event.created,
              ),
          DivisionCancelled: (event) => DivisionCancelled(
                uuid: event.uuid,
                data: event.data,
                created: event.created,
              ),
          DivisionFinished: (event) => DivisionFinished(
                uuid: event.uuid,
                data: event.data,
                created: event.created,
              ),
          DivisionDeleted: (event) => DivisionDeleted(
                uuid: event.uuid,
                data: event.data,
                created: event.created,
              ),
        });

  @override
  Division create(Map<String, Process> processors, String uuid, Map<String, dynamic> data) => Division(
        uuid,
        processors,
        data: data,
      );
}
