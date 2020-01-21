import 'package:sarsys_app_server/controllers/eventsource/controllers.dart';
import 'package:sarsys_app_server/domain/incident/incident.dart';
import 'package:sarsys_app_server/domain/operation/operation.dart' as sar;
import 'package:sarsys_app_server/domain/subject/commands.dart';
import 'package:sarsys_app_server/domain/subject/subject.dart';
import 'package:sarsys_app_server/sarsys_app_server.dart';
import 'package:sarsys_app_server/validation/validation.dart';

/// A ResourceController that handles
/// [/api/incidents](http://localhost/api/client.html#/Incident) requests
class IncidentController extends AggregateController<IncidentCommand, Incident> {
  IncidentController(IncidentRepository repository, RequestValidator validator)
      : super(repository, validator: validator);

  @override
  IncidentCommand onCreate(Map<String, dynamic> data) => RegisterIncident(data);

  @override
  IncidentCommand onUpdate(Map<String, dynamic> data) => UpdateIncidentInformation(data);

  @override
  IncidentCommand onDelete(Map<String, dynamic> data) => DeleteIncident(data);

  //////////////////////////////////
  // Documentation
  //////////////////////////////////

  /// Incident - Aggregate root
  @override
  APISchemaObject documentAggregateRoot(APIDocumentContext context) => APISchemaObject.object(
        {
          "uuid": context.schema['UUID']..description = "Unique incident id",
          "name": APISchemaObject.string()..description = "Name of incident scene",
          "summary": APISchemaObject.string()..description = "Situation summary",
          "type": documentType(),
          "status": documentStatus(),
          "resolution": documentResolution(),
          "transitions": documentTransitions(),
          "occurred": APISchemaObject.string()
            ..description = "When Incident occurred"
            ..format = 'date-time',
          "clues": APISchemaObject.array(ofSchema: context.schema['Clue'])
            ..description = "List of Clues for planning and response",
          "subjects": APISchemaObject.array(ofSchema: context.schema['UUID'])
            ..description = "List of uuids of Subjects impacted by this Incident",
          "operations": APISchemaObject.array(ofSchema: context.schema['UUID'])
            ..description = "List of uuids of Operations responding to this Incident",
        },
      )
        ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
        // POST only
        ..required = [
          'uuid',
          'name',
          'summary',
          'type',
          'occurred',
        ];

  APISchemaObject documentType() => APISchemaObject.string()
    ..description = "Incident type"
    ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
    ..enumerated = [
      'lost',
      'distress',
      'disaster',
      'other',
    ];

  APISchemaObject documentTransitions() => APISchemaObject.array(ofType: APIType.object)
    ..items = APISchemaObject.object({
      "status": documentStatus(),
      "resolution": documentResolution(),
      "timestamp": APISchemaObject.string()
        ..description = "When transition occured"
        ..format = 'date-time',
    })
    ..isReadOnly = true
    ..description = "State transitions (read only)"
    ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed;

  /// IncidentStatus - Value Object
  APISchemaObject documentStatus() => APISchemaObject.string()
    ..description = "Incident status"
    ..defaultValue = "registered"
    ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
    ..enumerated = [
      'registered',
      'handling',
      'closed',
    ];

  /// IncidentResolution - Value Object
  APISchemaObject documentResolution() => APISchemaObject.string()
    ..description = "Incident resolution"
    ..defaultValue = "unresolved"
    ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
    ..enumerated = [
      'unresolved',
      'cancelled',
      'duplicate',
      'resolved',
    ];
}

/// Implement controller for field `operations` in [Incident]
class IncidentOperationsController
    extends AggregateListController<sar.OperationCommand, sar.Operation, IncidentCommand, Incident> {
  IncidentOperationsController(
    IncidentRepository primary,
    sar.OperationRepository foreign,
    RequestValidator validator,
  ) : super('operations', primary, foreign, validator);

  @override
  sar.RegisterOperation onCreate(String uuid, Map<String, dynamic> data) => sar.RegisterOperation(data);

  @override
  AddOperationToIncident onCreated(Incident aggregate, String foreignUuid) => AddOperationToIncident(
        aggregate,
        foreignUuid,
      );
}

/// Implement controller for field `subjects` in [Incident]
class IncidentSubjectController extends AggregateListController<SubjectCommand, Subject, IncidentCommand, Incident> {
  IncidentSubjectController(
    IncidentRepository primary,
    SubjectRepository foreign,
    RequestValidator validator,
  ) : super('subjects', primary, foreign, validator);

  @override
  RegisterSubject onCreate(String uuid, Map<String, dynamic> data) => RegisterSubject(data);

  @override
  AddSubjectToIncident onCreated(Incident aggregate, String foreignUuid) => AddSubjectToIncident(
        aggregate,
        foreignUuid,
      );
}
