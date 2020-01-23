import 'package:sarsys_app_server/controllers/eventsource/controllers.dart';
import 'package:sarsys_app_server/domain/organisation/organisation.dart';
import 'package:sarsys_app_server/domain/division/commands.dart';
import 'package:sarsys_app_server/domain/division/division.dart';
import 'package:sarsys_app_server/validation/validation.dart';

/// Implement controller for field `divisions` in [Organisation]
class OrganisationDivisionController
    extends AggregateListController<DivisionCommand, Division, OrganisationCommand, Organisation> {
  OrganisationDivisionController(
    OrganisationRepository primary,
    DivisionRepository foreign,
    RequestValidator validator,
  ) : super('divisions', primary, foreign, validator, tag: 'Affiliations');

  @override
  CreateDivision onCreate(String uuid, Map<String, dynamic> data) => CreateDivision(data);

  @override
  AddDivisionToOrganisation onCreated(Organisation aggregate, String foreignUuid) => AddDivisionToOrganisation(
        aggregate,
        foreignUuid,
      );
}
