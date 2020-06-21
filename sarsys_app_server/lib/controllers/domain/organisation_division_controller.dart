import 'package:aqueduct/aqueduct.dart';
import 'package:sarsys_app_server/controllers/event_source/controllers.dart';
import 'package:sarsys_domain/sarsys_domain.dart' hide Operation;
import 'package:sarsys_app_server/validation/validation.dart';

/// Implement controller for field `divisions` in [Organisation]
class OrganisationDivisionController
    extends AggregateListController<DivisionCommand, Division, OrganisationCommand, Organisation> {
  OrganisationDivisionController(
    OrganisationRepository primary,
    DivisionRepository foreign,
    JsonValidation validation,
  ) : super(
          'divisions',
          primary,
          foreign,
          validation,
          tag: 'Organisations',
          readOnly: const ['organisation', 'divisions'],
        );

  @override
  @Operation.post('uuid')
  Future<Response> create(
    @Bind.path('uuid') String uuid,
    @Bind.body() Map<String, dynamic> data,
  ) =>
      super.create(uuid, data);

  @override
  CreateDivision onCreate(String uuid, Map<String, dynamic> data) => CreateDivision(data);

  @override
  AddDivisionToOrganisation onCreated(Organisation aggregate, String fuuid) => AddDivisionToOrganisation(
        aggregate,
        fuuid,
      );
}
