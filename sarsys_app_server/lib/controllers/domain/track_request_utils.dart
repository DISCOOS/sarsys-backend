import 'package:collection_x/collection_x.dart';
import 'package:event_source/event_source.dart';

class TrackRequestUtils {
  static Map<String, dynamic> toTrack(
    Map<String, dynamic> track,
    String expand,
    List<String> options,
  ) {
    final tracks = _shouldFilter(expand) ? _filter([track]) : [track];
    final parsed = toOptions(options);
    if (parsed.containsKey('truncate')) {
      final option = parsed['truncate'];
      final truncate = option.split(':');
      if (truncate.length != 2) {
        throw const InvalidOperation(
          "Option has format 'truncate:{value}:{unit}'",
        );
      }
      final value = int.parse(truncate[0]);
      final unit = truncate[1];
      return TrackRequestUtils.truncate(
        tracks.first,
        value,
        unit,
      );
    }
    return tracks.first;
  }

  static List<Map<String, dynamic>> toTracks(
    EntityArray array,
    String expand,
    List<String> options,
  ) {
    final parsed = TrackRequestUtils.toOptions(options);
    final tracks = _shouldFilter(expand) ? _filter(array.toList()) : array.toList();
    if (parsed.containsKey('truncate')) {
      final option = parsed['truncate'];
      final truncate = option.split(':');
      if (truncate.length != 2) {
        throw const InvalidOperation(
          "Option has format 'truncate:{value}:{unit}'",
        );
      }
      final value = int.parse(truncate[0]);
      final unit = truncate[1];
      return tracks.map((t) => TrackRequestUtils.truncate(t, value, unit)).toList();
    }
    return tracks;
  }

  static bool _shouldFilter(String expand) {
    final elements = expand?.split(',') ?? <String>[];
    if (elements.any((element) => element.toLowerCase() == 'positions')) {
      return false;
    }
    if (elements.isNotEmpty) {
      throw "Invalid query parameter 'expand' values: $expand";
    }
    return true;
  }

  static List<Map<String, dynamic>> _filter(List<Map<String, dynamic>> array) {
    return array.map((track) => track..remove('positions')).toList();
  }

  static Map<String, dynamic> truncate(
    Map<String, dynamic> track,
    int value,
    String unit,
  ) {
    switch (unit) {
      case 'p':
        return truncateCount(track, value);
      case 'm':
        return truncateMinutes(track, value);
      case 'h':
        return truncateMinutes(track, value * 60);
      default:
        throw InvalidOperation(
          "Option 'truncate' does not support unit '$unit'",
        );
    }
  }

  static Map<String, dynamic> truncateCount(Map<String, dynamic> track, int value) {
    if (track.hasPath('positions')) {
      final positions = List<Map<String, dynamic>>.from(track['positions'] as List);
      if (positions.length > value.abs()) {
        final truncated = Map<String, dynamic>.from(track);
        truncated['positions'] = value < 0
            // Truncate from head
            ? positions.sublist(positions.length + value, positions.length)
            // Truncate from tail
            : positions.sublist(0, value);

        return truncated;
      }
    }
    return track;
  }

  static Map<String, dynamic> truncateMinutes(Map<String, dynamic> track, int value) {
    if (track.hasPath('positions')) {
      var positions = List<Map<String, dynamic>>.from(track['positions'] as List);
      if (positions.isNotEmpty) {
        if (value < 0) {
          positions = positions.reversed.toList();
        }
        final first = positions.firstWhere(
          (p) => p.hasPath("properties/timestamp"),
        );
        if (first == null) {
          return Map<String, dynamic>.from(track)
            ..addAll(
              {'positions': []},
            );
        } else {
          final from = DateTime.parse(
            first.elementAt<String>("properties/timestamp"),
          );
          final diff = Duration(minutes: value.abs());
          final truncated = positions.where((p) {
            final ts = p.elementAt<String>("properties/timestamp");
            return ts?.isNotEmpty == true && DateTime.parse(ts).difference(from).abs() <= diff;
          }).toList();
          return Map<String, dynamic>.from(track)
            ..addAll(
              {'positions': value < 0 ? truncated.reversed.toList() : truncated},
            );
        }
      }
    }
    return track;
  }

  static Map<String, String> toOptions(List<String> options) {
    return Map.fromEntries(options.map((option) {
      final elements = option.split(':');
      return MapEntry(
        elements[0].toLowerCase(),
        elements.sublist(1).join(':').toLowerCase(),
      );
    }));
  }
}
