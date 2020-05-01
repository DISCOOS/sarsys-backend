import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:sarsys_domain/src/core/models/coordinates.dart';
import 'package:sarsys_domain/src/core/models/point.dart';
import 'package:sarsys_domain/src/core/models/source.dart';

part 'position.g.dart';

@JsonSerializable(explicitToJson: true)
class PositionModel extends Equatable {
  PositionModel({
    @required this.geometry,
    @required this.properties,
  }) : super();

  final PointModel geometry;
  final PositionModelProps properties;
  final String type = 'Feature';

  @JsonKey(ignore: true)
  double get lat => geometry.lat;

  @JsonKey(ignore: true)
  double get lon => geometry.lon;

  @JsonKey(ignore: true)
  double get alt => geometry.alt;

  @JsonKey(ignore: true)
  double get acc => properties.acc;

  @JsonKey(ignore: true)
  PositionSource get source => properties.source;

  @JsonKey(ignore: true)
  DateTime get timestamp => properties.timestamp;

  @override
  List<Object> get props => [
        geometry,
        properties,
        type,
      ];

  bool get isEmpty => geometry.isEmpty;
  bool get isNotEmpty => !isEmpty;

  /// Factory constructor for [PositionModel]
  factory PositionModel.from({
    @required double lat,
    @required double lon,
    @required PositionSource source,
    @required DateTime timestamp,
    double acc,
    double alt,
  }) =>
      PositionModel(
        geometry: PointModel(
          coordinates: CoordinatesModel(
            lat: lat,
            lon: lon,
            alt: alt,
          ),
        ),
        properties: PositionModelProps(
          acc: acc,
          source: source,
          timestamp: timestamp ?? DateTime.now(),
        ),
      );

  /// Factory constructor for creating a new `Point`  instance
  factory PositionModel.fromJson(Map<String, dynamic> json) => _$PositionModelFromJson(json);

  /// Declare support for serialization to JSON
  Map<String, dynamic> toJson() => _$PositionModelToJson(this);

  PositionModel cloneWith({
    double lat,
    double lon,
    double acc,
    double alt,
    SourceType source,
    DateTime timestamp,
  }) =>
      PositionModel.from(
        lat: lat ?? this.lat,
        lon: lon ?? this.lon,
        alt: alt ?? this.alt,
        acc: acc ?? this.acc,
        source: source ?? this.source,
        timestamp: timestamp ?? this.timestamp,
      );
}

enum PositionSource { manual, device, aggregate }

@JsonSerializable(explicitToJson: true)
class PositionModelProps extends Equatable {
  @JsonKey(name: 'accuracy')
  final double acc;
  final DateTime timestamp;
  final PositionSource source;

  PositionModelProps({
    @required this.acc,
    @required this.timestamp,
    this.source = PositionSource.manual,
  }) : super();

  @override
  List<Object> get props => [
        acc,
        timestamp,
        source,
      ];

  /// Factory constructor for creating a new `Point`  instance
  factory PositionModelProps.fromJson(Map<String, dynamic> json) => _$PositionModelPropsFromJson(json);

  /// Declare support for serialization to JSON
  Map<String, dynamic> toJson() => _$PositionModelPropsToJson(this);

  PositionModelProps cloneWith({
    double acc,
    SourceType source,
    DateTime timestamp,
  }) =>
      PositionModelProps(
        acc: acc ?? this.acc,
        source: source ?? this.source,
        timestamp: timestamp ?? this.timestamp,
      );
}
