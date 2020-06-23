import 'package:aqueduct/aqueduct.dart';
import 'package:sarsys_app_server/controllers/event_source/controllers.dart';
import 'package:sarsys_domain/sarsys_domain.dart' hide Operation;
import 'package:sarsys_app_server/validation/validation.dart';

/// Implement controller for field `personnels` in [Unit]
class UnitPersonnelController extends AggregateListController<PersonnelCommand, Personnel, UnitCommand, Unit> {
  UnitPersonnelController(
    UnitRepository primary,
    PersonnelRepository foreign,
    JsonValidation validation,
  ) : super(
          'personnels',
          primary,
          foreign,
          validation,
          tag: "Units > Personnels",
        );

  @override
  @Operation.get('uuid')
  Future<Response> get(
    @Bind.path('uuid') String uuid, {
    @Bind.query('offset') int offset = 0,
    @Bind.query('limit') int limit = 20,
  }) =>
      super.get(uuid, offset: offset, limit: limit);

  @override
  @Operation('PATCH', 'uuid')
  Future<Response> add(
    @Bind.path('uuid') String uuid,
    @Bind.body() Map<String, dynamic> data,
  ) =>
      super.add(uuid, data);

  @override
  @Operation.delete('uuid')
  Future<Response> remove(
    @Bind.path('uuid') String uuid,
    @Bind.body() Map<String, dynamic> data,
  ) =>
      super.remove(uuid, data);

  @override
  AssignPersonnelToUnit onAdd(Unit aggregate, String fuuid) => AssignPersonnelToUnit(
        aggregate,
        fuuid,
      );

  @override
  UpdatePersonnelInformation onAdded(
    Unit aggregate,
    String fuuid,
  ) =>
      UpdatePersonnelInformation(toForeignRef(
        aggregate,
        fuuid,
      ));

  @override
  RemovePersonnelFromUnit onRemove(Unit aggregate, String fuuid) => RemovePersonnelFromUnit(
        aggregate,
        fuuid,
      );

  @override
  UpdatePersonnelInformation onRemoved(
    Unit aggregate,
    String fuuid,
  ) =>
      UpdatePersonnelInformation(toForeignNullRef(
        fuuid,
      ));
}
