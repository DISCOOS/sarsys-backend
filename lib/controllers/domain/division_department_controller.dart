import 'package:sarsys_app_server/controllers/eventsource/controllers.dart';
import 'package:sarsys_app_server/domain/division/division.dart';
import 'package:sarsys_app_server/domain/department/commands.dart';
import 'package:sarsys_app_server/domain/department/department.dart';
import 'package:sarsys_app_server/validation/validation.dart';

/// Implement controller for field `departments` in [Division]
class DivisionDepartmentController
    extends AggregateListController<DepartmentCommand, Department, DivisionCommand, Division> {
  DivisionDepartmentController(
    DivisionRepository primary,
    DepartmentRepository foreign,
    RequestValidator validator,
  ) : super('departments', primary, foreign, validator, tag: 'Divisions');

  @override
  CreateDepartment onCreate(String uuid, Map<String, dynamic> data) => CreateDepartment(data);

  @override
  AddDepartmentToDivision onCreated(Division aggregate, String foreignUuid) => AddDepartmentToDivision(
        aggregate,
        foreignUuid,
      );
}
