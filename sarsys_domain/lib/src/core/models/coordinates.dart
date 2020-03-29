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

  bool get isNotEmpty => !isEmpty;
  bool get isEmpty => _isEmpty(lat) || _isEmpty(lon);

  bool _isEmpty(double value) => value == 0 || value == null;

  /// Factory constructor for creating a new `Point`  instance
  factory CoordinatesModel.fromJson(List<dynamic> json) => CoordinatesModel(
        lat: _latFromJson(json),
        lon: _lonFromJson(json),
        alt: _altFromJson(json),
      );

  /// Declare support for serialization to JSON
  List<double> toJson() => [lat, lon, if (alt != null) alt];
}

double _latFromJson(Object json) => _toDouble(json, 0);
double _lonFromJson(Object json) => _toDouble(json, 1);
double _altFromJson(Object json) => _toDouble(json, 2);

double _toDouble(Object json, int index) {
  if (json is List) {
    if (index < json.length) {
      var value = json[index];
      if (value is num) {
        return value.toDouble();
      } else if (value is String) {
        return double.parse(value);
      }
    }
  }
  return null;
}
