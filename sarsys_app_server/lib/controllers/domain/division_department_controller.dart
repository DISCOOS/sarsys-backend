import 'package:sarsys_app_server/controllers/eventsource/controllers.dart';
import 'package:sarsys_domain/sarsys_domain.dart';
import 'package:sarsys_app_server/validation/validation.dart';

/// Implement controller for field `departments` in [Division]
class DivisionDepartmentController
    extends AggregateListController<DepartmentCommand, Department, DivisionCommand, Division> {
  DivisionDepartmentController(
    DivisionRepository primary,
    DepartmentRepository foreign,
    JsonValidation validation,
  ) : super('departments', primary, foreign, validation, tag: 'Divisions');

  @override
  CreateDepartment onCreate(String uuid, Map<String, dynamic> data) => CreateDepartment(data);

  @override
  AddDepartmentToDivision onCreated(Division aggregate, String foreignUuid) => AddDepartmentToDivision(
        aggregate,
        foreignUuid,
      );
}
