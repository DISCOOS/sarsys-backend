import 'package:meta/meta.dart';

import 'package:event_source/event_source.dart';
import 'package:sarsys_domain/sarsys_domain.dart';

import 'aggregate.dart';
import 'commands.dart';
import 'events.dart';

class OperationRepository extends Repository<OperationCommand, Operation> {
  OperationRepository(
    EventStore store, {
    @required this.incidents,
  }) : super(store: store, processors: {
          OperationRegistered: (event) => OperationRegistered(event),
          OperationInformationUpdated: (event) => OperationInformationUpdated(event),
          OperationStarted: (event) => OperationStarted(event),
          OperationCancelled: (event) => OperationCancelled(event),
          OperationFinished: (event) => OperationFinished(event),
          OperationDeleted: (event) => OperationDeleted(event),
          ObjectiveAdded: (event) => ObjectiveAdded(event),
          ObjectiveUpdated: (event) => ObjectiveUpdated(event),
          ObjectiveRemoved: (event) => ObjectiveRemoved(event),
          TalkGroupAdded: (event) => TalkGroupAdded(event),
          TalkGroupUpdated: (event) => TalkGroupUpdated(event),
          TalkGroupRemoved: (event) => TalkGroupRemoved(event),
          OperationMessageAdded: (event) => OperationMessageAdded(event),
          OperationMessageUpdated: (event) => OperationMessageUpdated(event),
          OperationMessageRemoved: (event) => OperationMessageRemoved(event),
          PersonnelAddedToOperation: (event) => PersonnelAddedToOperation(event),
          PersonnelRemovedFromOperation: (event) => PersonnelRemovedFromOperation(event),
          UnitAddedToOperation: (event) => UnitAddedToOperation(event),
          UnitRemovedFromOperation: (event) => UnitRemovedFromOperation(event),
          MissionAddedToOperation: (event) => MissionAddedToOperation(event),
          MissionRemovedFromOperation: (event) => MissionRemovedFromOperation(event),
        });

  final IncidentRepository incidents;

  @override
  void willStartProcessingEvents() {
    // Remove Operation from 'operations' list when deleted
    rule<OperationDeleted>(incidents.newRemoveOperationRule);

    super.willStartProcessingEvents();
  }

  AggregateRule newRemoveUnitRule(_) => AssociationRule(
        (source, target) => RemoveUnitFromOperation(
          get(target),
          toAggregateUuid(source),
        ),
        target: this,
        targetField: 'units',
        intent: Action.delete,
        //
        // Relation: 'units-to-operation'
        //
        // - will remove unit
        //   from 'units' list
        //   when deleted
        //
        cardinality: Cardinality.any,
      );

  AssociationRule newRemovePersonnelRule(_) => AssociationRule(
        (source, target) => RemovePersonnelFromOperation(
          get(target),
          toAggregateUuid(source),
        ),
        target: this,
        targetField: 'personnels',
        intent: Action.delete,
        //
        // Relation: 'personnels-to-operation'
        //
        // - will remove mission
        //   from 'personnels' list
        //   when deleted
        //
        cardinality: Cardinality.any,
      );

  AssociationRule newRemoveMissionRule(_) => AssociationRule(
        (source, target) => RemoveMissionFromOperation(
          get(target),
          toAggregateUuid(source),
        ),
        target: this,
        targetField: 'missions',
        intent: Action.delete,
        //
        // Relation: 'missions-to-operation'
        //
        // - will remove mission
        //   from 'missions' list
        //   when deleted
        //
        cardinality: Cardinality.any,
      );

  @override
  Operation create(Map<String, ProcessCallback> processors, String uuid, Map<String, dynamic> data) => Operation(
        uuid,
        processors,
        data: data,
      );
}
