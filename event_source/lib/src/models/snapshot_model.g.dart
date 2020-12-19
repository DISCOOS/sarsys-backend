// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'snapshot_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SnapshotModel _$SnapshotModelFromJson(Map json) {
  return SnapshotModel(
    uuid: json['uuid'] as String,
    number: json['number'] == null
        ? null
        : EventNumberModel.fromJson((json['number'] as Map)?.map(
            (k, e) => MapEntry(k as String, e),
          )),
    timestamp: json['timestamp'] == null
        ? null
        : DateTime.parse(json['timestamp'] as String),
    aggregates: fromAggregateRootsJson(json['aggregates']),
  );
}

Map<String, dynamic> _$SnapshotModelToJson(SnapshotModel instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('uuid', instance.uuid);
  writeNotNull('timestamp', instance.timestamp?.toIso8601String());
  writeNotNull('number', instance.number?.toJson());
  writeNotNull('aggregates', toAggregateRootsJson(instance.aggregates));
  return val;
}
