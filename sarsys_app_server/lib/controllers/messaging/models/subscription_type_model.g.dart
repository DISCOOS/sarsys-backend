// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_type_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubscriptionTypeModel _$SubscriptionTypeModelFromJson(Map json) {
  return SubscriptionTypeModel(
    name: json['name'] as String,
    statePatches: json['statePatches'] as bool,
    changedState: json['changedState'] as bool,
    previousState: json['previousState'] as bool,
    match: _$enumDecodeNullable(
      _$FilterMatchEnumMap,
      json['match'],
      unknownValue: FilterMatch.any,
    ),
    events: json['events'] == null
        ? null
        : (json['events'] as List)
            .map((json) => SubscriptionEventModel.fromJson(Map<String, dynamic>.from(json as Map)))
            .toList(),
    filters: json['filters'] == null
        ? null
        : (json['filters'] as List)
            .map((json) => SubscriptionFilterModel.fromJson(Map<String, dynamic>.from(json as Map)))
            .toList(),
  );
}

Map<String, dynamic> _$SubscriptionTypeModelToJson(SubscriptionTypeModel instance) => <String, dynamic>{
      'name': instance.name,
      'statePatches': instance.statePatches,
      'changedState': instance.changedState,
      'previousState': instance.previousState,
      'match': _$FilterMatchEnumMap[instance.match],
      if (instance.events != null) 'events': instance.events.map((e) => e.toJson()).toList(),
      if (instance.filters != null) 'filters': instance.filters.map((e) => e.toJson()).toList(),
    };

const _$FilterMatchEnumMap = {
  FilterMatch.any: 'any',
  FilterMatch.all: 'all',
};

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

T _$enumDecode<T>(
  Map<T, dynamic> enumValues,
  dynamic source, {
  T unknownValue,
}) {
  if (source == null) {
    throw ArgumentError('A value must be provided. Supported values: '
        '${enumValues.values.join(', ')}');
  }

  final value = enumValues.entries.singleWhere((e) => e.value == source, orElse: () => null)?.key;

  if (value == null && unknownValue == null) {
    throw ArgumentError('`$source` is not one of the supported values: '
        '${enumValues.values.join(', ')}');
  }
  return value ?? unknownValue;
}
