import 'package:logging/logging.dart';

import 'error.dart';

extension TypeX on Type {
  /// Convert [Type] into lower case string
  String toLowerCase() {
    return '${this}'.toLowerCase();
  }

  /// Convert [Type] into colon delimited lower case string
  String toColonCase() {
    return '${this}'.toColonCase();
  }

  /// Convert [Type] into kebab case string
  String toKebabCase() {
    return '${this}'.toKebabCase();
  }

  /// Convert [Type] into delimited lower case string
  String toDelimiterCase(String delimiter) {
    return '${this}'.toDelimiterCase(delimiter);
  }
}

extension StringX on String {
  /// Convert [String] into colon delimited lower case string
  String toColonCase() {
    return toDelimiterCase(':');
  }

  /// Convert [String] into kebab case string
  String toKebabCase() {
    return toDelimiterCase('-');
  }

  /// Convert [String] into delimited lower case string
  String toDelimiterCase(String delimiter) {
    return '${this}'.split(RegExp('(?<=[a-z0-9])(?=[A-Z0-9])')).join(delimiter).toLowerCase();
  }
}

extension MapX on Map {
  /// Check if map contains data at given path
  bool hasPath(String ref) => elementAt(ref) != null;

  /// Get element with given reference on format '/name1/name2/name3'
  /// equivalent to map['name1']['name2']['name3'].
  ///
  /// Returns [null] if not found
  T elementAt<T>(String path) {
    final parts = path.split('/');
    dynamic found = parts.skip(parts.first.isEmpty ? 1 : 0).fold(this, (parent, name) {
      if (parent is Map<String, dynamic>) {
        if (parent.containsKey(name)) {
          return parent[name];
        }
      }
      final element = (parent ?? {});
      return element is Map ? element[name] : element is List && element.isNotEmpty ? element[int.parse(name)] : null;
    });
    return found as T;
  }
}

extension IterableX<T> on Iterable<T> {
  Iterable<T> toPage({
    int offset = 0,
    int limit = 20,
  }) {
    if (offset < 0 || limit < 0) {
      throw const InvalidOperation('Offset and limit can not be negative');
    } else if (offset > length) {
      throw InvalidOperation('Index out of bounds: offset $offset > length $length');
    } else if (offset == 0 && limit == 0) {
      return toList();
    }
    return skip(offset).take(limit);
  }

  T get firstOrNull => isNotEmpty ? first : null;
}

extension LoggerX on Logger {
  static const CONNECTION_CLOSED = 'Connection closed before full header was received';

  /// Decide between [Level.WARNING] and [Level.SEVERE]
  void network(String message, Object error, StackTrace stackTrace) {
    final level = '$error'.contains(CONNECTION_CLOSED) ? Level.WARNING : Level.SEVERE;
    log(
      level,
      message,
      error,
      stackTrace,
    );
  }
}
