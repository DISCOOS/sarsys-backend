import 'package:sarsys_app_server/controllers/entity_controller.dart';
import 'package:sarsys_app_server/domain/operation/aggregate.dart' as sar;
import 'package:sarsys_app_server/domain/operation/commands.dart';
import 'package:sarsys_app_server/domain/operation/repository.dart';
import 'package:sarsys_app_server/sarsys_app_server.dart';
import 'package:sarsys_app_server/validation/validation.dart';

/// A ResourceController that handles
/// [/api/incidents/{uuid}/personnels](http://localhost/api/client.html#/Personnel) requests
class PersonnelController extends EntityController<OperationCommand, sar.Operation> {
  PersonnelController(OperationRepository repository, RequestValidator validator)
      : super(repository, "Personnel", "personnels", validator: validator);

  @override
  OperationCommand create(String uuid, String type, Map<String, dynamic> data) => MobilizePersonnel(uuid, data);

  @override
  OperationCommand update(String uuid, String type, Map<String, dynamic> data) => UpdatePersonnelInformation(
        uuid,
        data,
      );

  @override
  OperationCommand delete(String uuid, String type, Map<String, dynamic> data) => RetirePersonnel(uuid, data);

  //////////////////////////////////
  // Documentation
  //////////////////////////////////

  @override
  APISchemaObject documentEntityObject(APIDocumentContext context) => APISchemaObject.object(
        {
          "id": APISchemaObject.integer()..description = "Personnel id (unique in Operation only)",
          "fname": APISchemaObject.string()..description = "First name",
          "lname": APISchemaObject.string()..description = "Last name",
          "phone": APISchemaObject.string()..description = "Phone number",
          /* TODO: Add affiliation
          "affiliation": context.schema["Affiliation"]
          */
          "status": documentStatus(),
          "transitions": APISchemaObject.array(ofType: APIType.object)
            ..items = APISchemaObject.object({
              "status": documentStatus(),
              "timestamp": APISchemaObject.string()
                ..description = "When transition occured"
                ..format = 'date-time',
            })
            ..isReadOnly = true
            ..description = "State transitions (read only)"
            ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed,
          /* TODO: Make Tracking an Value Object in ReadModel - manage tracking uuid internally
          "tracking": APISchemaObject.string()
            ..format = 'uuid'
            ..description = "Tracking Uuid of this unit",
           */
        },
      )
        ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
        ..required = [
          'id',
          'fname',
          'lname',
          'status',
        ];

  /// Personnel Status - Value Object
  APISchemaObject documentStatus() => APISchemaObject.string()
    ..description = "Personnel status"
    ..defaultValue = "mobilized"
    ..enumerated = [
      'mobilized',
      'deployed',
      'retired',
    ];
}
