import 'dart:collection';

import 'package:equatable/equatable.dart';
import 'package:event_source/event_source.dart';
import 'package:event_source/src/models/aggregate_root_model.dart';
import 'package:event_source/src/models/converters.dart';
import 'package:json_annotation/json_annotation.dart';

import 'event_number_model.dart';

part 'snapshot_model.g.dart';

@JsonSerializable()
class SnapshotModel extends Equatable {
  SnapshotModel({
    this.uuid,
    this.number,
    this.timestamp,
    LinkedHashMap<String, AggregateRootModel> aggregates,
  })  : _missing = _checkPartial(number, aggregates),
        // ignore: prefer_collection_literals
        aggregates = aggregates ?? LinkedHashMap<String, AggregateRootModel>();

  /// [SnapshotModel] uuid
  final String uuid;

  /// [Snapshot] timestamp
  final DateTime timestamp;

  /// Get event number of [Event] applied last
  final EventNumberModel number;

  /// Check if snapshot is partial.
  /// A partial snapshot contains
  /// aggregates that are missing
  /// events. This is an error
  /// that should not happen,
  /// but is resolvable.
  bool get isPartial => _missing > 0;

  static int _checkPartial(
    EventNumberModel number,
    LinkedHashMap<String, AggregateRootModel> aggregates,
  ) {
    var value = 0;
    if (aggregates != null) {
      for (var a in (aggregates).values) {
        // Adjust for zero-based number
        value = value + a.number.value + 1;
      }
    }
    // Adjust for zero-based number
    return number.value + 1 - value;
  }

  /// Get number of events missing from snapshot
  int get missing => _missing;
  final int _missing;

  /// List of aggregate roots
  @JsonKey(
    toJson: toAggregateRootsJson,
    fromJson: fromAggregateRootsJson,
  )
  final LinkedHashMap<String, AggregateRootModel> aggregates;

  /// Check if snapshot contains an
  /// [AggregateRootModel] with given [uuid]
  bool contains(String uuid) => aggregates.containsKey(uuid);

  /// Get updated snapshot model
  SnapshotModel copyWith(
    Repository repo, {
    String uuid,
    AggregateRoot root,
    DateTime timestamp,
  }) =>
      SnapshotModel(
        uuid: uuid ?? this.uuid,
        timestamp: timestamp ?? DateTime.now(),
        number: EventNumberModel.from(repo.number),
        aggregates: root == null ? toAggregateRoots(repo) : replaceAggregateRoot(aggregates, root),
      );

  @override
  List<Object> get props => [aggregates, timestamp, number];

  /// Factory constructor for creating a new `SnapshotModel` instance
  factory SnapshotModel.fromJson(Map<String, dynamic> json) => _$SnapshotModelFromJson(json);

  /// Declare support for serialization to JSON
  Map<String, dynamic> toJson() => _$SnapshotModelToJson(this);
}
