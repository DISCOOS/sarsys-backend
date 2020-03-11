import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

class CoordinatesModel extends Equatable {
  CoordinatesModel({
    @required this.lat,
    @required this.lon,
    this.alt,
  }) : super();

  final double lat;
  final double lon;
  final double alt;

  @override
  List<Object> get props => [
        lat,
        lon,
        alt,
      ];

  bool get isEmpty => lat == 0 && lon == 0;
  bool get isNotEmpty => !isEmpty;

  /// Factory constructor for creating a new `Point`  instance
  factory CoordinatesModel.fromJson(List<dynamic> json) => CoordinatesModel(
        lat: _latFromJson(json),
        lon: _lonFromJson(json),
        alt: _altFromJson(json),
      );

  /// Declare support for serialization to JSON
  List<double> toJson() => [lat, lon, if (alt != null) alt];
}

double _latFromJson(Object json) => (json as List)[0];
double _lonFromJson(Object json) => (json as List)[1];
double _altFromJson(Object json) => (json as List).length > 2 ? (json as List)[2] : null;
