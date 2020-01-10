import 'package:sarsys_app_server/domain/operation/events.dart';
import 'package:sarsys_app_server/eventsource/eventsource.dart';

abstract class OperationCommand<T extends DomainEvent> extends Command<T> {
  OperationCommand(
    Action action, {
    Map<String, dynamic> data = const {},
  }) : super(action, data: data);
}

class RegisterOperation extends OperationCommand<OperationRegistered> {
  RegisterOperation(
    Map<String, dynamic> data,
  ) : super(Action.create, data: data);
}

class UpdateOperationInformation extends OperationCommand<OperationInformationUpdated> {
  UpdateOperationInformation(
    Map<String, dynamic> data,
  ) : super(Action.update, data: data);
}
