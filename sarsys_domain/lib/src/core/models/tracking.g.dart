// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tracking.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TrackingModel _$TrackingModelFromJson(Map json) {
  return TrackingModel(
    uuid: json['uuid'] as String,
    status: _$enumDecodeNullable(_$TrackingStatusEnumMap, json['status']),
    speed: (json['speed'] as num)?.toDouble(),
    effort: json['effort'] == null
        ? null
        : Duration(microseconds: json['effort'] as int),
    tracks: (json['tracks'] as List)
        ?.map((e) => e == null
            ? null
            : TrackModel.fromJson((e as Map)?.map(
                (k, e) => MapEntry(k as String, e),
              )))
        ?.toList(),
    sources: (json['sources'] as List)
        ?.map((e) => e == null
            ? null
            : SourceModel.fromJson((e as Map)?.map(
                (k, e) => MapEntry(k as String, e),
              )))
        ?.toList(),
    history: (json['history'] as List)
        ?.map((e) => e == null
            ? null
            : PositionModel.fromJson((e as Map)?.map(
                (k, e) => MapEntry(k as String, e),
              )))
        ?.toList(),
    position: json['position'] == null
        ? null
        : PositionModel.fromJson((json['position'] as Map)?.map(
            (k, e) => MapEntry(k as String, e),
          )),
    distance: (json['distance'] as num)?.toDouble(),
  );
}

Map<String, dynamic> _$TrackingModelToJson(TrackingModel instance) =>
    <String, dynamic>{
      'uuid': instance.uuid,
      'status': _$TrackingStatusEnumMap[instance.status],
      'speed': instance.speed,
      'effort': instance.effort?.inMicroseconds,
      'distance': instance.distance,
      'position': instance.position?.toJson(),
      'tracks': instance.tracks?.map((e) => e?.toJson())?.toList(),
      'sources': instance.sources?.map((e) => e?.toJson())?.toList(),
      'history': instance.history?.map((e) => e?.toJson())?.toList(),
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

const _$TrackingStatusEnumMap = {
  TrackingStatus.ready: 'ready',
  TrackingStatus.tracking: 'tracking',
  TrackingStatus.paused: 'paused',
  TrackingStatus.closed: 'closed',
};
