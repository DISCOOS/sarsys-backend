import 'package:sarsys_app_server/controllers/eventsource/controllers.dart';
import 'package:sarsys_domain/sarsys_domain.dart' as sar;
import 'package:sarsys_app_server/validation/validation.dart';

/// Implement controller for field `units` in [sar.Operation]
class OperationUnitController
    extends AggregateListController<sar.UnitCommand, sar.Unit, sar.OperationCommand, sar.Operation> {
  OperationUnitController(
    sar.OperationRepository primary,
    sar.UnitRepository foreign,
    JsonValidation validation,
  ) : super('units', primary, foreign, validation, tag: 'Operations > Units');

  @override
  sar.CreateUnit onCreate(String uuid, Map<String, dynamic> data) => sar.CreateUnit(data);

  @override
  sar.AddUnitToOperation onCreated(sar.Operation aggregate, String foreignUuid) => sar.AddUnitToOperation(
        aggregate,
        foreignUuid,
      );
}
