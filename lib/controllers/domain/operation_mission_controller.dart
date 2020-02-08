import 'package:sarsys_app_server/controllers/eventsource/controllers.dart';
import 'package:sarsys_app_server/domain/mission/commands.dart';
import 'package:sarsys_app_server/domain/mission/mission.dart';
import 'package:sarsys_app_server/domain/operation/operation.dart' as sar;
import 'package:sarsys_app_server/domain/operation/operation.dart';
import 'package:sarsys_app_server/validation/validation.dart';

/// Implement controller for field `missions` in [sar.Operation]
class OperationMissionController
    extends AggregateListController<MissionCommand, Mission, sar.OperationCommand, sar.Operation> {
  OperationMissionController(
    sar.OperationRepository primary,
    MissionRepository foreign,
    JsonValidation validation,
  ) : super('missions', primary, foreign, validation, tag: 'Operations');

  @override
  CreateMission onCreate(String uuid, Map<String, dynamic> data) => CreateMission(data);

  @override
  AddMissionToOperation onCreated(Operation aggregate, String foreignUuid) => AddMissionToOperation(
        aggregate,
        foreignUuid,
      );
}
