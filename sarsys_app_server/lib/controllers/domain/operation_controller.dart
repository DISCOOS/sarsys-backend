import 'package:sarsys_app_server/controllers/domain/schemas.dart';
import 'package:sarsys_app_server/controllers/event_source/controllers.dart';
import 'package:sarsys_domain/sarsys_domain.dart' hide Operation;
import 'package:sarsys_domain/sarsys_domain.dart' as sar;
import 'package:sarsys_app_server/sarsys_app_server.dart';
import 'package:sarsys_app_server/validation/validation.dart';

/// A ResourceController that handles
/// [/api/operations](http://localhost/api/client.html#/Operation) requests
class OperationController extends AggregateController<OperationCommand, sar.Operation> {
  OperationController(OperationRepository repository, JsonValidation validation)
      : super(
          repository,
          validation: validation,
          readOnly: const [
            'units',
            'incident',
            'missions',
            'messages',
            'objectives',
            'talkgroups',
            'personnels',
            'transitions',
          ],
          tag: 'Operations',
        );

  @override
  @Operation.get()
  Future<Response> getAll({
    @Bind.query('offset') int offset = 0,
    @Bind.query('limit') int limit = 20,
    @Bind.query('deleted') bool deleted = false,
  }) {
    return super.getAll(
      offset: offset,
      limit: limit,
      deleted: deleted,
    );
  }

  @override
  @Operation.get('uuid')
  Future<Response> getByUuid(@Bind.path('uuid') String uuid) {
    return super.getByUuid(uuid);
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
  }) async {
    return await withResponseWaitForRuleResult<OperationRemovedFromIncident>(
      await super.delete(uuid, data: data),
    );
  }

  @override
  OperationCommand onCreate(Map<String, dynamic> data) => RegisterOperation(data);

  @override
  OperationCommand onUpdate(Map<String, dynamic> data) => UpdateOperationInformation(data);

  @override
  OperationCommand onDelete(Map<String, dynamic> data) => DeleteOperation(data);

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
          "author": documentAuthor(),
          "status": documentStatus(),
          "resolution": documentOperationResolution(),
          "reference": APISchemaObject.string()..description = "External reference from requesting authority",
          "justification": APISchemaObject.string()..description = "Justification for responding",
          "commander": APISchemaObject.object({
            "uuid": context.schema['UUID'],
          })
            ..description = "Reference to personnel in command",
          "ipp": documentLocation(context)..description = "Initial planning point",
          "meetup": documentLocation(context)..description = "On scene meeting point",
          "passcodes": documentPassCodes()..description = "Passcodes for Operation access rights",
          "transitions": APISchemaObject.array(ofSchema: documentTransition())
            ..isReadOnly = true
            ..description = "State transitions (read only)",
          "talkgroups": APISchemaObject.array(ofSchema: context.schema['TalkGroup'])
            ..description = "List of talk gropus in use",
          "objectives": APISchemaObject.array(ofSchema: context.schema['Objective'])
            ..isReadOnly = true
            ..description = "List of Operation objectives",
          "missions": APISchemaObject.array(ofSchema: context.schema['UUID'])
            ..isReadOnly = true
            ..description = "List of uuid of Missions executed by this operation",
          "units": APISchemaObject.array(ofSchema: context.schema['UUID'])
            ..isReadOnly = true
            ..description = "List of uuid of Units mobilized for this operation",
          "personnels": APISchemaObject.array(ofSchema: context.schema['UUID'])
            ..isReadOnly = true
            ..description = "List of uuid of Personnels mobilized for this operation",
          "messages": APISchemaObject.array(ofSchema: context.schema['Message'])
            ..isReadOnly = true
            ..description = "List of messages added to Operation",
        },
      )
        ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
        // POST only
        ..required = [
          'uuid',
        ];

  APISchemaObject documentTransition() => APISchemaObject.object({
        "status": documentStatus(),
        "resolution": documentOperationResolution(),
        "timestamp": APISchemaObject.string()
          ..description = "When transition occured"
          ..format = 'date-time',
      })
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
      'completed',
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
          "point": documentPoint(context)..description = "Location point",
          "address": documentAddress()..description = "Location address",
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
            ..description = "Pass codes for authorizing access to Operation data",
          "city": APISchemaObject.string()..description = "City name",
          "postalCode": APISchemaObject.string()..description = "Postal, state or zip code",
          "countryCode": APISchemaObject.string()..description = "ISO 3166 country code",
        },
      )
        ..description = "Address Schema (value object)"
        ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed;
}
