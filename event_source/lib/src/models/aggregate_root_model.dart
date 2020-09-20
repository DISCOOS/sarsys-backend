import 'package:equatable/equatable.dart';
import 'package:event_source/event_source.dart';
import 'package:event_source/src/models/converters.dart';
import 'package:json_annotation/json_annotation.dart';

import 'event_number_model.dart';

part 'aggregate_root_model.g.dart';

@JsonSerializable()
class AggregateRootModel extends Equatable {
  AggregateRootModel({
    this.uuid,
    this.data,
    this.number,
    this.createdBy,
    this.changedBy,
    this.deletedBy,
  });

  /// [AggregateRoot] uuid
  ///
  /// Not the same as [Event.uuid], which is unique for each event.
  final String uuid;

  /// Get [Event] that created this aggregate
  @JsonKey(
    toJson: toEventModelJson,
    fromJson: fromEventModelJson,
  )
  final Event createdBy;

  /// Get [DateTime] of when this [AggregateRoot] was created
  @JsonKey(ignore: true)
  DateTime get createdWhen => createdBy?.created;

  /// Get [Event] that last changed this aggregate
  @JsonKey(
    toJson: toEventModelJson,
    fromJson: fromEventModelJson,
  )
  final Event changedBy;

  /// Get [DateTime] of when this [AggregateRoot] was changed
  @JsonKey(ignore: true)
  DateTime get changedWhen => changedBy?.created;

  /// Get [Event] that deleted this aggregate
  @JsonKey(
    toJson: toEventModelJson,
    fromJson: fromEventModelJson,
  )
  final Event deletedBy;

  /// Get [DateTime] of when this [AggregateRoot] was deleted
  @JsonKey(ignore: true)
  DateTime get deletedWhen => deletedBy?.created;

  /// Get event number of [Event] applied last
  final EventNumberModel number;

  /// AggregateRoot root data (weak schema)
  @JsonKey(
    toJson: toMapJson,
    fromJson: toMapJson,
  )
  final Map<String, dynamic> data;

  @override
  List<Object> get props => [uuid, changedBy, changedBy, deletedBy, data, number];

  /// Factory constructor for creating a new `AggregateRoot` instance
  factory AggregateRootModel.fromJson(Map<String, dynamic> json) => _$AggregateRootModelFromJson(json);

  /// Declare support for serialization to JSON
  Map<String, dynamic> toJson() => _$AggregateRootModelToJson(this);
}
