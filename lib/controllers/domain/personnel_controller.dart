import 'package:sarsys_app_server/controllers/eventsource/aggregate_controller.dart';
import 'package:sarsys_app_server/domain/personnel/personnel.dart';
import 'package:sarsys_app_server/sarsys_app_server.dart';
import 'package:sarsys_app_server/validation/validation.dart';

/// A ResourceController that handles
/// [/api/incidents/{uuid}/personnels](http://localhost/api/client.html#/Personnel) requests
class PersonnelController extends AggregateController<PersonnelCommand, Personnel> {
  PersonnelController(PersonnelRepository repository, JsonValidation validation)
      : super(repository, validation: validation, readOnly: const ['operation'], tag: 'Personnels');

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
            "uuid": context.schema['UUID']..description = "Operation uuid which this mission belongs to",
          })
            ..isReadOnly = true
            ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed,
          "fname": APISchemaObject.string()..description = "First name",
          "lname": APISchemaObject.string()..description = "Last name",
          "phone": APISchemaObject.string()..description = "Phone number",
          "affiliation": context.schema["Affiliation"],
          "status": documentStatus(),
          "transitions": documentTransitions(),
          /* TODO: Make Tracking an Value Object in ReadModel - manage tracking uuid internally
          "tracking": APISchemaObject.string()
            ..format = 'uuid'
            ..description = "Tracking Uuid of this unit",
           */
        },
      )
        ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
        ..required = [
          'uuid',
          'fname',
          'lname',
          'status',
        ];

  APISchemaObject documentTransitions() => APISchemaObject.array(ofType: APIType.object)
    ..items = APISchemaObject.object({
      "status": documentStatus(),
      "timestamp": APISchemaObject.string()
        ..description = "When transition occured"
        ..format = 'date-time',
    })
    ..isReadOnly = true
    ..description = "State transitions (read only)"
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
