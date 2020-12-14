import 'package:sarsys_domain/sarsys_domain.dart' hide Operation;
import 'package:sarsys_app_server/sarsys_app_server.dart';

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
  @Operation.get('uuid')
  Future<Response> get(
    @Bind.path('uuid') String uuid, {
    @Bind.query('offset') int offset = 0,
    @Bind.query('limit') int limit = 20,
  }) =>
      super.get(uuid, offset: offset, limit: limit);

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
