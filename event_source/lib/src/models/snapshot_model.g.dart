// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'snapshot_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SnapshotModel _$SnapshotModelFromJson(Map json) {
  return SnapshotModel(
      uuid: json['uuid'],
      number: json['number'] == null
          ? null
          : EventNumberModel.fromJson((json['number'] as Map)?.map(
              (k, e) => MapEntry(k as String, e),
            )),
      timestamp: json['timestamp'] == null
          ? null
          : DateTime.parse(json['timestamp'] as String),
      aggregates: json['aggregates'] == null
          ? null
          : fromAggregateRootsJson(json['aggregates']));
}

Map<String, dynamic> _$SnapshotModelToJson(SnapshotModel instance) =>
    <String, dynamic>{
      'uuid': instance.uuid,
      'timestamp': instance.timestamp?.toIso8601String(),
      'number': instance.number?.toJson(),
      'aggregates': instance.aggregates == null
          ? null
          : toAggregateRootsJson(instance.aggregates)
    };
