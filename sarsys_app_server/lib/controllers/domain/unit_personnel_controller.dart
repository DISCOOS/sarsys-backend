import 'package:sarsys_app_server/controllers/event_source/controllers.dart';
import 'package:sarsys_domain/sarsys_domain.dart';
import 'package:sarsys_app_server/validation/validation.dart';

/// Implement controller for field `personnels` in [Unit]
class UnitPersonnelController extends AggregateListController<PersonnelCommand, Personnel, UnitCommand, Unit> {
  UnitPersonnelController(
    UnitRepository primary,
    PersonnelRepository foreign,
    JsonValidation validation,
  ) : super('personnels', primary, foreign, validation, tag: "Units > Personnels");

  @override
  RegisterPersonnel onCreate(String uuid, Map<String, dynamic> data) => RegisterPersonnel(data);

  @override
  AddPersonnelToUnit onCreated(Unit aggregate, String foreignUuid) => AddPersonnelToUnit(
        aggregate,
        foreignUuid,
      );
}
