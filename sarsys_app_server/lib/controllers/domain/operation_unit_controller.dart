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
    this.personnels,
    JsonValidation validation,
  ) : super(
          'units',
          primary,
          foreign,
          validation,
          readOnly: const [
            'messages',
            'operation',
            'transitions',
          ],
          tag: 'Operations > Units',
        );

  final PersonnelRepository personnels;

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
  @visibleForOverriding
  Future<Iterable<DomainEvent>> doCreate(String fuuid, Map<String, dynamic> data) async {
    final uuuid = data?.elementAt<String>('uuid');
    final hasTracking = data?.elementAt('tracking/uuid') != null;
    final _personnels = List<String>.from(
      data?.elementAt('personnels') ?? <String>[],
    );
    final notFound = _personnels.where((puuid) => !personnels.exists(puuid));
    if (notFound.isNotEmpty) {
      throw AggregateNotFound("Personnels not found: ${notFound.join(', ')}");
    }
    // Create without personnels
    final events = await super.doCreate(
      fuuid,
      Map.from(data)..remove('personnels'),
    );
    if (hasTracking) {
      await PolicyUtils.waitForRuleResult<TrackingCreated>(
        foreign,
        fail: true,
        timeout: const Duration(milliseconds: 1000),
      );
    }
    // Add personnels to unit just created
    if (_personnels.isNotEmpty) {
      final unit = foreign.get(uuuid);
      for (var puuid in _personnels) {
        await foreign.execute(
          AssignPersonnelToUnit(unit, puuid),
        );
      }
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
