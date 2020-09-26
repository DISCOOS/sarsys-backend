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
  }) : aggregates = aggregates ?? <String, AggregateRootModel>{};

  /// [SnapshotModel] uuid
  final String uuid;

  /// [Snapshot] timestamp
  final DateTime timestamp;

  /// Get event number of [Event] applied last
  final EventNumberModel number;

  /// List of aggregate roots
  @JsonKey(
    toJson: toAggregateRootsJson,
    fromJson: fromAggregateRootsJson,
  )
  final LinkedHashMap<String, AggregateRootModel> aggregates;

  /// Get updated snapshot model
  SnapshotModel copyWith(Repository repo, {String uuid, AggregateRoot root}) => SnapshotModel(
        uuid: uuid ?? this.uuid,
        timestamp: DateTime.now(),
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
