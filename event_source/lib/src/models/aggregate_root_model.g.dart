// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'aggregate_root_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AggregateRootModel _$AggregateRootModelFromJson(Map json) {
  return AggregateRootModel(
      uuid: json['uuid'],
      data: json['data'] == null ? null : toMapJson(json['data']),
      number: json['number'] == null
          ? null
          : EventNumberModel.fromJson((json['number'] as Map)?.map(
              (k, e) => MapEntry(k as String, e),
            )),
      createdBy: json['createdBy'] == null
          ? null
          : fromEventModelJson(json['createdBy']),
      changedBy: json['changedBy'] == null
          ? null
          : fromEventModelJson(json['changedBy']),
      deletedBy: json['deletedBy'] == null
          ? null
          : fromEventModelJson(json['deletedBy']));
}

Map<String, dynamic> _$AggregateRootModelToJson(AggregateRootModel instance) =>
    <String, dynamic>{
      'uuid': instance.uuid,
      'createdBy': instance.createdBy == null
          ? null
          : toEventModelJson(instance.createdBy),
      'changedBy': instance.changedBy == null
          ? null
          : toEventModelJson(instance.changedBy),
      'deletedBy': instance.deletedBy == null
          ? null
          : toEventModelJson(instance.deletedBy),
      'number': instance.number?.toJson(),
      'data': instance.data == null ? null : toMapJson(instance.data)
    };
