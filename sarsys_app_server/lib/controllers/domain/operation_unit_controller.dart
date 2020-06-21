import 'package:event_source/event_source.dart';
import 'package:sarsys_app_server/controllers/event_source/policy.dart';
import 'package:sarsys_domain/sarsys_domain.dart' as sar show Operation;
import 'package:sarsys_domain/sarsys_domain.dart' hide Operation;
import 'package:aqueduct/aqueduct.dart';
import 'package:meta/meta.dart';
import 'package:sarsys_app_server/controllers/event_source/controllers.dart';
import 'package:sarsys_app_server/validation/validation.dart';

/// Implement controller for field `units` in [sar.Operation]
class OperationUnitController extends AggregateListController<UnitCommand, Unit, OperationCommand, sar.Operation> {
  OperationUnitController(
    OperationRepository primary,
    UnitRepository foreign,
    JsonValidation validation,
  ) : super(
          'units',
          primary,
          foreign,
          validation,
          readOnly: const [
            'operation',
            'messages',
            'transitions',
          ],
          tag: 'Operations > Units',
        );

  @override
  @Operation.post('uuid')
  Future<Response> create(
    @Bind.path('uuid') String uuid,
    @Bind.body() Map<String, dynamic> data,
  ) =>
      super.create(uuid, data);

  @override
  @visibleForOverriding
  Future<Iterable<Event>> doCreate(String fuuid, Map<String, dynamic> data) async {
    final isAssigned = data?.elementAt('unit/uuid') != null;
    final hasTracking = data?.elementAt('tracking/uuid') != null;
    final events = await super.doCreate(fuuid, data);
    if (hasTracking || isAssigned) {
      await PolicyUtils.waitForRuleResults(
        foreign,
        fail: true,
        expected: {
          TrackingCreated: hasTracking ? 1 : 0,
          UnitAddedToOperation: isAssigned ? 1 : 0,
        },
        timeout: const Duration(milliseconds: 1000),
      );
    }
    return events;
  }

  @override
  CreateUnit onCreate(String uuid, Map<String, dynamic> data) => CreateUnit(data);

  @override
  AddUnitToOperation onCreated(sar.Operation aggregate, String fuuid) => onAdd(
        aggregate,
        fuuid,
      );

  @override
  AddUnitToOperation onAdd(sar.Operation aggregate, String fuuid) => AddUnitToOperation(
        aggregate,
        fuuid,
      );

  @override
  UpdateUnitInformation onAdded(
    sar.Operation aggregate,
    String fuuid,
  ) =>
      UpdateUnitInformation(toForeignRef(
        aggregate,
        fuuid,
      ));

  @override
  RemoveUnitFromOperation onRemove(
    sar.Operation aggregate,
    String fuuid,
  ) =>
      RemoveUnitFromOperation(
        aggregate,
        fuuid,
      );

  @override
  UpdateUnitInformation onRemoved(
    sar.Operation aggregate,
    String fuuid,
  ) =>
      UpdateUnitInformation(toForeignNullRef(
        fuuid,
      ));
}
