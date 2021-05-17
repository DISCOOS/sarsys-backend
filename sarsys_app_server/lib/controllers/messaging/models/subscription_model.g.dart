// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubscriptionModel _$SubscriptionModelFromJson(Map json) {
  return SubscriptionModel(
    types: json['types'] == null
        ? null
        : (json['types'] as List)
            .map((json) => SubscriptionTypeModel.fromJson(Map<String, dynamic>.from(json as Map)))
            .toList(),
    maxCount: json['maxCount'] as int,
    minPeriod: json['minPeriod'] == null ? null : Duration(microseconds: json['minPeriod'] as int),
  );
}

Map<String, dynamic> _$SubscriptionModelToJson(SubscriptionModel instance) => <String, dynamic>{
      'maxCount': instance.maxCount,
      'minPeriod': instance.minPeriod.inSeconds,
      if (instance.types != null) 'types': instance.types.map((e) => e.toJson()).toList(),
    };
