import 'package:sarsys_domain/sarsys_domain.dart' hide Operation;
import 'package:sarsys_app_server/sarsys_app_server.dart';

/// A ResourceController that handles
/// [/api/incidents/{uuid}/Divisions](http://localhost/api/client.html#/Division) requests
class DivisionController extends AggregateController<DivisionCommand, Division> {
  DivisionController(DivisionRepository repository, JsonValidation validation)
      : super(
          repository,
          validation: validation,
          readOnly: const ['organisation', 'departments'],
          tag: "Divisions",
        );

  AffiliationRepository get affiliations => (repository as DivisionRepository).affiliations;

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
    final count = affiliations.findDivision(uuid).length;
    final response = await super.delete(uuid, data: data);
    return await withResponseWaitForRuleResults(
      response,
      expected: {
        AffiliationDeleted: count,
        // Can not exist without organisation
        DivisionRemovedFromOrganisation: 1,
      },
      fail: true,
    );
  }

  @override
  DivisionCommand onCreate(Map<String, dynamic> data) => CreateDivision(data);

  @override
  Iterable<DivisionCommand> onUpdate(Map<String, dynamic> data) => [
        UpdateDivisionInformation(data),
      ];

  @override
  DivisionCommand onDelete(Map<String, dynamic> data) => DeleteDivision(data);

  //////////////////////////////////
  // Documentation
  //////////////////////////////////

  @override
  APISchemaObject documentAggregateRoot(APIDocumentContext context) => APISchemaObject.object({
        "uuid": context.schema['UUID']..description = "Unique division id",
        "organisation": APISchemaObject.object({
          "uuid": context.schema['UUID']..description = "Uuid of organisation which this division belongs to",
        })
          ..isReadOnly = true
          ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed,
        "name": APISchemaObject.string()..description = "Division name",
        "suffix": APISchemaObject.string()..description = "FleetMap suffix number",
        "departments": APISchemaObject.array(
          ofSchema: context.schema['UUID'],
        )..description = "List of unique department uuids",
        "active": APISchemaObject.boolean()..description = "Division status",
      })
        ..description = "Division Schema (aggregate root)"
        ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
        ..required = [
          'uuid',
        ];
}
