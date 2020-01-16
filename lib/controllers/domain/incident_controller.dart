import 'package:sarsys_app_server/controllers/eventsource/aggregate_controller.dart';
import 'package:sarsys_app_server/domain/incident/incident.dart';
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
          "uuid": APISchemaObject.string(format: 'uuid')
            ..format = 'uuid'
            ..description = "Unique incident id",
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
          "subjects": APISchemaObject.array(ofType: APIType.string)
            ..description = "List of uuids of Subjects impacted by this Incident"
            ..format = 'uuid',
          "operations": APISchemaObject.array(ofType: APIType.string)
            ..description = "List of uuids of Operations responding to this Incident"
            ..format = 'uuid',
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
