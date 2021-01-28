import 'package:equatable/equatable.dart';
import 'package:event_source/src/core.dart';
import 'package:json_annotation/json_annotation.dart';

part 'event_number_model.g.dart';

@JsonSerializable()
class EventNumberModel extends Equatable {
  const EventNumberModel({
    int value = -1,
    int position,
  })  : value = value ?? -1,
        position = position ?? value ?? -1;

  /// [Event] number value
  final int value;

  /// Get [Event] position in canonical stream
  final int position;

  /// Factory constructor for creating a new `EventNumberModel` instance
  factory EventNumberModel.fromJson(Map<String, dynamic> json) => _$EventNumberModelFromJson(json);

  /// Create [EventNumberModel] from [EventNumber]
  static EventNumberModel from(EventNumber number, {int position}) => EventNumberModel(
        value: number.value,
        position: position ?? number.value,
      );

  /// Declare support for serialization to JSON
  Map<String, dynamic> toJson() => _$EventNumberModelToJson(this);

  /// Get [Event] number
  EventNumber toNumber() => value == null ? EventNumber.none : EventNumber(value);

  /// Get [Event] position
  EventNumber toPosition() => value == null ? EventNumber.none : EventNumber(position);

  @override
  List<Object> get props => [value];

  @override
  String toString() {
    return '$value';
  }
}
