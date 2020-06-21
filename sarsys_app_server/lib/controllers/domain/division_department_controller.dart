import 'package:aqueduct/aqueduct.dart';
import 'package:sarsys_app_server/controllers/event_source/controllers.dart';
import 'package:sarsys_domain/sarsys_domain.dart' hide Operation;
import 'package:sarsys_app_server/validation/validation.dart';

/// Implement controller for field `departments` in [Division]
class DivisionDepartmentController
    extends AggregateListController<DepartmentCommand, Department, DivisionCommand, Division> {
  DivisionDepartmentController(
    DivisionRepository primary,
    DepartmentRepository foreign,
    JsonValidation validation,
  ) : super(
          'departments',
          primary,
          foreign,
          validation,
          readOnly: const ['division'],
          tag: 'Divisions',
        );

  @override
  @Operation.post('uuid')
  Future<Response> create(
    @Bind.path('uuid') String uuid,
    @Bind.body() Map<String, dynamic> data,
  ) =>
      super.create(uuid, data);

  @override
  CreateDepartment onCreate(String uuid, Map<String, dynamic> data) => CreateDepartment(data);

  @override
  AddDepartmentToDivision onCreated(Division aggregate, String fuuid) => onAdd(aggregate, fuuid);

  @override
  AddDepartmentToDivision onAdd(Division aggregate, String fuuid) => AddDepartmentToDivision(
        aggregate,
        fuuid,
      );

  @override
  UpdateDepartmentInformation onAdded(Division aggregate, String fuuid) => UpdateDepartmentInformation(toForeignRef(
        aggregate,
        fuuid,
      ));

  @override
  RemoveDepartmentFromDivision onRemove(Division aggregate, String fuuid) => RemoveDepartmentFromDivision(
        aggregate,
        fuuid,
      );

  @override
  UpdateDepartmentInformation onRemoved(
    Division aggregate,
    String fuuid,
  ) =>
      UpdateDepartmentInformation(toForeignNullRef(
        fuuid,
      ));
}
