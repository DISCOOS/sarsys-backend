import 'package:sarsys_app_server/controllers/eventsource/entity_controller.dart';
import 'package:sarsys_app_server/domain/incident/aggregate.dart';
import 'package:sarsys_app_server/domain/incident/commands.dart';
import 'package:sarsys_app_server/domain/incident/repository.dart';
import 'package:sarsys_app_server/sarsys_app_server.dart';
import 'package:sarsys_app_server/validation/validation.dart';

/// A ResourceController that handles
/// [/api/incidents/{uuid}/Clues](http://localhost/api/client.html#/Clue) requests
class ClueController extends EntityController<IncidentCommand, Incident> {
  ClueController(IncidentRepository repository, JsonValidation validator)
      : super(repository, "Clue", "clues", validator: validator, tag: "Incidents");

  @override
  IncidentCommand onCreate(String uuid, String type, Map<String, dynamic> data) => AddClue(uuid, data);

  @override
  IncidentCommand onUpdate(String uuid, String type, Map<String, dynamic> data) => UpdateClue(uuid, data);

  @override
  IncidentCommand onDelete(String uuid, String type, Map<String, dynamic> data) => RemoveClue(uuid, data);

  //////////////////////////////////
  // Documentation
  //////////////////////////////////

  /// Clue - Entity object
  @override
  APISchemaObject documentEntityObject(APIDocumentContext context) => APISchemaObject.object(
        {
          "id": context.schema['ID']..description = "Clue id (unique in Incident only)",
          "name": APISchemaObject.string()..description = "Clue name",
          "description": APISchemaObject.string()..description = "Clue description",
          "type": documentType(),
          "quality": documentQuality(),
          "location": context.schema['Location']..description = "Rescue or assitance location",
        },
      )
        ..description = "Objective Schema"
        ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
        ..required = [
          'id',
          'name',
          'type',
          'quality',
        ];

  APISchemaObject documentQuality() => APISchemaObject.string()
    ..description = "Clue quality assessment"
    ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
    ..enumerated = [
      'confirmed',
      'plausable',
      'possible',
      'unlikely',
      'rejected',
    ];

  APISchemaObject documentType() => APISchemaObject.string()
    ..description = "Clue type"
    ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
    ..enumerated = [
      'find',
      'condition',
      'observation',
      'circumstance',
    ];
}
