import 'package:sarsys_domain/sarsys_domain.dart' hide Operation;
import 'package:sarsys_app_server/sarsys_app_server.dart';

/// A ResourceController that handles
/// [/api/incidents/{uuid}/Clues](http://localhost/api/client.html#/Clue) requests
class ClueController extends EntityController<IncidentCommand, Incident> {
  ClueController(IncidentRepository repository, JsonValidation validation)
      : super(repository, "Clue", "clues", validation: validation, tag: "Incidents > Clues");

  @override
  @Operation.get('uuid')
  Future<Response> getAll(@Bind.path('uuid') String uuid) {
    return super.getAll(uuid);
  }

  @override
  @Operation.get('uuid', 'id')
  Future<Response> getById(
    @Bind.path('uuid') String uuid,
    @Bind.path('id') String id,
  ) {
    return super.getById(uuid, id);
  }

  @override
  @Operation.post('uuid')
  Future<Response> create(
    @Bind.path('uuid') String uuid,
    @Bind.body() Map<String, dynamic> data,
  ) {
    return super.create(uuid, data);
  }

  @override
  @Operation('PATCH', 'uuid', 'id')
  Future<Response> update(
    @Bind.path('uuid') String uuid,
    @Bind.path('id') String id,
    @Bind.body() Map<String, dynamic> data,
  ) {
    return super.update(uuid, id, data);
  }

  @override
  @Operation('DELETE', 'uuid', 'id')
  Future<Response> delete(
    @Bind.path('uuid') String uuid,
    @Bind.path('id') String id, {
    @Bind.body() Map<String, dynamic> data,
  }) {
    return super.delete(uuid, id, data: data);
  }

  @override
  IncidentCommand onCreate(String uuid, String type, Map<String, dynamic> data) => AddIncidentClue(uuid, data);

  @override
  IncidentCommand onUpdate(String uuid, String type, Map<String, dynamic> data) => UpdateIncidentClue(uuid, data);

  @override
  IncidentCommand onDelete(String uuid, String type, Map<String, dynamic> data) => RemoveIncidentClue(uuid, data);

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
