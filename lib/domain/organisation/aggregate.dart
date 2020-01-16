import 'package:sarsys_app_server/eventsource/eventsource.dart';

import 'events.dart';

class Organisation extends AggregateRoot<OrganisationCreated, OrganisationDeleted> {
  Organisation(
    String uuid,
    Map<String, Process> processors, {
    Map<String, dynamic> data = const {},
  }) : super(uuid, processors, data);
}
