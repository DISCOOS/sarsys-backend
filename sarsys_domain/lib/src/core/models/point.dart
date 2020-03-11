import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:sarsys_domain/src/core/models/coordinates.dart';

part 'point.g.dart';

@JsonSerializable(explicitToJson: true)
class PointModel extends Equatable {
  PointModel({
    @required this.coordinates,
  }) : super();

  @JsonKey(ignore: true)
  double get lat => coordinates.lat;

  @JsonKey(ignore: true)
  double get lon => coordinates.lon;

  @JsonKey(ignore: true)
  double get alt => coordinates.alt;

  final String type = 'Point';

  @JsonKey(fromJson: _coordsFromJson, toJson: _coordsToJson)
  final CoordinatesModel coordinates;

  @override
  List<Object> get props => [type, coordinates];

  bool get isEmpty => coordinates.isEmpty;
  bool get isNotEmpty => !isEmpty;

  /// Factory constructor for creating a new `Point`  instance
  factory PointModel.fromJson(Map<String, dynamic> json) => _$PointModelFromJson(json);

  /// Declare support for serialization to JSON
  Map<String, dynamic> toJson() => _$PointModelToJson(this);
}

CoordinatesModel _coordsFromJson(List json) => CoordinatesModel.fromJson(json);
dynamic _coordsToJson(CoordinatesModel coords) => coords.toJson();
