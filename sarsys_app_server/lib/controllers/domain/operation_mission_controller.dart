import 'package:sarsys_domain/sarsys_domain.dart' hide Operation;
import 'package:sarsys_domain/sarsys_domain.dart' as sar show Operation;
import 'package:sarsys_core/sarsys_core.dart';

/// Implement controller for field `missions` in [sar.Operation]
class OperationMissionController
    extends AggregateListController<MissionCommand, Mission, OperationCommand, sar.Operation> {
  OperationMissionController(
    OperationRepository primary,
    MissionRepository foreign,
    JsonValidation validation,
  ) : super('missions', primary, foreign, validation,
            readOnly: const [
              'operation',
              'parts',
              'results',
              'assignedTo',
              'transitions',
              'messages',
            ],
            tag: 'Operations > Missions');

  @override
  @Operation.get('uuid')
  Future<Response> get(
    @Bind.path('uuid') String uuid, {
    @Bind.query('offset') int offset = 0,
    @Bind.query('limit') int limit = 20,
  }) =>
      super.get(uuid, offset: offset, limit: limit);

  @override
  @Operation.post('uuid')
  Future<Response> create(
    @Bind.path('uuid') String uuid,
    @Bind.body() Map<String, dynamic> data,
  ) =>
      super.create(uuid, data);

  @override
  CreateMission onCreate(String uuid, Map<String, dynamic> data) => CreateMission(data);

  @override
  AddMissionToOperation onCreated(sar.Operation aggregate, String fuuid) => onAdd(
        aggregate,
        fuuid,
      );

  @override
  AddMissionToOperation onAdd(sar.Operation aggregate, String fuuid) => AddMissionToOperation(
        aggregate,
        fuuid,
      );

  @override
  UpdateMissionInformation onAdded(
    sar.Operation aggregate,
    String fuuid,
  ) =>
      UpdateMissionInformation(toForeignRef(
        aggregate,
        fuuid,
      ));

  @override
  RemoveMissionFromOperation onRemove(
    sar.Operation aggregate,
    String fuuid,
  ) =>
      RemoveMissionFromOperation(
        aggregate,
        fuuid,
      );

  @override
  UpdateMissionInformation onRemoved(
    sar.Operation aggregate,
    String fuuid,
  ) =>
      UpdateMissionInformation(toForeignNullRef(
        fuuid,
      ));
}
