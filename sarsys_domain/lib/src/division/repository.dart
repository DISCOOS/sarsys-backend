import 'package:event_source/event_source.dart';
import 'package:sarsys_domain/src/department/events.dart';

import 'aggregate.dart';
import 'commands.dart';
import 'events.dart';

class DivisionRepository extends Repository<DivisionCommand, Division> {
  DivisionRepository(EventStore store)
      : super(store: store, processors: {
          DivisionRegistered: (event) => DivisionRegistered(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
          DivisionInformationUpdated: (event) => DivisionInformationUpdated(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
          DepartmentAddedToDivision: (event) => DepartmentAddedToDivision(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
          DepartmentRemovedFromDivision: (event) => DepartmentRemovedFromDivision(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
          DivisionStarted: (event) => DivisionStarted(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
          DivisionCancelled: (event) => DivisionCancelled(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
          DivisionFinished: (event) => DivisionFinished(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
          DivisionDeleted: (event) => DivisionDeleted(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
        });

  @override
  void willStartProcessingEvents() {
    // Remove Department from 'departments' list when deleted
    rule<DepartmentDeleted>(newDeleteRule);

    super.willStartProcessingEvents();
  }

  AggregateRule newDeleteRule(_) => AssociationRule(
        (source, target) => RemoveDepartmentFromDivision(
          get(target),
          toAggregateUuid(source),
        ),
        target: this,
        targetField: 'departments',
        intent: Action.delete,
      );

  @override
  Division create(Map<String, Process> processors, String uuid, Map<String, dynamic> data) => Division(
        uuid,
        processors,
        data: data,
      );
}
