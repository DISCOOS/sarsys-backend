import 'package:sarsys_app_server/controllers/aggregate_controller.dart';
import 'package:sarsys_app_server/domain/unit/aggregate.dart';
import 'package:sarsys_app_server/domain/unit/commands.dart';
import 'package:sarsys_app_server/domain/unit/repository.dart';
import 'package:sarsys_app_server/sarsys_app_server.dart';

/// A ResourceController that handles
/// [/api/units](http://localhost/api/client.html#/Unit) requests
class UnitController extends AggregateController<UnitCommand, Unit> {
  UnitController(UnitRepository repository) : super(repository);

  @override
  UnitCommand create(Map<String, dynamic> data) => MobilizeUnit(data);

  @override
  UnitCommand update(Map<String, dynamic> data) => UpdateUnitInformation(data);

  //////////////////////////////////
  // Documentation
  //////////////////////////////////

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
