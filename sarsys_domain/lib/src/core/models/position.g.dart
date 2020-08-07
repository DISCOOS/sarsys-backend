// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'position.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PositionModel _$PositionModelFromJson(Map<String, dynamic> json) {
  return PositionModel(
      geometry: json['geometry'] == null
          ? null
          : PointModel.fromJson(json['geometry'] as Map<String, dynamic>),
      properties: json['properties'] == null
          ? null
          : PositionPropertiesModel.fromJson(
              json['properties'] as Map<String, dynamic>));
}

Map<String, dynamic> _$PositionModelToJson(PositionModel instance) =>
    <String, dynamic>{
      'geometry': instance.geometry?.toJson(),
      'properties': instance.properties?.toJson()
    };

PositionPropertiesModel _$PositionPropertiesModelFromJson(
    Map<String, dynamic> json) {
  return PositionPropertiesModel(
      acc: (json['accuracy'] as num)?.toDouble(),
      timestamp: json['timestamp'] == null
          ? null
          : DateTime.parse(json['timestamp'] as String),
      activity: json['activity'] == null
          ? null
          : ActivityModel.fromJson(json['activity'] as Map<String, dynamic>),
      source: _$enumDecodeNullable(_$PositionSourceEnumMap, json['source']));
}

Map<String, dynamic> _$PositionPropertiesModelToJson(
        PositionPropertiesModel instance) =>
    <String, dynamic>{
      'accuracy': instance.acc,
      'timestamp': instance.timestamp?.toIso8601String(),
      'source': _$PositionSourceEnumMap[instance.source],
      'activity': instance.activity?.toJson()
    };

T _$enumDecode<T>(Map<T, dynamic> enumValues, dynamic source) {
  if (source == null) {
    throw ArgumentError('A value must be provided. Supported values: '
        '${enumValues.values.join(', ')}');
  }
  return enumValues.entries
      .singleWhere((e) => e.value == source,
          orElse: () => throw ArgumentError(
              '`$source` is not one of the supported values: '
              '${enumValues.values.join(', ')}'))
      .key;
}

T _$enumDecodeNullable<T>(Map<T, dynamic> enumValues, dynamic source) {
  if (source == null) {
    return null;
  }
  return _$enumDecode<T>(enumValues, source);
}

const _$PositionSourceEnumMap = <PositionSource, dynamic>{
  PositionSource.manual: 'manual',
  PositionSource.device: 'device',
  PositionSource.aggregate: 'aggregate'
};

ActivityModel _$ActivityModelFromJson(Map<String, dynamic> json) {
  return ActivityModel(
      type: _$enumDecodeNullable(_$ActivityTypeEnumMap, json['type']),
      confidence: (json['confidence'] as num)?.toDouble());
}

Map<String, dynamic> _$ActivityModelToJson(ActivityModel instance) =>
    <String, dynamic>{
      'type': _$ActivityTypeEnumMap[instance.type],
      'confidence': instance.confidence
    };

const _$ActivityTypeEnumMap = <ActivityType, dynamic>{
  ActivityType.still: 'still',
  ActivityType.on_foot: 'on_foot',
  ActivityType.walking: 'walking',
  ActivityType.running: 'running',
  ActivityType.on_bicycle: 'on_bicycle',
  ActivityType.in_vehicle: 'in_vehicle'
};
