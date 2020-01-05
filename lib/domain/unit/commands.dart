import 'package:sarsys_app_server/eventsource/eventsource.dart';

abstract class UnitCommand extends Command {
  UnitCommand(
    Action action, {
    Map<String, dynamic> data = const {},
  }) : super(action, data: data);
}

class CreateUnit extends UnitCommand {
  CreateUnit(
    Map<String, dynamic> data,
  ) : super(Action.create, data: data);
}

class UpdateUnit extends UnitCommand {
  UpdateUnit(
    Map<String, dynamic> data,
  ) : super(Action.update, data: data);
}
