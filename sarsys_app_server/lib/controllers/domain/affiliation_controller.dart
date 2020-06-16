import 'package:sarsys_app_server/controllers/domain/schemas.dart';
import 'package:sarsys_app_server/controllers/event_source/aggregate_controller.dart';
import 'package:sarsys_domain/sarsys_domain.dart' hide Operation;
import 'package:sarsys_app_server/sarsys_app_server.dart';
import 'package:sarsys_app_server/validation/validation.dart';

/// A ResourceController that handles
/// [/api/affiliations](http://localhost/api/client.html#/Affiliations) requests
class AffiliationController extends AggregateController<AffiliationCommand, Affiliation> {
  AffiliationController(
    AffiliationRepository affiliations,
    JsonValidation validation,
  ) : super(affiliations, validation: validation, tag: 'Affiliations');

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
  AffiliationCommand onCreate(Map<String, dynamic> data) => CreateAffiliation(data);

  @override
  AffiliationCommand onUpdate(Map<String, dynamic> data) => UpdateAffiliation(data);

  @override
  AffiliationCommand onDelete(Map<String, dynamic> data) => DeleteAffiliation(data);

  //////////////////////////////////
  // Documentation
  //////////////////////////////////

  /// Affiliation - Aggregate root
  @override
  APISchemaObject documentAggregateRoot(APIDocumentContext context) => APISchemaObject.object({
        "uuid": context.schema['UUID']..description = "Unique Affiliation id",
        "person": documentAggregateRef(
          context,
          description: "Person reference for PII lookup",
          defaultType: 'Person',
        ),
        "org": documentAggregateRef(
          context,
          description: "Organisation which personnel is affiliated with",
          defaultType: 'Organisation',
        ),
        "div": documentAggregateRef(
          context,
          description: "Division which personnel is affiliated with",
          defaultType: 'Division',
        ),
        "dep": documentAggregateRef(
          context,
          description: "Department which personnel is affiliated with",
          defaultType: 'Department',
        ),
        "type": documentAffiliationType(),
        "standby": documentAffiliationStandbyStatus(),
        "active": APISchemaObject.boolean()..description = "Affiliation status flag"
      })
        ..isReadOnly = true
        ..description = "Affiliation information"
        ..required = ['person', 'org']
        ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed;

  @override
  Map<String, APISchemaObject> documentValues(APIDocumentContext context) => {
        "AffiliationType": documentAffiliationType(),
        "AffiliationStandbyStatus": documentAffiliationType(),
      };

  APISchemaObject documentAffiliationType() => APISchemaObject.string()
    ..description = "Affiliation type"
    ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
    ..defaultValue = "member"
    ..enumerated = [
      'member',
      'employee',
      'external',
      'volunteer',
    ];

  APISchemaObject documentAffiliationStandbyStatus() => APISchemaObject.string()
    ..description = "Personnel standby status"
    ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
    ..defaultValue = "available"
    ..enumerated = [
      'available',
      'shortnotice',
      'unavailable',
    ];
}
