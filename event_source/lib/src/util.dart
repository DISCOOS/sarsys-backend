import 'package:json_patch/json_patch.dart';
import 'extension.dart';

bool isEmptyOrNull(value) => emptyAsNull(value) == null;

T emptyAsNull<T>(T value) => value is String
    ? (value.isNotEmpty == true ? value : null)
    : (value is Iterable ? (value.isNotEmpty == true ? value : null) : value);

class JsonUtils {
  static const ops = ['add', 'remove', 'replace', 'move'];

  Iterable<T> added<T>(List<Map<String, dynamic>> patches, Pattern path) => _select<T>(patches, 'add', path);
  Iterable<T> moved<T>(List<Map<String, dynamic>> patches, Pattern path) => _select<T>(patches, 'move', path);
  Iterable<T> removed<T>(List<Map<String, dynamic>> patches, Pattern path) => _select<T>(patches, 'remove', path);
  Iterable<T> replaced<T>(List<Map<String, dynamic>> patches, Pattern path) => _select<T>(patches, 'replace', path);

  Iterable _select<T>(List<Map<String, dynamic>> patches, String op, Pattern path) => patches
      .where((patch) => patch['op'] == op)
      .where((patch) => patch['path'] == (patch['path'] as String).startsWith(path))
      .map((patch) => patch['value'])
      .cast<T>();

  /// Calculate key-stable patches enforcing
  /// a 'append-only' rule for keys and
  /// replace-only for arrays (remove are
  /// only allowed for arrays).
  ///
  /// This is important to allow for partial
  /// updates to an existing object that is
  /// semantically consistent with the HTTP
  /// PATCH method by only including keys
  /// in [next] should be updated, keeping
  /// the rest unchanged.
  ///
  static List<Map<String, dynamic>> diff(
    Map<String, dynamic> current,
    Map<String, dynamic> next,
  ) {
    final patches = JsonPatch.diff(current, next)
      ..removeWhere(
        (diff) {
          var isRemove = diff['op'] == 'remove';
          if (isRemove) {
            final elements = (diff['path'] as String).split('/');
            if (elements.length > 1) {
              // Get path to list by removing index
              final path = elements.take(elements.length - 1).join('/');
              if (path.isNotEmpty) {
                final value = current.elementAt(path);
                isRemove = value is! List;
              }
            }
          }
          return isRemove;
        },
      );
    return patches;
  }

  static Map<String, dynamic> apply(Map<String, dynamic> data, List<Map<String, dynamic>> patches) => data == null
      ? null
      : JsonPatch.apply(
          data,
          patches,
          strict: false,
        ) as Map<String, dynamic>;
}
