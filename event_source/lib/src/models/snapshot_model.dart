import 'dart:collection';
import 'dart:math';

import 'package:meta/meta.dart';
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
    @required this.uuid,
    @required this.type,
    @required this.number,
    DateTime timestamp,
    LinkedHashMap<String, AggregateRootModel> aggregates,
  })  : timestamp = timestamp ?? DateTime.now(),
        _tail = _toTail(number, aggregates),
        _missing = _toMissing(number, aggregates),
        // ignore: prefer_collection_literals
        aggregates = aggregates ?? LinkedHashMap<String, AggregateRootModel>();

  /// Aggregate type
  final String type;

  /// [SnapshotModel] uuid
  final String uuid;

  /// [Snapshot] timestamp
  final DateTime timestamp;

  /// Get [Event] number of event applied last
  final EventNumberModel number;

  /// Get number of events first event in snapshot is behind last event
  int get behind => number.position < 0 ? 0 : (number.position - (_tail < 0 ? 0 : _tail) + 1);

  /// Get position of first event in snapshot
  int get tail => _tail;
  final int _tail;

  /// Get number of events missing
  int get missing => _missing;
  final int _missing;

  /// Check if snapshot is partial.
  /// A partial snapshot contains
  /// aggregates that are missing
  /// events. This is an error
  /// that should not happen,
  /// but is resolvable by
  /// replaying events from [tail],
  ///
  bool get isPartial => _missing > 0;

  static int _toTail(
    EventNumberModel number,
    LinkedHashMap<String, AggregateRootModel> aggregates,
  ) {
    var tail = number.position;
    if (aggregates != null) {
      for (var a in (aggregates).values) {
        tail = min(tail, a.number.position);
      }
    }
    return tail;
  }

  static int _toMissing(
    EventNumberModel number,
    LinkedHashMap<String, AggregateRootModel> aggregates,
  ) {
    var count = 0;
    if (aggregates != null) {
      for (var a in (aggregates).values) {
        count += a.number.value + 1;
      }
    }
    return number.position < 0 ? 0 : number.position - count + 1;
  }

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
    String type,
    AggregateRoot root,
    DateTime timestamp,
  }) =>
      SnapshotModel(
        type: type ?? this.type,
        uuid: uuid ?? this.uuid,
        timestamp: timestamp ?? DateTime.now(),
        number: EventNumberModel.from(repo.number),
        aggregates: root == null ? toAggregateRoots(repo) : replaceAggregateRoot(repo, aggregates, root),
      );

  @override
  List<Object> get props => [type, timestamp, number, aggregates];

  /// Factory constructor for creating a new `SnapshotModel` instance
  factory SnapshotModel.fromJson(Map<String, dynamic> json) => _$SnapshotModelFromJson(json);

  /// Declare support for serialization to JSON
  Map<String, dynamic> toJson() => _$SnapshotModelToJson(this);
}
