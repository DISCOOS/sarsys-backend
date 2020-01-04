import 'package:sarsys_app_server/eventsource/eventsource.dart';

abstract class OperationCommand extends Command {
  OperationCommand(
    Action action, {
    Map<String, dynamic> data = const {},
  }) : super(action, data: data);
}

class CreateOperation extends OperationCommand {
  CreateOperation(
    Map<String, dynamic> data,
  ) : super(Action.create, data: data);
}

class UpdateOperation extends OperationCommand {
  UpdateOperation(
    Map<String, dynamic> data,
  ) : super(Action.update, data: data);
}
