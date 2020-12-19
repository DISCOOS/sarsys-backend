// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'point.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PointModel _$PointModelFromJson(Map json) {
  return PointModel(
    coordinates: _coordsFromJson(json['coordinates'] as List),
  );
}

Map<String, dynamic> _$PointModelToJson(PointModel instance) =>
    <String, dynamic>{
      'coordinates': _coordsToJson(instance.coordinates),
    };
