import 'package:sarsys_app_server/domain/unit/events.dart';
import 'package:sarsys_app_server/eventsource/eventsource.dart';

abstract class UnitCommand<T extends DomainEvent> extends Command<T> {
  UnitCommand(
    Action action, {
    Map<String, dynamic> data = const {},
  }) : super(action, data: data);
}

class MobilizeUnit extends UnitCommand<UnitMobilized> {
  MobilizeUnit(
    Map<String, dynamic> data,
  ) : super(Action.create, data: data);
}

class UpdateUnitInformation extends UnitCommand<UnitInformationUpdated> {
  UpdateUnitInformation(
    Map<String, dynamic> data,
  ) : super(Action.update, data: data);
}
