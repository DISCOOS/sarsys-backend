// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_number_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EventNumberModel _$EventNumberModelFromJson(Map json) {
  return EventNumberModel(
    value: json['value'] as int,
  );
}

Map<String, dynamic> _$EventNumberModelToJson(EventNumberModel instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('value', instance.value);
  return val;
}
