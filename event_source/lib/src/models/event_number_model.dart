import 'package:equatable/equatable.dart';
import 'package:event_source/src/core.dart';
import 'package:json_annotation/json_annotation.dart';

part 'event_number_model.g.dart';

@JsonSerializable()
class EventNumberModel extends Equatable {
  const EventNumberModel({
    this.value,
  });

  /// Event number value
  final int value;

  /// Factory constructor for creating a new `EventNumberModel` instance
  factory EventNumberModel.fromJson(Map<String, dynamic> json) => _$EventNumberModelFromJson(json);

  /// Create [EventNumberModel] from [EventNumber]
  static EventNumberModel from(EventNumber number) => EventNumberModel(value: number.value);

  /// Declare support for serialization to JSON
  Map<String, dynamic> toJson() => _$EventNumberModelToJson(this);

  EventNumber toNumber() => value == null ? EventNumber.none : EventNumber(value);

  @override
  List<Object> get props => [value];
}
