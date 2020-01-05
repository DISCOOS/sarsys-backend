import 'package:sarsys_app_server/controllers/crud_controller.dart';
import 'package:sarsys_app_server/domain/unit/aggregate.dart';
import 'package:sarsys_app_server/domain/unit/commands.dart';
import 'package:sarsys_app_server/domain/unit/repository.dart';
import 'package:sarsys_app_server/sarsys_app_server.dart';

/// A ResourceController that handles
/// [/api/units](http://localhost/api/client.html#/Unit) requests
class UnitController extends CRUDController<UnitCommand, Unit> {
  UnitController(UnitRepository repository) : super(repository);

  @override
  UnitCommand create(Map<String, dynamic> data) => CreateUnit(data);

  @override
  UnitCommand update(Map<String, dynamic> data) => UpdateUnit(data);

  //////////////////////////////////
  // Documentation
  //////////////////////////////////

  static const passCodesDescription = "Users with an admin role are allowed to get all units. "
      "All other roles will get access to units based on given passcodes. All available fields are "
      "only returned for units with passcode which match the value given in header 'X-Passcode'. "
      "Rquests without header 'X-Passcode', or with an invalid passcode, will get units containing "
      "fields [uuid] and [name] only. Brute-force attacks are banned for a lmitied time without any "
      "feedback. When banned, all units will contain fields [uuid] and [name] only, regardless of "
      "the value in 'X-Passcode'.";

  @override
  String documentOperationDescription(APIDocumentContext context, Operation operation) {
    String desc = "${documentOperationSummary(context, operation)}. ";
    switch (operation.method) {
      case "GET":
        desc = "$desc $passCodesDescription";
        break;
    }
    return desc;
  }

  /// Unit - Aggregate root
  @override
  APISchemaObject documentAggregateRoot(APIDocumentContext context) => APISchemaObject.object(
        {
          "uuid": APISchemaObject.string()
            ..format = 'uuid'
            ..description = "Unique unit id",
          "operationUuid": APISchemaObject.string()
            ..format = 'uuid'
            ..description = "Uuid of Operation which this Unit is mobilized for",
          /* TODO: Make Tracking an Value Object in ReadModel - manage tracking uuid internally
          "tracking": APISchemaObject.string()
            ..format = 'uuid'
            ..description = "Tracking Uuid of this unit",
           */
          "number": APISchemaObject.integer()..description = "Unit number",
          "type": documentType(),
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
          "phone": APISchemaObject.string()..description = "Phone number",
          "callsign": APISchemaObject.string()..description = "Unit callsign",
          "personnel": APISchemaObject.array(ofType: APIType.string)
            ..description = "List of uuid of Personnel assigned to this unit"
            ..format = 'uuid',
          "created": APISchemaObject.string()
            ..description = "When Unit was created"
            ..format = 'date-time',
          "changed": APISchemaObject.string()
            ..description = "When Unit was last changed"
            ..format = 'date-time',
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
