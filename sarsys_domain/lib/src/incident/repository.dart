import 'package:event_source/event_source.dart';

import 'aggregate.dart';
import 'commands.dart';
import 'events.dart';

class IncidentRepository extends Repository<IncidentCommand, Incident> implements MessageHandler<DomainEvent> {
  IncidentRepository(EventStore store)
      : super(store: store, processors: {
          IncidentRegistered: (event) => IncidentRegistered(event),
          IncidentInformationUpdated: (event) => IncidentInformationUpdated(event),
          OperationAddedToIncident: (event) => OperationAddedToIncident(event),
          OperationRemovedFromIncident: (event) => OperationRemovedFromIncident(event),
          SubjectAddedToIncident: (event) => SubjectAddedToIncident(event),
          SubjectRemovedFromIncident: (event) => SubjectRemovedFromIncident(event),
          IncidentRespondedTo: (event) => IncidentRespondedTo(event),
          IncidentResolved: (event) => IncidentResolved(event),
          IncidentDeleted: (event) => IncidentDeleted(event),
          ClueAdded: (event) => ClueAdded(event),
          ClueUpdated: (event) => ClueUpdated(event),
          ClueRemoved: (event) => ClueRemoved(event),
          IncidentMessageAdded: (event) => IncidentMessageAdded(event),
          IncidentMessageUpdated: (event) => IncidentMessageUpdated(event),
          IncidentMessageRemoved: (event) => IncidentMessageRemoved(event)
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
  Incident create(Map<String, ProcessCallback> processors, String uuid, Map<String, dynamic> data) => Incident(
        uuid,
        processors,
        data: data,
      );
}
