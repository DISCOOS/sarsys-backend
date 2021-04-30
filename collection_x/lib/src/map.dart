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
    if (found is String) {
      switch (T) {
        case int:
          found = int.parse(
            found.toString(),
          );
          break;
        case double:
          found = double.parse(
            found.toString(),
          );
          break;
        case DateTime:
          found = DateTime.parse(
            found.toString(),
          );
          break;
        case Duration:
          found = Duration(
            milliseconds: int.parse(found.toString()),
          );
          break;
      }
    }
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

  /// Joint elements at given paths as string
  String jointAt<T>(List<String> paths, {String separator = '', T defaultValue}) => paths
      .map((path) => elementAt(path, defaultValue: defaultValue)?.toString())
      .where((e) => e != null)
      .join(separator);
}
