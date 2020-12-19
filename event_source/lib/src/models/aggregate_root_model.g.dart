// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'aggregate_root_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AggregateRootModel _$AggregateRootModelFromJson(Map json) {
  return AggregateRootModel(
    uuid: json['uuid'] as String,
    data: toMapJson(json['data'] as Map),
    number: json['number'] == null
        ? null
        : EventNumberModel.fromJson((json['number'] as Map)?.map(
            (k, e) => MapEntry(k as String, e),
          )),
    createdBy: fromEventModelJson(json['createdBy']),
    changedBy: fromEventModelJson(json['changedBy']),
    deletedBy: fromEventModelJson(json['deletedBy']),
  );
}

Map<String, dynamic> _$AggregateRootModelToJson(AggregateRootModel instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('uuid', instance.uuid);
  writeNotNull('createdBy', toEventModelJson(instance.createdBy));
  writeNotNull('changedBy', toEventModelJson(instance.changedBy));
  writeNotNull('deletedBy', toEventModelJson(instance.deletedBy));
  writeNotNull('number', instance.number?.toJson());
  writeNotNull('data', toMapJson(instance.data));
  return val;
}
