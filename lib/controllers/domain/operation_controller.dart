import 'package:sarsys_app_server/controllers/eventsource/aggregate_controller.dart';
import 'package:sarsys_app_server/domain/operation/operation.dart' as sar;
import 'package:sarsys_app_server/domain/operation/repository.dart';
import 'package:sarsys_app_server/sarsys_app_server.dart';
import 'package:sarsys_app_server/validation/validation.dart';

/// A ResourceController that handles
/// [/api/operations](http://localhost/api/client.html#/Operation) requests
class OperationController extends AggregateController<sar.OperationCommand, sar.Operation> {
  OperationController(OperationRepository repository, RequestValidator validator)
      : super(repository, validator: validator);

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
          "uuid": APISchemaObject.string()
            ..format = 'uuid'
            ..description = "Unique Operation id",
          "name": APISchemaObject.string()..description = "Name of operation scene",
          "type": documentType(),
          "status": documentStatus(),
          "resolution": documentOperationResolution(),
          "transitions": documentTransitions(),
          "reference": APISchemaObject.string()..description = "External reference from requesting authority",
          "justification": APISchemaObject.string()..description = "Justification for responding",
          "talkgroups": APISchemaObject.array(ofSchema: context.schema['TalkGroup'])
            ..description = "List of talk gropus in use",
          "ipp": context.schema['Location']..description = "Initial planning point",
          "meetup": context.schema['Location']..description = "On scene meeting point",
          "objectives": APISchemaObject.array(ofSchema: context.schema['Objective'])
            ..description = "List of Operation objectives",
          "missions": APISchemaObject.array(ofType: APIType.string)
            ..description = "List of uuid of Missions executed by this operation"
            ..format = 'uuid',
          "units": APISchemaObject.array(ofType: APIType.string)
            ..description = "List of uuid of Units mobilized for this operation"
            ..format = 'uuid',
          "commander": APISchemaObject.array(ofType: APIType.string)
            ..description = "Uuid of personnel in command"
            ..format = 'uuid',
          "personnels": APISchemaObject.array(ofType: APIType.string)
            ..description = "List of uuid of Personnels mobilized for this operation"
            ..format = 'uuid',
          "passcodes": context.schema['PassCodes']..description = "Passcodes for Operation access rights",
        },
      )
        ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
        // POST only
        ..required = [
          'uuid',
          'incidentUuid',
          'name',
          'type',
          'ipp',
          'meetup',
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
        "Position": documentPosition(),
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
          "position": APISchemaObject.array(ofSchema: context.schema['Position'])..description = "Location position",
          "address": APISchemaObject.array(ofSchema: context.schema['Address'])..description = "Location address",
          "description": APISchemaObject.string()..description = "Location description",
        },
      )
        ..description = "Location Schema (value object)"
        ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
        ..required = [
          'position',
        ];

  /// Point - Value object
  APISchemaObject documentPosition() => APISchemaObject.object(
        {
          "lat": APISchemaObject.number()..description = "Latitude in decimal degrees",
          "lon": APISchemaObject.number()..description = "Longitude in decimal degrees",
          "alt": APISchemaObject.number()..description = "Altitude above sea level in meters",
          "acc": APISchemaObject.number()..description = "Accuracy in meters",
          "timestamp": APISchemaObject.string()
            ..description = "Timestamp in ISO8601 Date Time String Format"
            ..format = "date-time",
          "type": documentPositionType(),
        },
      )
        ..description = "Position Schema (value object)"
        ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
        ..required = [
          'lat',
          'lon',
        ];

  APISchemaObject documentPositionType() => APISchemaObject.string()
    ..description = "Position type"
    ..defaultValue = "manual"
    ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
    ..enumerated = [
      'manual',
      'device',
      'personnel',
      'aggregated',
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
        ..description = "Position Schema (value object)"
        ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
        ..required = [
          'lat',
          'lon',
          'timestamp',
        ];
}
