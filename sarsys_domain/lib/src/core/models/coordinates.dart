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
        lat: latFromJson(json),
        lon: lonFromJson(json),
        alt: altFromJson(json),
      );

  /// Declare support for serialization to JSON.
  /// GeoJSON specifies longitude at index 0,
  /// latitude at index 1 and altitude at index 2,
  /// see https://tools.ietf.org/html/rfc7946#section-3.1.1
  List<double> toJson() => [lon, lat, if (alt != null) alt];
}

/// GeoJSON specifies longitude at index 0,
/// see https://tools.ietf.org/html/rfc7946#section-3.1.1
double lonFromJson(Object json) => _toDouble(json, 0);

/// GeoJSON specifies latitude at index 1,
/// see https://tools.ietf.org/html/rfc7946#section-3.1.1
double latFromJson(Object json) => _toDouble(json, 1);

/// GeoJSON specifies altitude at index 2,
/// see https://tools.ietf.org/html/rfc7946#section-3.1.1
double altFromJson(Object json) => _toDouble(json, 2);

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
