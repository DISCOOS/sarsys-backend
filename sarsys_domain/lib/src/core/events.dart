import 'package:event_source/event_source.dart';
import 'package:meta/meta.dart';

class PositionEvent extends ValueObjectEvent<Map<String, dynamic>> {
  PositionEvent({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
    String valueField = 'position',
  }) : super(
          uuid: uuid,
          type: '$PositionEvent',
          created: created,
          valueField: valueField ?? 'position',
          data: data,
        );

  double get lon => coordinates[0];
  double get lat => coordinates[1];
  double get alt => coordinates[2];
  String get source => value.elementAt('properties/source');
  double get acc => double.tryParse(value.elementAt('properties/accuracy'));
  DateTime get ts => DateTime.parse(value.elementAt('properties/timestamp'));
  Map<String, dynamic> get position => value.elementAt('geometry');
  List<double> get coordinates => List.from(position.elementAt('coordinates'));
}
