import 'package:sarsys_app_server/controllers/eventsource/controllers.dart';
import 'package:sarsys_app_server/domain/operation/operation.dart' as sar;
import 'package:sarsys_app_server/domain/operation/operation.dart';
import 'package:sarsys_app_server/domain/unit/unit.dart';
import 'package:sarsys_app_server/validation/validation.dart';

/// Implement controller for field `units` in [sar.Operation]
class OperationUnitController extends AggregateListController<UnitCommand, Unit, sar.OperationCommand, sar.Operation> {
  OperationUnitController(
    sar.OperationRepository primary,
    UnitRepository foreign,
    JsonValidation validation,
  ) : super('units', primary, foreign, validation, tag: 'Operations > Units');

  @override
  CreateUnit onCreate(String uuid, Map<String, dynamic> data) => CreateUnit(data);

  @override
  AddUnitToOperation onCreated(Operation aggregate, String foreignUuid) => AddUnitToOperation(
        aggregate,
        foreignUuid,
      );
}
