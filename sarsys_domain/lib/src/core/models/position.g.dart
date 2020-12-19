// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'position.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PositionModel _$PositionModelFromJson(Map json) {
  return PositionModel(
    geometry: json['geometry'] == null
        ? null
        : PointModel.fromJson((json['geometry'] as Map)?.map(
            (k, e) => MapEntry(k as String, e),
          )),
    properties: json['properties'] == null
        ? null
        : PositionPropertiesModel.fromJson((json['properties'] as Map)?.map(
            (k, e) => MapEntry(k as String, e),
          )),
  );
}

Map<String, dynamic> _$PositionModelToJson(PositionModel instance) =>
    <String, dynamic>{
      'geometry': instance.geometry?.toJson(),
      'properties': instance.properties?.toJson(),
    };

PositionPropertiesModel _$PositionPropertiesModelFromJson(Map json) {
  return PositionPropertiesModel(
    acc: (json['accuracy'] as num)?.toDouble(),
    timestamp: json['timestamp'] == null
        ? null
        : DateTime.parse(json['timestamp'] as String),
    activity: json['activity'] == null
        ? null
        : ActivityModel.fromJson((json['activity'] as Map)?.map(
            (k, e) => MapEntry(k as String, e),
          )),
    source: _$enumDecodeNullable(_$PositionSourceEnumMap, json['source']),
  );
}

Map<String, dynamic> _$PositionPropertiesModelToJson(
        PositionPropertiesModel instance) =>
    <String, dynamic>{
      'accuracy': instance.acc,
      'timestamp': instance.timestamp?.toIso8601String(),
      'source': _$PositionSourceEnumMap[instance.source],
      'activity': instance.activity?.toJson(),
    };

T _$enumDecode<T>(
  Map<T, dynamic> enumValues,
  dynamic source, {
  T unknownValue,
}) {
  if (source == null) {
    throw ArgumentError('A value must be provided. Supported values: '
        '${enumValues.values.join(', ')}');
  }

  final value = enumValues.entries
      .singleWhere((e) => e.value == source, orElse: () => null)
      ?.key;

  if (value == null && unknownValue == null) {
    throw ArgumentError('`$source` is not one of the supported values: '
        '${enumValues.values.join(', ')}');
  }
  return value ?? unknownValue;
}

T _$enumDecodeNullable<T>(
  Map<T, dynamic> enumValues,
  dynamic source, {
  T unknownValue,
}) {
  if (source == null) {
    return null;
  }
  return _$enumDecode<T>(enumValues, source, unknownValue: unknownValue);
}

const _$PositionSourceEnumMap = {
  PositionSource.manual: 'manual',
  PositionSource.device: 'device',
  PositionSource.aggregate: 'aggregate',
};

ActivityModel _$ActivityModelFromJson(Map json) {
  return ActivityModel(
    type: _$enumDecodeNullable(_$ActivityTypeEnumMap, json['type']),
    confidence: json['confidence'] as int,
  );
}

Map<String, dynamic> _$ActivityModelToJson(ActivityModel instance) =>
    <String, dynamic>{
      'type': _$ActivityTypeEnumMap[instance.type],
      'confidence': instance.confidence,
    };

const _$ActivityTypeEnumMap = {
  ActivityType.still: 'still',
  ActivityType.on_foot: 'on_foot',
  ActivityType.walking: 'walking',
  ActivityType.running: 'running',
  ActivityType.on_bicycle: 'on_bicycle',
  ActivityType.in_vehicle: 'in_vehicle',
};
