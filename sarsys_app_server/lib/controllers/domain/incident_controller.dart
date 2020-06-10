import 'package:sarsys_app_server/controllers/event_source/controllers.dart';
import 'package:sarsys_domain/sarsys_domain.dart' hide Operation;
import 'package:sarsys_app_server/sarsys_app_server.dart';
import 'package:sarsys_app_server/validation/validation.dart';

/// A ResourceController that handles
/// [/api/incidents](http://localhost/api/client.html#/Incident) requests
class IncidentController extends AggregateController<IncidentCommand, Incident> {
  IncidentController(IncidentRepository repository, JsonValidation validation)
      : super(repository,
            tag: "Incidents",
            readOnly: const [
              'clues',
              'messages',
              'transitions',
            ],
            validation: validation);

  @override
  @Operation.get()
  Future<Response> getAll({
    @Bind.query('offset') int offset = 0,
    @Bind.query('limit') int limit = 20,
    @Bind.query('deleted') bool deleted = false,
  }) {
    return super.getAll(
      offset: offset,
      limit: limit,
      deleted: deleted,
    );
  }

  @override
  @Operation.get('uuid')
  Future<Response> getByUuid(@Bind.path('uuid') String uuid) {
    return super.getByUuid(uuid);
  }

  @override
  @Operation.post()
  Future<Response> create(@Bind.body() Map<String, dynamic> data) {
    return super.create(data);
  }

  @override
  @Operation('PATCH', 'uuid')
  Future<Response> update(
    @Bind.path('uuid') String uuid,
    @Bind.body() Map<String, dynamic> data,
  ) {
    return super.update(uuid, data);
  }

  @override
  @Operation('DELETE', 'uuid')
  Future<Response> delete(
    @Bind.path('uuid') String uuid, {
    @Bind.body() Map<String, dynamic> data,
  }) {
    return super.delete(uuid, data: data);
  }

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
          "exercise": APISchemaObject.boolean()..description = "Exercise flag",
          "status": documentStatus(),
          "resolution": documentResolution(),
          "occurred": APISchemaObject.string()
            ..description = "When Incident occurred"
            ..format = 'date-time',
          "transitions": APISchemaObject.array(ofSchema: documentTransition())
            ..isReadOnly = true
            ..description = "State transitions (read only)",
          "clues": APISchemaObject.array(ofSchema: context.schema['Clue'])
            ..isReadOnly = true
            ..description = "List of Clues for planning and response",
          "subjects": APISchemaObject.array(ofSchema: context.schema['UUID'])
            ..isReadOnly = true
            ..description = "List of uuids of Subjects impacted by this Incident",
          "operations": APISchemaObject.array(ofSchema: context.schema['UUID'])
            ..isReadOnly = true
            ..description = "List of uuids of Operations responding to this Incident",
          "messages": APISchemaObject.array(ofSchema: context.schema['Message'])
            ..isReadOnly = true
            ..description = "List of messages added to Incident",
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

  APISchemaObject documentTransition() => APISchemaObject.object({
        "status": documentStatus(),
        "resolution": documentResolution(),
        "timestamp": APISchemaObject.string()
          ..description = "When transition occurred"
          ..format = 'date-time',
      })
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
