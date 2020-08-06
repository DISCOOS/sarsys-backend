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
          : PositionModelProps.fromJson(
              json['properties'] as Map<String, dynamic>));
}

Map<String, dynamic> _$PositionModelToJson(PositionModel instance) =>
    <String, dynamic>{
      'geometry': instance.geometry?.toJson(),
      'properties': instance.properties?.toJson()
    };

PositionModelProps _$PositionModelPropsFromJson(Map<String, dynamic> json) {
  return PositionModelProps(
      acc: (json['accuracy'] as num)?.toDouble(),
      timestamp: json['timestamp'] == null
          ? null
          : DateTime.parse(json['timestamp'] as String),
      source: _$enumDecodeNullable(_$PositionSourceEnumMap, json['source']));
}

Map<String, dynamic> _$PositionModelPropsToJson(PositionModelProps instance) =>
    <String, dynamic>{
      'accuracy': instance.acc,
      'timestamp': instance.timestamp?.toIso8601String(),
      'source': _$PositionSourceEnumMap[instance.source]
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
