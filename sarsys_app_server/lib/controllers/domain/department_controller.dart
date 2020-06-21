import 'package:sarsys_app_server/controllers/event_source/aggregate_controller.dart';
import 'package:sarsys_domain/sarsys_domain.dart' hide Operation;
import 'package:sarsys_app_server/sarsys_app_server.dart';
import 'package:sarsys_app_server/validation/validation.dart';

/// A ResourceController that handles
/// [/api/incidents/{uuid}/Departments](http://localhost/api/client.html#/Department) requests
class DepartmentController extends AggregateController<DepartmentCommand, Department> {
  DepartmentController(DepartmentRepository repository, JsonValidation validation)
      : super(
          repository,
          validation: validation,
          readOnly: const ['division'],
          tag: "Departments",
        );

  AffiliationRepository get affiliations => (repository as DepartmentRepository).affiliations;

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
    final count = affiliations.findDepartment(uuid).length;
    final response = await super.delete(uuid, data: data);
    return await withResponseWaitForRuleResults(
      response,
      expected: {
        AffiliationDeleted: count,
        // Can not exist without division
        DepartmentRemovedFromDivision: 1,
      },
    );
  }

  @override
  DepartmentCommand onCreate(Map<String, dynamic> data) => CreateDepartment(data);

  @override
  DepartmentCommand onUpdate(Map<String, dynamic> data) => UpdateDepartmentInformation(data);

  @override
  DepartmentCommand onDelete(Map<String, dynamic> data) => DeleteDepartment(data);

  //////////////////////////////////
  // Documentation
  //////////////////////////////////

  @override
  APISchemaObject documentAggregateRoot(APIDocumentContext context) => APISchemaObject.object({
        "uuid": context.schema['UUID']..description = "Unique department id",
        "division": APISchemaObject.object({
          "uuid": context.schema['UUID']..description = "Uuid of division which this department belongs to",
        })
          ..isReadOnly = true
          ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed,
        "name": APISchemaObject.string()..description = "Department name",
        "suffix": APISchemaObject.string()..description = "FleetMap number suffix",
        "active": APISchemaObject.boolean()..description = "Department status",
      })
        ..description = "Department Schema (aggregate root)"
        ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
        ..required = [
          'uuid',
        ];
}
