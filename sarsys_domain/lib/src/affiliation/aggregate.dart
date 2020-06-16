import 'package:event_source/event_source.dart';

import 'events.dart';

class Affiliation extends AggregateRoot<AffiliationCreated, AffiliationDeleted> {
  Affiliation(
    String uuid,
    Map<String, Process> processors, {
    Map<String, dynamic> data = const {},
  }) : super(uuid, processors, data);
}
