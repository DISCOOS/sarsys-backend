import 'package:sarsys_app_server/controllers/eventsource/aggregate_controller.dart';
import 'package:sarsys_app_server/domain/unit/unit.dart';
import 'package:sarsys_app_server/sarsys_app_server.dart';
import 'package:sarsys_app_server/validation/validation.dart';

/// A ResourceController that handles
/// [/api/incidents/{uuid}/units](http://localhost/api/client.html#/Unit) requests
class UnitController extends AggregateController<UnitCommand, Unit> {
  UnitController(UnitRepository repository, JsonValidation validation)
      : super(repository,
            validation: validation,
            readOnly: const [
              'operation',
              'messages',
              'transitions',
            ],
            tag: 'Units');

  @override
  UnitCommand onCreate(Map<String, dynamic> data) => CreateUnit(data);

  @override
  UnitCommand onUpdate(Map<String, dynamic> data) => UpdateUnitInformation(data);

  @override
  UnitCommand onDelete(Map<String, dynamic> data) => DeleteUnit(data);

  //////////////////////////////////
  // Documentation
  //////////////////////////////////

  @override
  APISchemaObject documentAggregateRoot(APIDocumentContext context) => APISchemaObject.object(
        {
          "uuid": context.schema['UUID']..description = "Unique unit id",
          "operation": APISchemaObject.object({
            "uuid": context.schema['UUID']..description = "Operation uuid which this unit belongs to",
          })
            ..isReadOnly = true
            ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed,
          "type": documentType(),
          "number": APISchemaObject.integer()..description = "Unit number",
          "affiliation": context.schema["Affiliation"],
          "phone": APISchemaObject.string()..description = "Unit phone number",
          "callsign": APISchemaObject.string()..description = "Unit callsign",
          "status": documentStatus(),
          "tracking": context.schema['UUID'],
          "transitions": documentTransitions(),
          "personnels": APISchemaObject.array(ofSchema: context.schema['UUID'])
            ..description = "List of uuid of Personnels assigned to this unit",
          "messages": APISchemaObject.array(ofSchema: context.schema['Message'])
            ..isReadOnly = true
            ..description = "List of messages added to Incident",
        },
      )
        ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
        ..required = [
          'uuid',
          'type',
          'status',
          'number',
          'callsign',
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

  /// Unit type - Value Object
  APISchemaObject documentType() => APISchemaObject.string()
    ..description = "Unit type"
    ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
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
    ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
    ..defaultValue = "mobilized"
    ..enumerated = [
      'mobilized',
      'deployed',
      'retired',
    ];
}
