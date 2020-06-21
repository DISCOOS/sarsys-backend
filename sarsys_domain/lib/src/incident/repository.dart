import 'package:event_source/event_source.dart';

import 'aggregate.dart';
import 'commands.dart';
import 'events.dart';

class IncidentRepository extends Repository<IncidentCommand, Incident> implements MessageHandler<DomainEvent> {
  IncidentRepository(EventStore store)
      : super(store: store, processors: {
          IncidentRegistered: (event) => IncidentRegistered(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
          IncidentInformationUpdated: (event) => IncidentInformationUpdated(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
          OperationAddedToIncident: (event) => OperationAddedToIncident(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
          OperationRemovedFromIncident: (event) => OperationRemovedFromIncident(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
          SubjectAddedToIncident: (event) => SubjectAddedToIncident(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
          SubjectRemovedFromIncident: (event) => SubjectRemovedFromIncident(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
          IncidentRespondedTo: (event) => IncidentRespondedTo(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
          IncidentResolved: (event) => IncidentResolved(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
          IncidentDeleted: (event) => IncidentDeleted(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
          ClueAdded: (event) => ClueAdded(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
          ClueUpdated: (event) => ClueUpdated(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
          ClueRemoved: (event) => ClueRemoved(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
          IncidentMessageAdded: (event) => IncidentMessageAdded(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
          IncidentMessageUpdated: (event) => IncidentMessageUpdated(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
          IncidentMessageRemoved: (event) => IncidentMessageRemoved(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              )
        });

  AssociationRule newRemoveSubjectRule(_) => AssociationRule(
        (source, target) => RemoveSubjectFromIncident(
          get(target),
          toAggregateUuid(source),
        ),
        target: this,
        targetField: 'subjects',
        intent: Action.delete,
        //
        // Relation: 'subjects-to-incident'
        //
        // - will remove subject
        //   from 'subjects' list
        //   when deleted
        //
        cardinality: Cardinality.any,
      );

  AssociationRule newRemoveOperationRule(_) => AssociationRule(
        (source, target) => RemoveOperationFromIncident(
          get(target),
          toAggregateUuid(source),
        ),
        target: this,
        targetField: 'operations',
        intent: Action.delete,
        //
        // Relation: 'operations-to-incident'
        //
        // - will remove operation
        //   from 'operations' list
        //   when deleted
        //
        cardinality: Cardinality.any,
      );

  @override
  Incident create(Map<String, Process> processors, String uuid, Map<String, dynamic> data) => Incident(
        uuid,
        processors,
        data: data,
      );
}
