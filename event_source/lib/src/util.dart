import 'dart:collection';

import 'package:json_patch/json_patch.dart';
import 'package:json_path/json_path.dart';
import 'package:collection_x/collection_x.dart';

bool isEmptyOrNull(value) => emptyAsNull(value) == null;

T emptyAsNull<T>(T value) => value is String
    ? (value.isNotEmpty == true ? value : null)
    : (value is Iterable ? (value.isNotEmpty == true ? value : null) : value);

/// Sort map on keys.
Map<K, V> sortMapKeys<K, V>(Map<K, V> map, {int Function(K a, K b) compare}) {
  final keys = map.keys.toList(growable: false);
  compare ??= (K a, K b) => '$a'.compareTo('$b');
  keys.sort((k1, k2) => compare(k1, k2));
  // ignore: prefer_collection_literals
  final sortedMap = LinkedHashMap<K, V>();
  keys.forEach((k1) {
    sortedMap[k1] = map[k1];
  });
  return sortedMap;
}

/// Sort map on values.
Map<K, V> sortMapValues<K, V>(Map<K, V> map, {int Function(V a, V b) compare}) {
  final keys = map.keys.toList(growable: false);
  compare ??= (V a, V b) => '$a'.compareTo('$b');
  keys.sort((k1, k2) => compare(map[k1], map[k2]));
  // ignore: prefer_collection_literals
  final sortedMap = LinkedHashMap<K, V>();
  keys.forEach((k1) {
    sortedMap[k1] = map[k1];
  });
  return sortedMap;
}

class JsonUtils {
  static const ops = ['add', 'remove', 'replace', 'move'];

  Iterable<T> added<T>(List<Map<String, dynamic>> patches, Pattern path) => _select<T>(patches, 'add', path);
  Iterable<T> moved<T>(List<Map<String, dynamic>> patches, Pattern path) => _select<T>(patches, 'move', path);
  Iterable<T> removed<T>(List<Map<String, dynamic>> patches, Pattern path) => _select<T>(patches, 'remove', path);
  Iterable<T> replaced<T>(List<Map<String, dynamic>> patches, Pattern path) => _select<T>(patches, 'replace', path);

  Iterable<T> _select<T>(List<Map<String, dynamic>> patches, String op, Pattern path) => patches
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
  /// in [newJson] should be updated, keeping
  /// the rest unchanged.
  ///
  static List<Map<String, dynamic>> diff(
    dynamic oldJson,
    dynamic newJson, {
    bool appendOnly = true,
  }) {
    final patches = JsonPatch.diff(oldJson, newJson);
    if (appendOnly) {
      patches.removeWhere(
        (diff) {
          var isRemove = diff['op'] == 'remove';
          if (isRemove) {
            final elements = (diff['path'] as String).split('/');
            if (elements.length > 1) {
              // Get path to list by removing index
              final path = elements.take(elements.length - 1).join('/');
              if (oldJson is Map && path.isNotEmpty) {
                final value = oldJson.elementAt(path);
                isRemove = value is! List;
              }
            }
          }
          return isRemove;
        },
      );
    }
    // HACK: JsonPatch started to
    // return list patches in
    // reverse order in version
    // 2.1.0
    return patches.reversed.toList();
  }

  static Map<String, dynamic> apply(Map<String, dynamic> data, List<Map<String, dynamic>> patches) => data == null
      ? <String, dynamic>{}
      : JsonPatch.apply(
          data,
          patches,
          strict: false,
        ) as Map<String, dynamic>;

  static String toQueryRoot(String query, [RegExpMatch match]) {
    match ??= RegExp(r'(\$?.{1,2}.*)\[\?.*\]').firstMatch(query);
    if (match == null) {
      return '';
    }
    return match.group(1);
  }

  // If number - use g4 | g5, g6 and g7 should be null
  // If string - use g5 | g6 and g7 should be null
  // If regexp - use g6 | g5 and g7 should be null
  // If script - use g7 | g5 and g6 should be null (g8 = name, g9 = value)
  static const _regex = r'(\$?.{1,2}.*)'
      r'\[\?\(\s*\@\.(\w*)\s*([><]?|==|!=|<=|>=|=~)'
      r"\s*([-.\d]*|\'(.*)\'|(\/[^!=<>~'].*)|((\w+)\s*(.*)))\s*\)\s*\]";

