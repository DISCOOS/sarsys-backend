import 'package:meta/meta.dart';

import 'package:event_source/event_source.dart';
import 'package:sarsys_domain/src/affiliation/repository.dart';

import 'aggregate.dart';
import 'commands.dart';
import 'events.dart';

class PersonRepository extends Repository<PersonCommand, Person> {
  PersonRepository(
    EventStore store, {
    @required this.affiliations,
  }) : super(store: store, processors: {
          PersonCreated: (event) => PersonCreated(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
          PersonInformationUpdated: (event) => PersonInformationUpdated(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
          PersonDeleted: (event) => PersonDeleted(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
        });

  final AffiliationRepository affiliations;

  @override
  void willStartProcessingEvents() {
    // Delete all person-to-affiliation
    // relations if any  exist
    rule<PersonDeleted>(affiliations.newDeletePersonRule);

    super.willStartProcessingEvents();
  }

  @override
  Person create(Map<String, ProcessCallback> processors, String uuid, Map<String, dynamic> data) => Person(
        uuid,
        processors,
        data: data,
      );
}
