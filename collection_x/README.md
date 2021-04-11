A library of extension methods on collections

## Usage

A simple usage example:

```dart
import 'package:collection_x/collection_x.dart';

main() {
  final map = <String,dynamic>{
    'object1': {
      'key1': 1,
      'key2': '2',
    }  
  };
  final value1 = map.elementAt<int>('object1/key1');

  final list = <String>['value1', 'value2'];
  final noValue = list.whereType<double>().firstOrNull;
  final value1 = list.where((e) => e !=null).firstOrNull;
  final value2 = list.where((e) => e !=null).lastOrNull;
  
}
```

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: http://github.com/DISCOOS/sarsys-backend/issues/replaceme
