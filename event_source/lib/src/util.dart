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
}
