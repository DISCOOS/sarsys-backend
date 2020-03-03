// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'point.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PointModel _$PointModelFromJson(Map<String, dynamic> json) {
  return PointModel(
      coordinates: json['coordinates'] == null
          ? null
          : PointModel._coordsFromJson(json['coordinates'] as Map));
}

Map<String, dynamic> _$PointModelToJson(PointModel instance) =>
    <String, dynamic>{
      'coordinates': instance.coordinates == null
          ? null
          : PointModel._coordsToJson(instance.coordinates)
    };
