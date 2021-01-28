import 'dart:collection';

import 'package:event_source/event_source.dart';
import 'package:event_source/src/models/event_model.dart';
import 'package:event_source/src/models/snapshot_model.dart';
import 'package:uuid/uuid.dart';

import 'aggregate_root_model.dart';
import 'event_number_model.dart';

Event fromEventModelJson(dynamic json) {
  if (json != null) {
    final model = EventModel.fromJson(
      toMapJson(json as Map),
    );
    return Event(
      local: false,
      type: model.type,
      uuid: model.uuid,
      data: model.data,
      created: model.created,
      number: EventNumber(model.number.value),
    );
  }
  return null;
}

Map<String, dynamic> toEventModelJson(Event event) {
  if (event != null) {
    final model = EventModel(
      type: event.type,
      uuid: event.uuid,
      data: event.data,
      created: event.created,
      number: EventNumberModel.from(event.number),
    );
    return model.toJson();
  }
  return null;
}

Map<String, dynamic> toMapJson(Map data) => Map<String, dynamic>.from(data);
LinkedHashMap<String, dynamic> toLinkedHashMapJson(Map data) => LinkedHashMap<String, dynamic>.from(data);

LinkedHashMap<String, AggregateRootModel> fromAggregateRootsJson(dynamic aggregates) =>
    LinkedHashMap<String, AggregateRootModel>.from(
      (aggregates as Map)
          .map((key, value) => MapEntry(key, AggregateRootModel.fromJson(toLinkedHashMapJson(value as Map)))),
    );

LinkedHashMap<String, dynamic> toAggregateRootsJson(Map<String, AggregateRootModel> aggregates) =>
    toLinkedHashMapJson(aggregates.map((key, value) => MapEntry(key, value.toJson())));

SnapshotModel toSnapshot(Repository repo, {DateTime timestamp}) =>
    repo.snapshot?.copyWith(
      repo,
      uuid: Uuid().v4(),
      timestamp: timestamp,
      type: '${repo.aggregateType}',
    ) ??
    SnapshotModel(
      uuid: Uuid().v4(),
      type: '${repo.aggregateType}',
      aggregates: toAggregateRoots(repo),
      timestamp: timestamp ?? DateTime.now(),
      number: EventNumberModel.from(repo.number),
    );

/// Only aggregates with base is included
LinkedHashMap<String, AggregateRootModel> toAggregateRoots(Repository repo) =>
    LinkedHashMap.fromEntries(repo.aggregates.where((a) => !a.isNew).map(toAggregateRoot).map(
          (a) => MapEntry(a.uuid, a),
        ));

LinkedHashMap<String, AggregateRootModel> replaceAggregateRoot(
  LinkedHashMap<String, AggregateRootModel> aggregates,
  AggregateRoot aggregate,
) {
  final prev = aggregates[aggregate.uuid];
  if (prev == null || prev.number.value < aggregate.baseEvent.number.value) {
    final model = toAggregateRoot(aggregate);
    aggregates.update(aggregate.uuid, (_) => model, ifAbsent: () => model);
  }
  return aggregates;
}

/// Store remote state only!
AggregateRootModel toAggregateRoot(AggregateRoot root) => AggregateRootModel(
      uuid: root.uuid,
      data: root.head,
      createdBy: root.createdBy,
      changedBy: root.baseEvent,
      deletedBy: root.deletedBy,
      // Since only aggregates
      // confirmed to exist remotely
      // should be persisted, BaseEvent
      // MUST exist!
      number: EventNumberModel.from(root.baseEvent.number),
    );
