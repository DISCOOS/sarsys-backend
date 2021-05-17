import 'package:event_source/event_source.dart';
import 'package:json_path/json_path.dart';
import 'package:test/test.dart';

void main() {
  test('Search for value of type int correctly', () {
    _testSearchNumber<int>(1234);
  });

  test('Search for value of type double correctly', () {
    _testSearchNumber<double>(-1234.5);
  });

  test('Search for value of type String correctly', () {
    final path = '..';
    final value = '-1234.0';
    final data = {'price': value};
    final ops = {
      '>': false,
      '<': false,
      '==': true,
      '!=': false,
      '>=': true,
      '<=': true,
    };
    for (var op in ops.entries) {
      // Arrange
      final query = "$path[?(@.price${op.key}'$value')]";

      // Act
      final match = JsonUtils.matchQuery(query);
      final named = JsonUtils.toNamedQuery(query, match);
      final args = JsonUtils.toNamedArgs(match);
      final name = JsonUtils.toNamedFilter(op.key);

      // Assert
      expect(
        match,
        isNotNull,
        reason: "should parse '$query'",
      );

      expect(match.groupCount, 9);
      expect(match.group(0), query);
      expect(match.group(1), path);
      expect(match.group(2), 'price');
      expect(match.group(3), op.key);
      expect(match.group(4), "'$value'");
      expect(match.group(5), value);

      // On string, group 6 should be null
      expect(match.group(6), isNull);

      // Check named parts
      expect(named, contains('$path[?$name]'));
      expect(args[name], isA<Map>());
      expect(args[name]['name'], 'price');
      expect(args[name]['value'], isA<String>());
      expect(args[name]['value'], value);

      // Check search result
      final result = JsonPath(
        named,
        filter: JsonUtils.toNamedFilters(args),
      ).read(data);
      expect(
        result.isNotEmpty,
        op.value,
        reason: 'Expected a match for ${op.key}',
      );
      if (op.value) {
        expect(result.length, 1);
        expect(result.first.path, '\$');
        expect((result.first.value as Map)['price'], value);
      }
    }
  });

  test('Search for value with regex correctly', () {
    final path = r'$';
    final values = <String, Map<String, dynamic>>{
      r'/[\d]*/igm': {'value': 1234, 'match': true},
      r'/[-.\d]*/igm': {'value': -1234.5, 'match': true},
      '/.*/igm': {'value': '-1234.5', 'match': true},
      '/abcd/': {'value': 'abcd', 'match': true},
      '/abcd/m': {'value': '1234\nABCD', 'match': false},
      '/abcd/im': {'value': '1234\nABCD', 'match': true},
    };
    final op = '=~';
    for (var rx in values.entries) {
      // Arrange
      final query = '$path[?(@.price=~${rx.key})]';

      // Act
      final match = JsonUtils.matchQuery(query);
      final named = JsonUtils.toNamedQuery(query, match);
      final args = JsonUtils.toNamedArgs(match);
      final name = JsonUtils.toNamedFilter(op);

      // Assert
      expect(
        match,
        isNotNull,
        reason: "should parse '$query'",
      );
      expect(match.groupCount, 9);
      expect(match.group(0), query);
      expect(match.group(1), path);
      expect(match.group(2), 'price');
      expect(match.group(3), op);
      expect(match.group(4), rx.key);
      expect(match.group(6), rx.key);

      // On regex, group 5 should be null
      expect(match.group(5), isNull);

      // Check named parts
      expect(named, contains('$path[?$name]'));
      expect(args[name], isA<Map>());
      expect(args[name]['name'], 'price');
      expect(args[name]['value'], isA<String>());
      expect(args[name]['value'], rx.key);

      // Check search result
      final result = JsonPath(
        named,
        filter: JsonUtils.toNamedFilters(args),
      ).read({
        'price': rx.value['value'],
      });
      final shouldMatch = rx.value['match'] as bool;
      expect(
        result.isNotEmpty,
        shouldMatch,
        reason: 'Expected a match for ${rx.key}',
      );
      expect(
        result.length,
        shouldMatch ? 1 : 0,
      );
      if (shouldMatch) {
        expect(result.first.path, '\$');
        expect(
          (result.first.value as Map)['price'],
          rx.value['value'],
        );
      }
    }
  });
}

void _testSearchNumber<T extends num>(T value) {
  final property = 'object';
  final path = '..$property';
  final data = {
    'object': {'price': value}
  };
  final ops = {
    '>': false,
    '<': false,
    '==': true,
    '!=': false,
    '>=': true,
    '<=': true,
  };

  // Arrange
  for (var op in ops.entries) {
    final query = '$path[?(@.price${op.key}$value)]';

    // Act
    final match = JsonUtils.matchQuery(query);
    final named = JsonUtils.toNamedQuery(query, match);
    final args = JsonUtils.toNamedArgs(match);
    final name = JsonUtils.toNamedFilter(op.key);

    // Assert
    expect(
      match,
      isNotNull,
      reason: "should parse '$query'",
    );

    expect(match.groupCount, 9);
    expect(match.group(0), query);
    expect(match.group(1), path);
    expect(match.group(2), 'price');
    expect(match.group(3), op.key);
    expect(num.tryParse(match.group(4)), value);

    // On number, group 5 and 6 should be null
    expect(match.group(5), isNull);
    expect(match.group(6), isNull);

    // Check named parts
    expect(named, contains('$path[?$name]'));
    expect(args[name], isA<Map>());
    expect(args[name]['name'], 'price');
    expect(args[name]['value'], isA<T>());
    expect(args[name]['value'], value);

    // Check search result
    final result = JsonPath(
      named,
      filter: JsonUtils.toNamedFilters(args),
    ).read(data);
    expect(
      result.isNotEmpty,
      op.value,
      reason: 'Expected a match for ${op.key}',
    );
    if (op.value) {
      expect(result.length, 1);
      expect(result.first.path, "\$['$property']");
      expect((result.first.value as Map)['price'], value);
    }
  }
}
