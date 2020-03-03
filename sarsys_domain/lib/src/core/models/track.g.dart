// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'track.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TrackModel _$TrackModelFromJson(Map<String, dynamic> json) {
  return TrackModel(
      id: json['id'] as String,
      status: _$enumDecodeNullable(_$TrackStatusEnumMap, json['status']),
      source: json['source'] == null
          ? null
          : SourceModel.fromJson(json['source'] as Map<String, dynamic>),
      positions: (json['positions'] as List)
          ?.map((e) => e == null
              ? null
              : PositionModel.fromJson(e as Map<String, dynamic>))
          ?.toList());
}

Map<String, dynamic> _$TrackModelToJson(TrackModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'status': _$TrackStatusEnumMap[instance.status],
      'source': instance.source?.toJson(),
      'positions': instance.positions?.map((e) => e?.toJson())?.toList()
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

const _$TrackStatusEnumMap = <TrackStatus, dynamic>{
  TrackStatus.attached: 'attached',
  TrackStatus.detached: 'detached'
};
