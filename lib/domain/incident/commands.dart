import 'package:sarsys_app_server/domain/incident/events.dart';
import 'package:sarsys_app_server/eventsource/eventsource.dart';

abstract class IncidentCommand<T extends DomainEvent> extends Command<T> {
  IncidentCommand(
    Action action, {
    String uuid,
    Map<String, dynamic> data = const {},
  }) : super(action, uuid: uuid, data: data);
}

class RegisterIncident extends IncidentCommand<IncidentRegistered> {
  RegisterIncident(
    Map<String, dynamic> data,
  ) : super(Action.create, data: data);
}

class UpdateIncidentInformation extends IncidentCommand<IncidentInformationUpdated> {
  UpdateIncidentInformation(
    Map<String, dynamic> data,
  ) : super(Action.update, data: data);
}

class CreateSubject extends IncidentCommand<IncidentInformationUpdated> {
  CreateSubject(
    String uuid,
    Map<String, dynamic> data,
  ) : super(Action.create, uuid: uuid, data: data);
}

class UpdateSubject extends IncidentCommand<IncidentInformationUpdated> {
  UpdateSubject(
    String uuid,
    Map<String, dynamic> data,
  ) : super(Action.update, uuid: uuid, data: data);
}
