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
          PersonCreated: (event) => PersonCreated(event),
          PersonInformationUpdated: (event) => PersonInformationUpdated(event),
          PersonDeleted: (event) => PersonDeleted(event),
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
