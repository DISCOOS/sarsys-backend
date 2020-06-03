import 'package:event_source/event_source.dart';
import 'package:sarsys_domain/src/mission/events.dart';
import 'package:sarsys_domain/src/unit/events.dart';

import 'aggregate.dart';
import 'commands.dart';
import 'events.dart';

class OperationRepository extends Repository<OperationCommand, Operation> {
  OperationRepository(EventStore store)
      : super(store: store, processors: {
          OperationRegistered: (event) => OperationRegistered(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
          OperationInformationUpdated: (event) => OperationInformationUpdated(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
          MissionAddedToOperation: (event) => OperationStarted(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
          MissionRemovedFromOperation: (event) => MissionRemovedFromOperation(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
          UnitAddedToOperation: (event) => UnitAddedToOperation(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
          UnitRemovedFromOperation: (event) => UnitRemovedFromOperation(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
          OperationStarted: (event) => OperationStarted(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
          OperationCancelled: (event) => OperationCancelled(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
          OperationFinished: (event) => OperationFinished(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
          OperationDeleted: (event) => OperationDeleted(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
          ObjectiveAdded: (event) => ObjectiveAdded(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
          ObjectiveUpdated: (event) => ObjectiveUpdated(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
          ObjectiveRemoved: (event) => ObjectiveRemoved(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
          TalkGroupAdded: (event) => TalkGroupAdded(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
          TalkGroupUpdated: (event) => TalkGroupUpdated(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
          TalkGroupRemoved: (event) => TalkGroupRemoved(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
          OperationMessageAdded: (event) => OperationMessageAdded(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
          OperationMessageUpdated: (event) => OperationMessageUpdated(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
          OperationMessageRemoved: (event) => OperationMessageRemoved(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
        });

  @override
  void willStartProcessingEvents() {
    // Remove Mission from 'missions' list when deleted
    rule<MissionDeleted>(newRemoveMissionRule);

    // Remove Unit from 'units' list when deleted
    rule<UnitDeleted>(newRemoveUnitRule);

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
  Operation create(Map<String, Process> processors, String uuid, Map<String, dynamic> data) => Operation(
        uuid,
        processors,
        data: data,
      );
}
