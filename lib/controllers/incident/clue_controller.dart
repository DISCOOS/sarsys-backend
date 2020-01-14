import 'package:sarsys_app_server/controllers/entity_controller.dart';
import 'package:sarsys_app_server/domain/incident/aggregate.dart';
import 'package:sarsys_app_server/domain/incident/commands.dart';
import 'package:sarsys_app_server/domain/incident/repository.dart';
import 'package:sarsys_app_server/sarsys_app_server.dart';
import 'package:sarsys_app_server/validation/validation.dart';

/// A ResourceController that handles
/// [/api/incidents/{uuid}/Clues](http://localhost/api/client.html#/Clue) requests
class ClueController extends EntityController<IncidentCommand, Incident> {
  ClueController(IncidentRepository repository, RequestValidator validator)
      : super(repository, "Clue", "clues", validator: validator);

  @override
  IncidentCommand create(String uuid, String type, Map<String, dynamic> data) => AddClue(uuid, data);

  @override
  IncidentCommand update(String uuid, String type, Map<String, dynamic> data) => UpdateClue(uuid, data);

  @override
  IncidentCommand delete(String uuid, String type, Map<String, dynamic> data) => RemoveClue(uuid, data);

  //////////////////////////////////
  // Documentation
  //////////////////////////////////

  /// Clue - Entity object
  @override
  APISchemaObject documentEntityObject(APIDocumentContext context) => APISchemaObject.object(
        {
          "id": APISchemaObject.integer()..description = "Clue id (unique in Incident only)",
          "name": APISchemaObject.string()..description = "Clue name",
          "description": APISchemaObject.string()..description = "Clue description",
          "type": APISchemaObject.string()
            ..description = "Clue type"
            ..enumerated = [
              'find',
              'condition',
              'observation',
              'circumstance',
            ],
          "quality": APISchemaObject.string()
            ..description = "Clue quality assessment"
            ..enumerated = [
              'confirmed',
              'plausable',
              'possible',
              'unlikely',
              'rejected',
            ],
          "location": APISchemaObject.array(ofSchema: context.schema['Location'])
            ..description = "Rescue or assitance location",
        },
      )
        ..description = "Objective Schema"
        ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
        ..required = [
          'name',
          'type',
          'quality',
        ];
}
