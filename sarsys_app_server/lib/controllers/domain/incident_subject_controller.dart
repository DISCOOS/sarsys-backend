import 'package:sarsys_app_server/controllers/eventsource/controllers.dart';
import 'package:sarsys_domain/sarsys_domain.dart';
import 'package:sarsys_app_server/validation/validation.dart';

/// Implement controller for field `subjects` in [Incident]
class IncidentSubjectController extends AggregateListController<SubjectCommand, Subject, IncidentCommand, Incident> {
  IncidentSubjectController(
    IncidentRepository primary,
    SubjectRepository foreign,
    JsonValidation validation,
  ) : super('subjects', primary, foreign, validation, tag: "Incidents > Subjects");

  @override
  RegisterSubject onCreate(String uuid, Map<String, dynamic> data) => RegisterSubject(data);

  @override
  AddSubjectToIncident onCreated(Incident aggregate, String foreignUuid) => AddSubjectToIncident(
        aggregate,
        foreignUuid,
      );
}
