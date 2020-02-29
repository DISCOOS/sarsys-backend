import 'package:sarsys_app_server/controllers/event_source/controllers.dart';
import 'package:sarsys_domain/sarsys_domain.dart' as sar;
import 'package:sarsys_app_server/validation/validation.dart';

/// Implement controller for field `operations` in [sar.Incident]
class IncidentOperationsController
    extends AggregateListController<sar.OperationCommand, sar.Operation, sar.IncidentCommand, sar.Incident> {
  IncidentOperationsController(
    sar.IncidentRepository primary,
    sar.OperationRepository foreign,
    JsonValidation validation,
  ) : super('operations', primary, foreign, validation, tag: "Incidents > Operations");

  @override
  sar.RegisterOperation onCreate(String uuid, Map<String, dynamic> data) => sar.RegisterOperation(data);

  @override
  sar.AddOperationToIncident onCreated(sar.Incident aggregate, String foreignUuid) => sar.AddOperationToIncident(
        aggregate,
        foreignUuid,
      );
}
