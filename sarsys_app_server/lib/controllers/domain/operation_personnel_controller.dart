import 'package:aqueduct/aqueduct.dart';
import 'package:meta/meta.dart';

import 'package:event_source/event_source.dart';
import 'package:sarsys_app_server/controllers/event_source/controllers.dart';
import 'package:sarsys_app_server/controllers/event_source/policy.dart';
import 'package:sarsys_domain/sarsys_domain.dart' hide Operation;
import 'package:sarsys_domain/sarsys_domain.dart' as sar show Operation;
import 'package:sarsys_app_server/validation/validation.dart';

/// Implement controller for field `missions` in [sar.Operation]
class OperationPersonnelController
    extends AggregateListController<PersonnelCommand, Personnel, OperationCommand, sar.Operation> {
  OperationPersonnelController(
    OperationRepository primary,
    PersonnelRepository foreign,
    this.affiliations,
    JsonValidation validation,
  ) : super('personnels', primary, foreign, validation,
            readOnly: const [
              'unit',
              'messages',
              'operation',
              'transitions',
            ],
            tag: 'Operations > Personnels');

  final AffiliationRepository affiliations;

  @override
  @Operation.post('uuid')
  Future<Response> create(
    @Bind.path('uuid') String uuid,
    @Bind.body() Map<String, dynamic> data,
  ) async {
    final auuid = data.elementAt('affiliation/uuid');
    if (auuid is! String) {
      return Response.badRequest(
        body: "Field [affiliation/uuid] is required",
      );
    } else if (!affiliations.contains(auuid as String)) {
      return Response.badRequest(
        body: "Affiliation $uuid not found",
      );
    }
    return super.create(uuid, data);
  }

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
          PersonnelAddedToOperation: isAssigned ? 1 : 0,
        },
        timeout: const Duration(milliseconds: 1000),
      );
    }
    return events;
  }

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
  MobilizePersonnel onCreate(String uuid, Map<String, dynamic> data) => MobilizePersonnel(data);

  @override
  AddPersonnelToOperation onCreated(sar.Operation aggregate, String fuuid) => onAdd(aggregate, fuuid);

  @override
  AddPersonnelToOperation onAdd(
    sar.Operation aggregate,
    String fuuid,
  ) =>
      AddPersonnelToOperation(
        aggregate,
        fuuid,
      );

  @override
  UpdatePersonnelInformation onAdded(
    sar.Operation aggregate,
    String fuuid,
  ) =>
      UpdatePersonnelInformation(toForeignRef(
        aggregate,
        fuuid,
      ));

  @override
  RemovePersonnelFromOperation onRemove(
    sar.Operation aggregate,
    String fuuid,
  ) =>
      RemovePersonnelFromOperation(
        aggregate,
        fuuid,
      );

  @override
  UpdatePersonnelInformation onRemoved(
    sar.Operation aggregate,
    String fuuid,
  ) =>
      UpdatePersonnelInformation(toForeignNullRef(
        fuuid,
      ));
}
