import 'package:sarsys_app_server/eventsource/eventsource.dart';

abstract class IncidentCommand extends Command {
  IncidentCommand(
    Action action, {
    String uuid,
    Map<String, dynamic> data = const {},
  }) : super(action, uuid: uuid, data: data);
}

class CreateIncident extends IncidentCommand {
  CreateIncident(
    Map<String, dynamic> data,
  ) : super(Action.create, data: data);
}

class UpdateIncident extends IncidentCommand {
  UpdateIncident(
    Map<String, dynamic> data,
  ) : super(Action.update, data: data);
}

class CreateSubject extends IncidentCommand {
  CreateSubject(
    String uuid,
    Map<String, dynamic> data,
  ) : super(Action.create, uuid: uuid, data: data);
}

class UpdateSubject extends IncidentCommand {
  UpdateSubject(
    String uuid,
    Map<String, dynamic> data,
  ) : super(Action.update, uuid: uuid, data: data);
}
