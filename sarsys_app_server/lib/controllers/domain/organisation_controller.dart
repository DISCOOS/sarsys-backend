import 'package:sarsys_app_server/controllers/event_source/aggregate_controller.dart';
import 'package:sarsys_domain/sarsys_domain.dart' hide Operation;
import 'package:sarsys_app_server/sarsys_app_server.dart';
import 'package:sarsys_app_server/validation/validation.dart';

/// A ResourceController that handles
/// [/api/organisations](http://localhost/api/client.html#/Organisation) requests
class OrganisationController extends AggregateController<OrganisationCommand, Organisation> {
  OrganisationController(
    OrganisationRepository organisations,
    JsonValidation validation,
  ) : super(
          organisations,
          validation: validation,
          readOnly: const ['divisions'],
          tag: 'Organisations',
        );

  AffiliationRepository get affiliations => (repository as OrganisationRepository).affiliations;

  @override
  @Operation.get()
  Future<Response> getAll({
    @Bind.query('offset') int offset = 0,
    @Bind.query('limit') int limit = 20,
    @Bind.query('deleted') bool deleted = false,
  }) {
    return super.getAll(
      offset: offset,
      limit: limit,
      deleted: deleted,
    );
  }

  @override
  @Operation.get('uuid')
  Future<Response> getByUuid(@Bind.path('uuid') String uuid) {
    return super.getByUuid(uuid);
  }

  @override
  @Operation.post()
  Future<Response> create(@Bind.body() Map<String, dynamic> data) {
    return super.create(data);
  }

  @override
  @Operation('PATCH', 'uuid')
  Future<Response> update(
    @Bind.path('uuid') String uuid,
    @Bind.body() Map<String, dynamic> data,
  ) {
    return super.update(uuid, data);
  }

  @override
  @Operation('DELETE', 'uuid')
  Future<Response> delete(
    @Bind.path('uuid') String uuid, {
    @Bind.body() Map<String, dynamic> data,
  }) async {
    final count = affiliations.findOrganisation(uuid).length;
    final response = await super.delete(uuid, data: data);
    if (count > 0) {
      return await withResponseWaitForRuleResult<AffiliationDeleted>(
        response,
        count: count,
        fail: true,
      );
    }
    return response;
  }

  @override
  OrganisationCommand onCreate(Map<String, dynamic> data) => CreateOrganisation(data);

  @override
  OrganisationCommand onUpdate(Map<String, dynamic> data) => UpdateOrganisation(data);

  @override
  OrganisationCommand onDelete(Map<String, dynamic> data) => DeleteOrganisation(data);

  //////////////////////////////////
  // Documentation
  //////////////////////////////////

  /// Organisation - Aggregate root
  @override
  APISchemaObject documentAggregateRoot(APIDocumentContext context) => APISchemaObject.object(
        {
          "uuid": context.schema['UUID']..description = "Unique Organisation id",
          "name": APISchemaObject.string()..description = "Organisation name",
          "suffix": APISchemaObject.string()..description = "FleetMap number suffix",
          "divisions": APISchemaObject.array(
            ofSchema: context.schema['UUID'],
          )..description = "List of division uuids",
          "active": APISchemaObject.boolean()..description = "Organisation status",
        },
      )
        ..description = "Organisation Schema (aggregate root)"
        ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
        ..required = [
          'uuid',
        ];
}
