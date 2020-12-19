import 'dart:collection';

import 'package:event_source/event_source.dart';
import 'package:event_source/src/models/event_model.dart';
import 'package:event_source/src/models/snapshot_model.dart';
import 'package:uuid/uuid.dart';

import 'aggregate_root_model.dart';
import 'event_number_model.dart';

Event fromEventModelJson(dynamic json) {
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

SnapshotModel toSnapshot(Repository repo, {DateTime timestamp}) => SnapshotModel(
      uuid: Uuid().v4(),
      aggregates: toAggregateRoots(repo),
      timestamp: timestamp ?? DateTime.now(),
      number: EventNumberModel.from(repo.number),
    );

LinkedHashMap<String, AggregateRootModel> toAggregateRoots(Repository repo) =>
    LinkedHashMap.fromEntries(repo.aggregates.map(toAggregateRoot).map(
          (a) => MapEntry(a.uuid, a),
        ));

LinkedHashMap<String, AggregateRootModel> replaceAggregateRoot(
  Map<String, AggregateRootModel> aggregates,
  AggregateRoot root,
) {
  final model = toAggregateRoot(root);
  final updated = LinkedHashMap<String, AggregateRootModel>.from(aggregates);
  updated.update(root.uuid, (_) => model, ifAbsent: () => model);
  return updated;
}

AggregateRootModel toAggregateRoot(AggregateRoot root) => AggregateRootModel(
      uuid: root.uuid,
      data: root.data,
      createdBy: root.createdBy,
      changedBy: root.changedBy,
      deletedBy: root.deletedBy,
      number: EventNumberModel.from(root.number),
    );
