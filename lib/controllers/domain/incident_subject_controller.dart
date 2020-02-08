import 'package:sarsys_app_server/controllers/eventsource/controllers.dart';
import 'package:sarsys_app_server/domain/incident/incident.dart';
import 'package:sarsys_app_server/domain/subject/commands.dart';
import 'package:sarsys_app_server/domain/subject/subject.dart';
import 'package:sarsys_app_server/validation/validation.dart';

/// Implement controller for field `subjects` in [Incident]
class IncidentSubjectController extends AggregateListController<SubjectCommand, Subject, IncidentCommand, Incident> {
  IncidentSubjectController(
    IncidentRepository primary,
    SubjectRepository foreign,
    JsonValidation validation,
  ) : super('subjects', primary, foreign, validation, tag: "Incidents");

  @override
  RegisterSubject onCreate(String uuid, Map<String, dynamic> data) => RegisterSubject(data);

  @override
  AddSubjectToIncident onCreated(Incident aggregate, String foreignUuid) => AddSubjectToIncident(
        aggregate,
        foreignUuid,
      );
}
