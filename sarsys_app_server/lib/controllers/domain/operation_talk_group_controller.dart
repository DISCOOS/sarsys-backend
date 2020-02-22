import 'package:aqueduct/aqueduct.dart';
import 'package:sarsys_app_server/controllers/eventsource/entity_controller.dart';
import 'package:sarsys_domain/sarsys_domain.dart' as sar;
import 'package:sarsys_app_server/validation/validation.dart';

/// A ResourceController that handles
/// [/api/incidents/{uuid}/subjects](http://localhost/api/client.html#/TalkGroup) requests
class TalkGroupController extends EntityController<sar.OperationCommand, sar.Operation> {
  TalkGroupController(sar.OperationRepository repository, JsonValidation validation)
      : super(repository, "TalkGroup", "talkgroups", validation: validation, tag: 'Operations > Talkgroups');

  @override
  sar.OperationCommand onCreate(String uuid, String type, Map<String, dynamic> data) => sar.AddTalkGroup(uuid, data);

  @override
  sar.OperationCommand onUpdate(String uuid, String type, Map<String, dynamic> data) => sar.UpdateTalkGroup(uuid, data);

  @override
  sar.OperationCommand onDelete(String uuid, String type, Map<String, dynamic> data) => sar.RemoveTalkGroup(uuid, data);

  //////////////////////////////////
  // Documentation
  //////////////////////////////////

  /// TalkGroup - Entity object
  @override
  APISchemaObject documentEntityObject(APIDocumentContext context) => APISchemaObject.object(
        {
          "id": context.schema['ID']..description = "TalkGroup id (unique in Operation only)",
          "name": APISchemaObject.boolean()..description = "Talkgroup name",
          "type": documentType(),
        },
      )
        ..description = "TalkGroup Schema (value object)"
        ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
        ..required = [
          'id',
          'name',
          'type',
        ];

  APISchemaObject documentType() => APISchemaObject.string()
    ..description = "Talkgroup type"
    ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
    ..enumerated = [
      'tetra',
      'marine',
      'analog',
    ];
}
