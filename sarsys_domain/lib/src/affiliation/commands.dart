import 'package:event_source/event_source.dart';

import 'events.dart';

abstract class AffiliationCommand<T extends DomainEvent> extends Command<T> {
  AffiliationCommand(
    Action action, {
    String uuid,
    Map<String, dynamic> data = const {},
  }) : super(action, uuid: uuid, data: data);
}

//////////////////////////////////
// Affiliation aggregate commands
//////////////////////////////////

class CreateAffiliation extends AffiliationCommand<AffiliationCreated> {
  CreateAffiliation(
    Map<String, dynamic> data,
  ) : super(Action.create, data: data);
}

class UpdateAffiliation extends AffiliationCommand<AffiliationInformationUpdated> {
  UpdateAffiliation(
    Map<String, dynamic> data,
  ) : super(Action.update, data: data);
}

class DeleteAffiliation extends AffiliationCommand<AffiliationDeleted> {
  DeleteAffiliation(
    Map<String, dynamic> data,
  ) : super(Action.delete, data: data);
}
