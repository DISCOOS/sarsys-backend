import 'package:json_annotation/json_annotation.dart';

import 'event_number_model.dart';

part 'event_model.g.dart';

@JsonSerializable()
class EventModel {
  EventModel({
    this.type,
    this.uuid,
    this.data,
    this.number,
    this.created,
  });

  /// [EventModel] type
  final String type;

  /// [EventModel] uuid
  final String uuid;

  /// Get [EventNumberModel] in stream
  final EventNumberModel number;

  /// [EventModel] creation time
  final DateTime created;

  /// [EventModel] data
  final Map<String, dynamic> data;

  /// Factory constructor for creating a new `AggregateRootModel` instance
  factory EventModel.fromJson(Map<String, dynamic> json) => _$EventModelFromJson(json);

  /// Declare support for serialization to JSON
  Map<String, dynamic> toJson() => _$EventModelToJson(this);
}
