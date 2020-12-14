import 'package:event_source/event_source.dart';
import 'package:meta/meta.dart';
import 'package:sarsys_domain/sarsys_domain.dart';

class PositionEvent extends ValueObjectEvent<Map<String, dynamic>> {
  PositionEvent({
    @required bool local,
    @required String uuid,
    @required String type,
    @required DateTime created,
    @required Map<String, dynamic> data,
    String valueField = 'position',
  }) : super(
          uuid: uuid,
          type: type,
          local: local,
          created: created,
          valueField: valueField ?? 'position',
          data: data,
        );

  PositionModel get position => PositionModel.fromJson(
        toValue(JsonUtils.apply(previous ?? {}, patches)),
      );
}
