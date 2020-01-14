import 'package:sarsys_app_server/controllers/entity_controller.dart';
import 'package:sarsys_app_server/domain/operation/aggregate.dart' as sar;
import 'package:sarsys_app_server/domain/operation/commands.dart';
import 'package:sarsys_app_server/domain/operation/repository.dart';
import 'package:sarsys_app_server/sarsys_app_server.dart';
import 'package:sarsys_app_server/validation/validation.dart';

/// A ResourceController that handles
/// [/api/incidents/{uuid}/units](http://localhost/api/client.html#/Unit) requests
class UnitController extends EntityController<OperationCommand, sar.Operation> {
  UnitController(OperationRepository repository, RequestValidator validator)
      : super(repository, "Unit", "units", validator: validator);

  @override
  OperationCommand create(String uuid, String type, Map<String, dynamic> data) => MobilizeUnit(uuid, data);

  @override
  OperationCommand update(String uuid, String type, Map<String, dynamic> data) => UpdateUnitInformation(
        uuid,
        data,
      );

  @override
  OperationCommand delete(String uuid, String type, Map<String, dynamic> data) => RetireUnit(uuid, data);

  //////////////////////////////////
  // Documentation
  //////////////////////////////////

  @override
  APISchemaObject documentEntityObject(APIDocumentContext context) => APISchemaObject.object(
        {
          "id": APISchemaObject.integer()..description = "Unit id (unique in Operation only)",
          "type": documentType(),
          "number": APISchemaObject.integer()..description = "Unit number",
          /* TODO: Add affiliation
          "affiliation": context.schema["Affiliation"]
          */
          "phone": APISchemaObject.string()..description = "Unit phone number",
          "callsign": APISchemaObject.string()..description = "Unit callsign",
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
          "personnel": APISchemaObject.array(ofType: APIType.string)
            ..description = "List of uuid of Unit assigned to this unit"
            ..format = 'uuid',
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
          'operationUuid',
          'number',
          'type',
          'callsign',
        ];

  /// Unit type - Value Object
  APISchemaObject documentType() => APISchemaObject.string()
    ..description = "Unit type"
    ..enumerated = [
      'team',
      'k9',
      'boat',
      'vehicle',
      'snowmobile',
      'atv',
      'commandpost',
      'other',
    ];

  /// Unit Status - Value Object
  APISchemaObject documentStatus() => APISchemaObject.string()
    ..description = "Unit status"
    ..defaultValue = "mobilized"
    ..enumerated = [
      'mobilized',
      'deployed',
      'retired',
    ];
}
