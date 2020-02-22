import 'package:sarsys_app_server/controllers/eventsource/controllers.dart';
import 'package:sarsys_domain/sarsys_domain.dart' as sar;
import 'package:sarsys_app_server/sarsys_app_server.dart';
import 'package:sarsys_app_server/validation/validation.dart';

/// A ResourceController that handles
/// [/api/operations](http://localhost/api/client.html#/Operation) requests
class OperationController extends AggregateController<sar.OperationCommand, sar.Operation> {
  OperationController(sar.OperationRepository repository, JsonValidation validation)
      : super(
          repository,
          validation: validation,
          readOnly: const [
            'incident',
            'objectives',
            'talkgroups',
            'messages',
            'transitions',
          ],
          tag: 'Operations',
        );

  @override
  sar.OperationCommand onCreate(Map<String, dynamic> data) => sar.RegisterOperation(data);

  @override
  sar.OperationCommand onUpdate(Map<String, dynamic> data) => sar.UpdateOperationInformation(data);

  @override
  sar.OperationCommand onDelete(Map<String, dynamic> data) => sar.DeleteOperation(data);

  //////////////////////////////////
  // Documentation
  //////////////////////////////////

  /// Operation - Aggregate root
  @override
  APISchemaObject documentAggregateRoot(APIDocumentContext context) => APISchemaObject.object(
        {
          "uuid": context.schema['UUID']..description = "Unique operation id",
          "incident": APISchemaObject.object({
            "uuid": context.schema['UUID']..description = "Incident uuid which this operation responds to",
          })
            ..isReadOnly = true
            ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed,
          "name": APISchemaObject.string()..description = "Name of operation scene",
          "type": documentType(),
          "status": documentStatus(),
          "resolution": documentOperationResolution(),
          "transitions": documentTransitions(),
          "reference": APISchemaObject.string()..description = "External reference from requesting authority",
          "justification": APISchemaObject.string()..description = "Justification for responding",
          "commander": context.schema['UUID']..description = "Uuid of personnel in command",
          "talkgroups": APISchemaObject.array(ofSchema: context.schema['TalkGroup'])
            ..description = "List of talk gropus in use"
            ..isReadOnly = true,
          "ipp": context.schema['Location']..description = "Initial planning point",
          "meetup": context.schema['Location']..description = "On scene meeting point",
          "objectives": APISchemaObject.array(ofSchema: context.schema['Objective'])
            ..description = "List of Operation objectives"
            ..isReadOnly = true,
          "missions": APISchemaObject.array(ofSchema: context.schema['UUID'])
            ..description = "List of uuid of Missions executed by this operation",
          "units": APISchemaObject.array(ofSchema: context.schema['UUID'])
            ..description = "List of uuid of Units mobilized for this operation",
          "personnels": APISchemaObject.array(ofSchema: context.schema['UUID'])
            ..description = "List of uuid of Personnels mobilized for this operation",
          "passcodes": context.schema['PassCodes']..description = "Passcodes for Operation access rights",
          "messages": APISchemaObject.array(ofSchema: context.schema['Message'])
            ..isReadOnly = true
            ..description = "List of messages added to Operation",
        },
      )
        ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
        // POST only
        ..required = [
          'uuid',
          'name',
          'type',
          'justification',
        ];

  APISchemaObject documentTransitions() => APISchemaObject.array(ofType: APIType.object)
    ..items = APISchemaObject.object({
      "status": documentStatus(),
      "resolution": documentOperationResolution(),
      "timestamp": APISchemaObject.string()
        ..description = "When transition occured"
        ..format = 'date-time',
    })
    ..isReadOnly = true
    ..description = "State transitions (read only)"
    ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed;

  APISchemaObject documentType() => APISchemaObject.string()
    ..description = "Operation type"
    ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
    ..enumerated = [
      'search',
      'rescue',
      'other',
    ];

  @override
  Map<String, APISchemaObject> documentEntities(APIDocumentContext context) => {
        "Address": documentAddress(),
        "Location": documentLocation(context),
      };

  /// OperationStatus - Value object
  APISchemaObject documentStatus() => APISchemaObject.string()
    ..description = "Operation status"
    ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
    ..defaultValue = "planned"
    ..enumerated = [
      'planned',
      'enroute',
      'onscene',
      'finished',
    ];

  /// OperationResolution - Entity object
  APISchemaObject documentOperationResolution() => APISchemaObject.string()
    ..description = "Operation resolution"
    ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
    ..defaultValue = "unresolved"
    ..enumerated = [
      'unresolved',
      'cancelled',
      'duplicate',
      'resolved',
    ];

  /// Location - Value object
  APISchemaObject documentLocation(APIDocumentContext context) => APISchemaObject.object(
        {
          "point": context.schema['Point']..description = "Location point",
          "address": context.schema['Address']..description = "Location address",
          "description": APISchemaObject.string()..description = "Location description",
        },
      )
        ..description = "Location Schema (value object)"
        ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
        ..required = [
          'point',
        ];

  /// Address - Value object
  APISchemaObject documentAddress() => APISchemaObject.object(
        {
          "lines": APISchemaObject.array(ofType: APIType.string)
            ..description = "Pass codes for authorizing access to Operation data"
            ..type = APIType.string,
          "city": APISchemaObject.string()..description = "City name",
          "postalCode": APISchemaObject.string()..description = "Postal, state or zip code",
          "countryCode": APISchemaObject.string()..description = "ISO 3166 country code",
        },
      )
        ..description = "Address Schema (value object)"
        ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
        ..required = [
          'lines',
          'city',
          'postalCode',
          'countryCode',
        ];
}
