import 'package:sarsys_app_server/controllers/entity_controller.dart';
import 'package:sarsys_app_server/domain/incident/aggregate.dart';
import 'package:sarsys_app_server/domain/incident/commands.dart';
import 'package:sarsys_app_server/domain/incident/repository.dart';
import 'package:sarsys_app_server/sarsys_app_server.dart';
import 'package:sarsys_app_server/validation/validation.dart';

/// A ResourceController that handles
/// [/api/incidents/{uuid}/subjects](http://localhost/api/client.html#/Subject) requests
class SubjectController extends EntityController<IncidentCommand, Incident> {
  SubjectController(IncidentRepository repository, RequestValidator validator)
      : super(repository, "Subject", "subjects", validator: validator);

  @override
  IncidentCommand create(String uuid, String type, Map<String, dynamic> data) => CreateSubject(uuid, data);

  @override
  IncidentCommand update(String uuid, String type, Map<String, dynamic> data) => UpdateSubject(uuid, data);

  @override
  IncidentCommand delete(String uuid, String type, Map<String, dynamic> data) => DeleteSubject(uuid, data);

  //////////////////////////////////
  // Documentation
  //////////////////////////////////

  /// Subject - Entity object
  @override
  APISchemaObject documentEntityObject(APIDocumentContext context) => APISchemaObject.object(
        {
          "id": APISchemaObject.integer()
            ..description = "Subject id (unique in Incident only)"
            ..defaultValue = 1,
          // TODO: Subject - replace name with reference to PII
          "name": APISchemaObject.string()..description = "Subject name",
          "situation": APISchemaObject.string()..description = "Subject situation",
          "type": APISchemaObject.string()
            ..description = "Subject type"
            ..enumerated = [
              'person',
              'vehicle',
              'other',
            ],
          "location": context.schema['Location']..description = "Rescue or assitance location",
        },
      )
        ..description = "Objective Schema"
        ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
        ..required = [
          'name',
          'type',
          'situation',
          'location',
        ];
}
