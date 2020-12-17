import 'package:sarsys_domain/sarsys_domain.dart' as sar;
import 'package:sarsys_http_core/sarsys_http_core.dart';

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
  sar.RegisterOperation onCreate(String uuid, Map<String, dynamic> data) => sar.RegisterOperation(data);

  @override
  sar.AddOperationToIncident onCreated(sar.Incident aggregate, String fuuid) => sar.AddOperationToIncident(
        aggregate,
        fuuid,
      );
}
