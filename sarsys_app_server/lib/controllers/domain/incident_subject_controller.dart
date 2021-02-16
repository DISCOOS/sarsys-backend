import 'package:sarsys_domain/sarsys_domain.dart' hide Operation;
import 'package:sarsys_core/sarsys_core.dart';

/// Implement controller for field `subjects` in [Incident]
class IncidentSubjectController extends AggregateListController<SubjectCommand, Subject, IncidentCommand, Incident> {
  IncidentSubjectController(
    IncidentRepository primary,
    SubjectRepository foreign,
    JsonValidation validation,
  ) : super(
          'subjects',
          primary,
          foreign,
          validation,
          readOnly: const ['incident'],
          tag: "Incidents > Subjects",
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
  RegisterSubject onCreate(String uuid, Map<String, dynamic> data) => RegisterSubject(data);

  @override
  AddSubjectToIncident onCreated(Incident aggregate, String fuuid) => AddSubjectToIncident(
        aggregate,
        fuuid,
      );
}
