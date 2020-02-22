import 'package:sarsys_app_server/controllers/eventsource/entity_controller.dart';
import 'package:sarsys_domain/sarsys_domain.dart' as sar;
import 'package:sarsys_app_server/sarsys_app_server.dart';
import 'package:sarsys_app_server/validation/validation.dart';

/// A ResourceController that handles
/// [/api/incidents/{uuid}/objectives](http://localhost/api/client.html#/Objective) requests
class ObjectiveController extends EntityController<sar.OperationCommand, sar.Operation> {
  ObjectiveController(sar.OperationRepository repository, JsonValidation validation)
      : super(repository, "Objective", "objectives", validation: validation, tag: 'Operations > Objectives');

  @override
  sar.OperationCommand onCreate(String uuid, String type, Map<String, dynamic> data) => sar.AddObjective(uuid, data);

  @override
  sar.OperationCommand onUpdate(String uuid, String type, Map<String, dynamic> data) => sar.UpdateObjective(uuid, data);

  @override
  sar.OperationCommand onDelete(String uuid, String type, Map<String, dynamic> data) => sar.RemoveObjective(uuid, data);

  //////////////////////////////////
  // Documentation
  //////////////////////////////////

  /// Objective - Entity object
  @override
  APISchemaObject documentEntityObject(APIDocumentContext context) => APISchemaObject.object(
        {
          "id": context.schema['ID']..description = "Objective id (unique in Operation only)",
          "name": APISchemaObject.string()..description = "Objective name",
          "description": APISchemaObject.string()..description = "Objective description",
          "type": APISchemaObject.string()
            ..description = "Objective type"
            ..enumerated = [
              'locate',
              'rescue',
              'assist',
            ],
          "location": APISchemaObject.array(ofSchema: context.schema['Location'])
            ..description = "Rescue or assitance location",
          "resolution": documentObjectiveResolution(),
        },
      )
        ..description = "Objective Schema (entity object)"
        ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
        ..required = [
          'name',
          'type',
          'resolution',
        ];

  /// ObjectiveResolution - Value object
  APISchemaObject documentObjectiveResolution() => APISchemaObject.string()
    ..description = "Objective resolution"
    ..defaultValue = "unresolved"
    ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
    ..enumerated = [
      'unresolved',
      'cancelled',
      'duplicate',
      'resolved',
    ];
}
