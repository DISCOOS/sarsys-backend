import 'package:sarsys_app_server/eventsource/eventsource.dart';

import 'events.dart';

abstract class OrganisationCommand<T extends DomainEvent> extends Command<T> {
  OrganisationCommand(
    Action action, {
    String uuid,
    Map<String, dynamic> data = const {},
  }) : super(action, uuid: uuid, data: data);
}

//////////////////////////////////
// Organisation aggregate commands
//////////////////////////////////

class CreateOrganisation extends OrganisationCommand<OrganisationCreated> {
  CreateOrganisation(
    Map<String, dynamic> data,
  ) : super(Action.create, data: data);
}

class UpdateOrganisation extends OrganisationCommand<OrganisationUpdated> {
  UpdateOrganisation(
    Map<String, dynamic> data,
  ) : super(Action.update, data: data);
}

class DeleteOrganisation extends OrganisationCommand<OrganisationDeleted> {
  DeleteOrganisation(
    Map<String, dynamic> data,
  ) : super(Action.delete, data: data);
}
