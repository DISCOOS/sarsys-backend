import 'package:sarsys_app_server/controllers/event_source/controllers.dart';
import 'package:sarsys_domain/sarsys_domain.dart' as sar;
import 'package:sarsys_app_server/validation/validation.dart';

/// Implement controller for field `missions` in [sar.Operation]
class OperationMissionController
    extends AggregateListController<sar.MissionCommand, sar.Mission, sar.OperationCommand, sar.Operation> {
  OperationMissionController(
    sar.OperationRepository primary,
    sar.MissionRepository foreign,
    JsonValidation validation,
  ) : super('missions', primary, foreign, validation, tag: 'Operations > Missions');

  @override
  sar.CreateMission onCreate(String uuid, Map<String, dynamic> data) => sar.CreateMission(data);

  @override
  sar.AddMissionToOperation onCreated(sar.Operation aggregate, String foreignUuid) => sar.AddMissionToOperation(
        aggregate,
        foreignUuid,
      );
}
