import 'package:sarsys_app_server/controllers/eventsource/aggregate_controller.dart';
import 'package:sarsys_app_server/domain/department/department.dart';
import 'package:sarsys_app_server/sarsys_app_server.dart';
import 'package:sarsys_app_server/validation/validation.dart';

/// A ResourceController that handles
/// [/api/incidents/{uuid}/Departments](http://localhost/api/client.html#/Department) requests
class DepartmentController extends AggregateController<DepartmentCommand, Department> {
  DepartmentController(DepartmentRepository repository, RequestValidator validator)
      : super(repository, validator: validator, tag: "Affiliations");

  @override
  DepartmentCommand onCreate(Map<String, dynamic> data) => CreateDepartment(data);

  @override
  DepartmentCommand onUpdate(Map<String, dynamic> data) => UpdateDepartment(data);

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
        "alias": APISchemaObject.string()..description = "Department alias",
      })
        ..description = "Department Schema (aggregate root)"
        ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
        ..required = [
          'id',
          'name',
        ];
}
