import 'dart:collection';
import 'dart:math';

import 'package:latlong2/latlong.dart';
import 'package:json_path/json_path.dart';
import 'package:collection_x/collection_x.dart';

import 'package:sarsys_core/sarsys_core.dart';

class JsonQuery {
  JsonQuery._({
    @required this.pattern,
    @required this.dataRoot,
    @required this.jsonPath,
    @required this.queryArgs,
    @required this.queryMatch,
    @required this.namedQuery,
    @required this.customFilter,
    @required this.defaultFilter,
  });

  factory JsonQuery.from(pattern) {
    QueryUtils.pruneQueryCache();
    return QueryUtils._queryCache.update(pattern, (query) => query, ifAbsent: () {
      final queryMatch = JsonUtils.matchQuery(pattern);
      final namedQuery = JsonUtils.toNamedQuery(pattern, queryMatch);
      final queryArgs = JsonUtils.toNamedArgs(queryMatch, QueryUtils.toCustomArgs);
      final customFilter = QueryUtils.toCustomFilter(queryArgs);
      final defaultFilter = JsonUtils.toNamedFilters(queryArgs);
      return JsonQuery._(
        pattern: pattern,
        jsonPath: JsonPath(
          namedQuery,
          filter: {
            ...defaultFilter,
            ...customFilter,
          },
        ),
        queryArgs: queryArgs,
        namedQuery: namedQuery,
        queryMatch: queryMatch,
        customFilter: customFilter,
        defaultFilter: defaultFilter,
        dataRoot: JsonUtils.toQueryRoot(pattern),
      );
    });
  }

  final String pattern;
  final String dataRoot;
  final String namedQuery;
  final JsonPath jsonPath;
  final RegExpMatch queryMatch;
  final Map<String, dynamic> queryArgs;
  final Map<String, Predicate> customFilter;
  final Map<String, Predicate> defaultFilter;

  bool get queryAll => dataRoot.contains('..');

  bool isMatch(Map<String, dynamic> data) {
    final matches = jsonPath.read({
      // Only include if search is recursive or root matches object
      if (queryAll || dataRoot.contains('data')) 'data': data,
    });
    return matches.isNotEmpty;
  }
}

class QueryUtils {
  static final _customArgs = LinkedHashMap.from(<String, dynamic>{});
  static final _queryCache = LinkedHashMap.from(<String, dynamic>{});

  static void clearQueryCache() => _queryCache.clear();
  static void clearCustomArgsCache() => _customArgs.clear();

  static void pruneQueryCache({int maxLength = 100}) {
    while (_queryCache.length > max(0, maxLength)) {
      _queryCache.remove(_queryCache.keys.first);
    }
  }

  static void pruneCustomArgsCache({int maxLength = 100}) {
    while (_customArgs.length > max(0, maxLength)) {
      _customArgs.remove(_customArgs.keys.first);
    }
  }

  static bool isMatch(String pattern, Map<String, dynamic> data) => JsonQuery.from(pattern).isMatch(data);

  static Map<String, Predicate> toCustomFilter(Map<String, dynamic> args) {
    final filter = <String, Predicate>{};
    for (var name in args.keys) {
      switch (name) {
        case 'within':
          filter.addAll({
            'within': (data) => isWithin(args['within'] as Map<String, dynamic>, data),
          });
          break;
      }
    }
    return filter;
  }

  static bool isWithin(Map<String, dynamic> args, dynamic data) {
    if (data is Map) {
      final coords = data.elementAt(args['name'], delimiter: '.');
      if (coords is List) {
        const distance = Distance();
        final value = args['value'];
        final km = distance.as(
          LengthUnit.Kilometer,
          LatLng(coords[0] as double, coords[1] as double),
          value['center'] as LatLng,
        );
        return km <= (value['radius'] as double);
      }
    }
    return false;
  }

  static dynamic toCustomArgs(String name, String value) {
    pruneCustomArgsCache();
    switch (name) {
      case 'within':
        return _customArgs.update('$name $value', (args) => args, ifAbsent: () {
          final parts = value.toLowerCase().split(';');
          final args1 = parts[1].split('=').map((s) => s.trim().toLowerCase()).toList();
          final args2 = parts[2].split('=').map((s) => s.trim().toLowerCase()).toList();
          final radius = args1[0].startsWith('r') ? args1[1] : args2[1];
          final center = args2[0].startsWith('c') ? args2[1] : args1[1];
          final coords = center.substring(1, center.length - 2).split(',');
          return {
            'geometry': parts[0],
            'radius': double.parse(radius),
            'center': LatLng(
              double.parse(coords[0]),
              double.parse(coords[1]),
            ),
          };
        });
      default:
        return value;
    }
  }
}
