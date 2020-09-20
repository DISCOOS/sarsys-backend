// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EventModel _$EventModelFromJson(Map json) {
  return EventModel(
      type: json['type'] as String,
      uuid: json['uuid'] as String,
      data: (json['data'] as Map)?.map(
        (k, e) => MapEntry(k as String, e),
      ),
      number: json['number'] == null
          ? null
          : EventNumberModel.fromJson((json['number'] as Map)?.map(
              (k, e) => MapEntry(k as String, e),
            )),
      created: json['created'] == null
          ? null
          : DateTime.parse(json['created'] as String));
}

Map<String, dynamic> _$EventModelToJson(EventModel instance) =>
    <String, dynamic>{
      'type': instance.type,
      'uuid': instance.uuid,
      'number': instance.number?.toJson(),
      'created': instance.created?.toIso8601String(),
      'data': instance.data
    };