  static RegExpMatch matchQuery(String query) => RegExp(_regex).firstMatch(query);

  static Map<String, dynamic> toNamedArgs(
    RegExpMatch match, [
    dynamic Function(String name, String value) map,
  ]) {
    final args = <String, dynamic>{};
    if (match != null) {
      final g5 = match.group(5);
      final g6 = match.group(6);
      final g7 = match.group(7);
      // If script, use it as operand
      final name = g5 == null && g6 == null && g7 != null ? match.group(8) : match.group(3);
      // Number comparison
      args[toNamedFilter(name)] = {
        'name': match.group(2),
        if (g5 == null && g6 == null && g7 == null)
          // Number
          'value': num.parse(match.group(4))
        else if (g5 != null && g6 == null && g7 == null)
          // String
          'value': match.group(5)
        else if (g5 == null && g6 != null && g7 == null)
          // Regex
          'value': match.group(6)
        else
          // Regex
          'value': map == null
              ? match.group(9)
              : map(
                  name,
                  match.group(9),
                ),
      };
    }
    return args;
  }

  static String toNamedQuery(String query, RegExpMatch match) {
    if (match == null) {
      return query;
    }
    // If script, use it as operand
    final isScript = match.group(5) == null && match.group(6) == null && match.group(7) != null;
    final op = isScript ? match.group(8) : match.group(3);
    return '${match.group(1)}[?${toNamedFilter(op)}]';
  }

  static Map<String, Predicate> toNamedFilters(Map<String, dynamic> args) => {
        if (args.hasPath('eq'))
          'eq': (e) => _eval(
                e,
                args,
                'eq',
                (v1, v2) => v1 == v2,
              ),
        if (args.hasPath('ne'))
          'ne': (e) => _eval(
                e,
                args,
                'ne',
                (v1, v2) => v1 != v2,
              ),
        if (args.hasPath('le'))
          'le': (e) => _eval(
                e,
                args,
                'le',
                (v1, v2) => v1 is num && v2 is num ? v1 <= v2 : '$v1'.compareTo('$v2') <= 0,
              ),
        if (args.hasPath('ge'))
          'ge': (e) => _eval(
                e,
                args,
                'ge',
                (v1, v2) => v1 is num && v2 is num ? v1 >= v2 : '$v1'.compareTo('$v2') >= 0,
              ),
        if (args.hasPath('lt'))
          'lt': (e) => _eval(
                e,
                args,
                'lt',
                (v1, v2) => v1 is num && v2 is num ? v1 < v2 : '$v1'.compareTo('$v2') < 0,
              ),
        if (args.hasPath('gt'))
          'gt': (e) => _eval(
                e,
                args,
                'gt',
                (v1, v2) => v1 is num && v2 is num ? v1 > v2 : '$v1'.compareTo('$v2') > 0,
              ),
        if (args.hasPath('rx'))
          'rx': (e) => _eval(
                e,
                args,
                'rx',
                (v1, v2) {
                  final parts = '$v2'.split('/');
                  final query = parts.length > 1 ? parts[1] : '$v2';
                  final options = parts.length > 2 ? parts[2] : '';
                  return RegExp(
                        query,
                        dotAll: options.contains('g'),
                        multiLine: options.contains('m'),
                        caseSensitive: !options.contains('i'),
                      ).firstMatch('$v1') !=
                      null;
                },
              ),
      };

  static bool _eval(
    dynamic e,
    Map<String, dynamic> args,
    String operator,
    bool Function(dynamic v1, dynamic v2) test,
  ) {
    final name = args.elementAt('$operator/name');
    final value = args.elementAt('$operator/value');
    if (name != null && e is Map) {
      return test(e[name], value);
    }
    if (e is List) {
      return e.any((e) {
        if (e is Map) {
          return name != null && test(e[name], value);
        }
        return test(e[name], value);
      });
    }
    return false;
  }

  static String toNamedFilter(String operator) {
    switch (operator) {
      case '==':
        return 'eq';
      case '!=':
        return 'ne';
      case '<=':
        return 'le';
      case '>=':
        return 'ge';
      case '<':
        return 'lt';
      case '>':
        return 'gt';
      case '=~':
        return 'rx';
      default:
        return operator;
    }
  }
}
