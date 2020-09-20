import 'package:event_source/event_source.dart';
import 'package:event_source/src/models/event_model.dart';
import 'package:event_source/src/models/snapshot_model.dart';
import 'package:uuid/uuid.dart';

import 'aggregate_root_model.dart';
import 'event_number_model.dart';

Event fromEventModelJson(Map<String, dynamic> json) {
  final model = EventModel.fromJson(json);
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

Map<String, AggregateRootModel> fromAggregateRootsJson(Map aggregates) => Map<String, AggregateRootModel>.from(
      aggregates.map((key, value) => MapEntry(key, AggregateRootModel.fromJson(Map.from(value)))),
    );

Map<String, dynamic> toAggregateRootsJson(Map<String, AggregateRootModel> aggregates) =>
    Map.from(aggregates.map((key, value) => MapEntry(key, value.toJson())));

SnapshotModel toSnapshot(Repository repo, {DateTime timestamp}) => SnapshotModel(
      uuid: Uuid().v4(),
      aggregates: toAggregateRoots(repo),
      timestamp: timestamp ?? DateTime.now(),
      number: EventNumberModel.from(repo.number),
    );

Map<String, AggregateRootModel> toAggregateRoots(Repository repo) =>
    Map.fromEntries(repo.aggregates.map(toAggregateRoot).map(
          (a) => MapEntry(a.uuid, a),
        ));

Map<String, AggregateRootModel> replaceAggregateRoot(
  Map<String, AggregateRootModel> aggregates,
  AggregateRoot root,
) {
  final model = toAggregateRoot(root);
  final updated = Map.from(aggregates);
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
