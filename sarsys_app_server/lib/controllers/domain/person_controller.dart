import 'package:sarsys_app_server/controllers/event_source/aggregate_controller.dart';
import 'package:sarsys_domain/sarsys_domain.dart' hide Operation;
import 'package:sarsys_app_server/sarsys_app_server.dart';
import 'package:sarsys_app_server/validation/validation.dart';

/// A ResourceController that handles
/// [/api/persons](http://localhost/api/client.html#/Person) requests
class PersonController extends AggregateController<PersonCommand, Person> {
  PersonController(PersonRepository persons, JsonValidation validation)
      : super(persons, validation: validation, tag: 'Persons');

  AffiliationRepository get affiliations => (repository as PersonRepository).affiliations;

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
  Future<Response> create(@Bind.body() Map<String, dynamic> data) async {
    return super.create(data);
  }

  @override
  @Operation('PATCH', 'uuid')
  Future<Response> update(
    @Bind.path('uuid') String uuid,
    @Bind.body() Map<String, dynamic> data,
  ) {
    return super.update(uuid, data..remove('tracking'));
  }

  @override
  @Operation('DELETE', 'uuid')
  Future<Response> delete(
    @Bind.path('uuid') String uuid, {
    @Bind.body() Map<String, dynamic> data,
  }) async {
    final count = affiliations.findPerson(uuid).length;
    final response = await super.delete(uuid, data: data);
    if (count > 0) {
      return await withResponseWaitForRuleResult<AffiliationDeleted>(
        response,
        count: count,
        fail: true,
      );
    }
    return response;
  }

  @override
  PersonCommand onCreate(Map<String, dynamic> data) => CreatePerson(data);

  @override
  PersonCommand onUpdate(Map<String, dynamic> data) => UpdatePersonInformation(data);

  @override
  PersonCommand onDelete(Map<String, dynamic> data) => DeletePerson(data);

  //////////////////////////////////
  // Documentation
  //////////////////////////////////

  @override
  APISchemaObject documentAggregateRoot(APIDocumentContext context) => APISchemaObject.object(
        {
          "uuid": context.schema['UUID']..description = "Unique Person id",
          "fname": APISchemaObject.string()..description = "First name",
          "lname": APISchemaObject.string()..description = "Last name",
          "phone": APISchemaObject.string()..description = "Phone number",
          "email": APISchemaObject.string()..description = "E-mail address",
          "userId": APISchemaObject.string()..description = "Authenticated used id",
          "temporary": APISchemaObject.boolean()..description = "Temporary person",
        },
      )
        ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
        ..required = [
          'uuid',
        ];
}
