import 'package:sarsys_app_server/eventsource/eventsource.dart';

abstract class IncidentCommand extends Command {
  IncidentCommand(
    Action action, {
    Map<String, dynamic> data = const {},
  }) : super(action, data: data);
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
