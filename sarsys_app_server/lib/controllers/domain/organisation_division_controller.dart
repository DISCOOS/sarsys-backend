import 'package:sarsys_app_server/controllers/event_source/controllers.dart';
import 'package:sarsys_domain/sarsys_domain.dart';
import 'package:sarsys_app_server/validation/validation.dart';

/// Implement controller for field `divisions` in [Organisation]
class OrganisationDivisionController
    extends AggregateListController<DivisionCommand, Division, OrganisationCommand, Organisation> {
  OrganisationDivisionController(
    OrganisationRepository primary,
    DivisionRepository foreign,
    JsonValidation validation,
  ) : super('divisions', primary, foreign, validation, tag: 'Organisations');

  @override
  CreateDivision onCreate(String uuid, Map<String, dynamic> data) => CreateDivision(data);

  @override
  AddDivisionToOrganisation onCreated(Organisation aggregate, String foreignUuid) => AddDivisionToOrganisation(
        aggregate,
        foreignUuid,
      );
}
