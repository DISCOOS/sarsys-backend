import 'package:aqueduct/aqueduct.dart';
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
  ) : super(
          'operations',
          primary,
          foreign,
          validation,
          readOnly: const ['incident'],
          tag: "Incidents > Operations",
        );

  @override
  @Operation.post('uuid')
  Future<Response> create(
    @Bind.path('uuid') String uuid,
    @Bind.body() Map<String, dynamic> data,
  ) =>
      super.create(uuid, data);

  @override
  sar.RegisterOperation onCreate(String uuid, Map<String, dynamic> data) => sar.RegisterOperation(data);

  @override
  sar.AddOperationToIncident onCreated(sar.Incident aggregate, String fuuid) => sar.AddOperationToIncident(
        aggregate,
        fuuid,
      );
}
