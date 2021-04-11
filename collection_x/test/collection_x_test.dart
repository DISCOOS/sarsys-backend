import 'package:collection_x/collection_x.dart';
import 'package:test/test.dart';

void main() {
  test('Fetch value from map on given path', () {
    final map = <String, dynamic>{
      'object1': {
        'key1': 1,
        'key2': '2',
      }
    };
    final value1 = map.elementAt<int>('object1/key1');
    expect(value1, 1);
  });

  test('First on empty iterable is null', () {
    final list = <String>['value1', 'value2'];
    final noValue = list.whereType<double>().firstOrNull;
    expect(noValue, isNull);
  });

  test('Last on empty iterable is null', () {
    final list = <String>['value1', 'value2'];
    final noValue = list.whereType<double>().lastOrNull;
    expect(noValue, isNull);
  });

  test('First on iterable is not null', () {
    final list = <String>['value1', 'value2'];
    final value1 = list.where((e) => e != null).firstOrNull;
    expect(value1, 'value1');
  });

  test('Last on iterable is not', () {
    final list = <String>['value1', 'value2'];
    final value2 = list.where((e) => e != null).lastOrNull;
    expect(value2, 'value2');
  });
}
