import 'package:sarsys_app_server/controllers/eventsource/controllers.dart';
import 'package:sarsys_app_server/domain/incident/incident.dart';
import 'package:sarsys_app_server/domain/operation/operation.dart' as sar;
import 'package:sarsys_app_server/validation/validation.dart';

/// Implement controller for field `operations` in [Incident]
class IncidentOperationsController
    extends AggregateListController<sar.OperationCommand, sar.Operation, IncidentCommand, Incident> {
  IncidentOperationsController(
    IncidentRepository primary,
    sar.OperationRepository foreign,
    RequestValidator validator,
  ) : super('operations', primary, foreign, validator, tag: "Incidents");

  @override
  sar.RegisterOperation onCreate(String uuid, Map<String, dynamic> data) => sar.RegisterOperation(data);

  @override
  AddOperationToIncident onCreated(Incident aggregate, String foreignUuid) => AddOperationToIncident(
        aggregate,
        foreignUuid,
      );
}
