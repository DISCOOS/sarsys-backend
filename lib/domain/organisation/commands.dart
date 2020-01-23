import 'package:sarsys_app_server/eventsource/eventsource.dart';

import 'aggregate.dart';
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

class UpdateOrganisation extends OrganisationCommand<OrganisationInfomationUpdated> {
  UpdateOrganisation(
    Map<String, dynamic> data,
  ) : super(Action.update, data: data);
}

class AddDivisionToOrganisation extends OrganisationCommand<DivisionAddedToOrganisation> {
  AddDivisionToOrganisation(
    Organisation organisation,
    String operationUuid,
  ) : super(
          Action.update,
          uuid: organisation.uuid,
          data: Command.addToList<String>(organisation.data, 'divisions', operationUuid),
        );
}

class RemoveDivisionFromOrganisation extends OrganisationCommand<DivisionRemovedFromOrganisation> {
  RemoveDivisionFromOrganisation(
    Organisation organisation,
    String operationUuid,
  ) : super(
          Action.update,
          uuid: organisation.uuid,
          data: Command.removeFromList<String>(organisation.data, 'divisions', operationUuid),
        );
}

class DeleteOrganisation extends OrganisationCommand<OrganisationDeleted> {
  DeleteOrganisation(
    Map<String, dynamic> data,
  ) : super(Action.delete, data: data);
}
