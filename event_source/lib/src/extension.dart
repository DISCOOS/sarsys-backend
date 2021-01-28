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
  T elementAt<T>(String path, {String delimiter = '/', T defaultValue}) {
    final parts = path.split(delimiter);
    dynamic found = parts.skip(parts.first.isEmpty ? 1 : 0).fold(this, (parent, name) {
      if (parent is Map<String, dynamic>) {
        if (parent.containsKey(name)) {
          return parent[name];
        }
      }
      final element = (parent ?? {});
      final index = int.tryParse(name);
      return element is Map
          ? element[name]
          : element is List && element.isNotEmpty && index != null && index >= 0 && index < element.length
              ? element[index]
              : defaultValue;
    });
    return (found ?? defaultValue) as T;
  }

  /// Get [List] of type [T] at given path
  List<T> listAt<T>(String path, {List<T> defaultList}) {
    final list = elementAt(path);
    return list == null ? defaultList : List<T>.from(list as List);
  }

  /// Get [Map] with keys of type [S] and values of type [T] at given path
  Map<S, T> mapAt<S, T>(String path, {Map<S, T> defaultMap}) {
    final map = elementAt(path);
    return map == null ? defaultMap : Map<S, T>.from(map as Map);
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
  T get lastOrNull => isNotEmpty ? last : null;
}

extension LoggerX on Logger {
  static const CONNECTION_ERRORS = [
    'ClientException',
    'SocketException',
    'os error: connection refused',
    'connection closed before full header was received',
  ];

  /// Decide between [Level.WARNING] and [Level.SEVERE]
  void network(Object message, Object error, StackTrace stackTrace) {
    final type = '${error.runtimeType}';
    final match = '$error'.toLowerCase();
    log(
      CONNECTION_ERRORS.any((test) => match.startsWith(test) || type.startsWith(test)) ? Level.WARNING : Level.SEVERE,
      message,
      error,
      stackTrace,
    );
  }
}
