import 'dart:collection';

import 'package:event_source/event_source.dart';
import 'package:event_source/src/models/event_model.dart';
import 'package:event_source/src/models/snapshot_model.dart';
import 'package:uuid/uuid.dart';

import 'aggregate_root_model.dart';
import 'event_number_model.dart';

Event fromEventModelJson(Map json) {
  final model = EventModel.fromJson(
    toMapJson(json),
  );
  return Event(
    local: false,
    type: model.type,
    uuid: model.uuid,
    number: EventNumber(model.number.value),
    data: model.data,
    created: model.created,
  );
}

Map<String, dynamic> toEventModelJson(Event event) {
  final model = EventModel(
    type: event.type,
    uuid: event.uuid,
    data: event.data,
    created: event.created,
    number: EventNumberModel.from(event.number),
  );
  return model.toJson();
}

Map<String, dynamic> toMapJson(Map data) => Map<String, dynamic>.from(data);
LinkedHashMap<String, dynamic> toLinkedHashMapJson(Map data) => LinkedHashMap<String, dynamic>.from(data);

Map<String, AggregateRootModel> fromAggregateRootsJson(Map aggregates) =>
    LinkedHashMap<String, AggregateRootModel>.from(
      aggregates.map((key, value) => MapEntry(key, AggregateRootModel.fromJson(toLinkedHashMapJson(value)))),
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
  final updated = LinkedHashMap.from(aggregates);
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
