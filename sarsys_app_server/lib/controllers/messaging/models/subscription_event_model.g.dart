// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_event_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubscriptionEventModel _$SubscriptionEventModelFromJson(Map json) {
  return SubscriptionEventModel(
    name: json['name'] as String,
    statePatches: json['statePatches'] as bool,
    changedState: json['changedState'] as bool,
    previousState: json['previousState'] as bool,
  );
}

Map<String, dynamic> _$SubscriptionEventModelToJson(SubscriptionEventModel instance) => <String, dynamic>{
      'name': instance.name,
      'statePatches': instance.statePatches,
      'changedState': instance.changedState,
      'previousState': instance.previousState,
    };
