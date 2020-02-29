import 'package:sarsys_app_server/controllers/event_source/aggregate_controller.dart';
import 'package:sarsys_domain/sarsys_domain.dart' hide Operation;
import 'package:sarsys_app_server/sarsys_app_server.dart';
import 'package:sarsys_app_server/validation/validation.dart';

/// A ResourceController that handles
/// [/api/incidents/{uuid}/personnels](http://localhost/api/client.html#/Personnel) requests
class PersonnelController extends AggregateController<PersonnelCommand, Personnel> {
  PersonnelController(PersonnelRepository repository, JsonValidation validation)
      : super(repository,
            validation: validation,
            readOnly: const [
              'operation',
              'tracking',
              'transitions',
              'messages',
            ],
            tag: 'Personnels');

  @override
  @Operation.get()
  Future<Response> getAll({
    @Bind.query('offset') int offset = 0,
    @Bind.query('limit') int limit = 20,
  }) {
    return super.getAll(offset: offset, limit: limit);
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
  PersonnelCommand onCreate(Map<String, dynamic> data) => CreatePersonnel(data);

  @override
  PersonnelCommand onUpdate(Map<String, dynamic> data) => UpdatePersonnelInformation(data);

  @override
  PersonnelCommand onDelete(Map<String, dynamic> data) => DeletePersonnel(data);

  //////////////////////////////////
  // Documentation
  //////////////////////////////////

  @override
  APISchemaObject documentAggregateRoot(APIDocumentContext context) => APISchemaObject.object(
        {
          "uuid": context.schema['UUID']..description = "Unique Personnel id",
          "operation": APISchemaObject.object({
            "uuid": context.schema['UUID'],
          })
            ..description = "Operation which this personnel is allocated to"
            ..isReadOnly = true
            ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed,
          "fname": APISchemaObject.string()..description = "First name",
          "lname": APISchemaObject.string()..description = "Last name",
          "phone": APISchemaObject.string()..description = "Phone number",
          "affiliation": context.schema["Affiliation"],
          "status": documentStatus(),
          "transitions": APISchemaObject.array(ofSchema: documentTransition())
            ..isReadOnly = true
            ..description = "State transitions (read only)",
          "tracking": APISchemaObject.object({
            "uuid": context.schema['UUID'],
          })
            ..description = "Tracking object for this personnel"
            ..isReadOnly = true,
          "messages": APISchemaObject.array(ofSchema: context.schema['Message'])
            ..isReadOnly = true
            ..description = "List of messages added to Personnel",
        },
      )
        ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
        ..required = [
          'uuid',
        ];

  APISchemaObject documentTransition() => APISchemaObject.object({
        "status": documentStatus(),
        "timestamp": APISchemaObject.string()
          ..description = "When transition occured"
          ..format = 'date-time',
      })
        ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed;

  /// Personnel Status - Value Object
  APISchemaObject documentStatus() => APISchemaObject.string()
    ..description = "Personnel status"
    ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
    ..defaultValue = "mobilized"
    ..enumerated = [
      'mobilized',
      'deployed',
      'retired',
    ];

  @override
  Map<String, APISchemaObject> documentValues(APIDocumentContext context) => {
        "Affiliation": APISchemaObject.object({
          "organisation": APISchemaObject.object({'uuid': context.schema["UUID"]}),
          "division": APISchemaObject.object({'uuid': context.schema["UUID"]}),
          "department": APISchemaObject.object({'uuid': context.schema["UUID"]}),
        })
          ..isReadOnly = true
          ..description = "Affiliation information"
          ..required = ['organisation']
          ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed,
      };
}
