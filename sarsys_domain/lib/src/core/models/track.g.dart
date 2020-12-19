// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'track.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TrackModel _$TrackModelFromJson(Map json) {
  return TrackModel(
    id: json['id'] as String,
    status: _$enumDecodeNullable(_$TrackStatusEnumMap, json['status']),
    source: json['source'] == null
        ? null
        : SourceModel.fromJson((json['source'] as Map)?.map(
            (k, e) => MapEntry(k as String, e),
          )),
    positions: (json['positions'] as List)
        ?.map((e) => e == null
            ? null
            : PositionModel.fromJson((e as Map)?.map(
                (k, e) => MapEntry(k as String, e),
              )))
        ?.toList(),
  );
}

Map<String, dynamic> _$TrackModelToJson(TrackModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'status': _$TrackStatusEnumMap[instance.status],
      'source': instance.source?.toJson(),
      'positions': instance.positions?.map((e) => e?.toJson())?.toList(),
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

const _$TrackStatusEnumMap = {
  TrackStatus.attached: 'attached',
  TrackStatus.detached: 'detached',
};
