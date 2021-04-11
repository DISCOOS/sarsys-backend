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
    return '${this}'
        .split(RegExp('(?<=[a-z0-9])(?=[A-Z0-9])'))
        .join(delimiter)
        .toLowerCase();
  }
}

extension PageableX<T> on Iterable<T> {
  Iterable<T> toPage({
    int offset = 0,
    int limit = 20,
  }) {
    if (offset < 0 || limit < 0) {
      throw const InvalidOperation('Offset and limit can not be negative');
    } else if (offset > length) {
      throw InvalidOperation(
          'Index out of bounds: offset $offset > length $length');
    } else if (offset == 0 && limit == 0) {
      return toList();
    }
    return skip(offset).take(limit);
  }
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
      CONNECTION_ERRORS
              .any((test) => match.startsWith(test) || type.startsWith(test))
          ? Level.WARNING
          : Level.SEVERE,
      message,
      error,
      stackTrace,
    );
  }
}
