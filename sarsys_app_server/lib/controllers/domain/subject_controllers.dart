import 'package:sarsys_domain/sarsys_domain.dart' hide Operation;
import 'package:sarsys_app_server/sarsys_app_server.dart';

/// A ResourceController that handles
/// [/api/incidents/{uuid}/subjects](http://localhost/api/client.html#/Subject) requests
class SubjectController extends AggregateController<SubjectCommand, Subject> {
  SubjectController(SubjectRepository repository, JsonValidation validation)
      : super(repository, validation: validation, readOnly: const ['incident'], tag: 'Subjects');

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
    return await withResponseWaitForRuleResult<SubjectRemovedFromIncident>(
      await super.delete(uuid, data: data),
    );
  }

  @override
  SubjectCommand onCreate(Map<String, dynamic> data) => RegisterSubject(data);

  @override
  Iterable<SubjectCommand> onUpdate(Map<String, dynamic> data) => [
        UpdateSubject(data),
      ];

  @override
  SubjectCommand onDelete(Map<String, dynamic> data) => DeleteSubject(data);

  //////////////////////////////////
  // Documentation
  //////////////////////////////////

  @override
  APISchemaObject documentAggregateRoot(APIDocumentContext context) => APISchemaObject.object(
        {
          "uuid": context.schema['UUID']..description = "Unique subject id",
          "incident": APISchemaObject.object({
            "uuid": APISchemaObject.string()..description = "UUID of incident which this subject is affected by",
          })
            ..isReadOnly = true
            ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed,
          // TODO: Subject - replace name with reference to PII
          "name": APISchemaObject.string()..description = "Subject name",
          "situation": APISchemaObject.string()..description = "Subject situation",
          "type": documentType(),
          "location": context.schema['Location']..description = "Rescue or assitance location",
        },
      )
        ..description = "Objective Schema"
        ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
        ..required = [
          'uuid',
          'name',
          'type',
          'situation',
          'location',
        ];

  APISchemaObject documentType() => APISchemaObject.string()
    ..description = "Subject type"
    ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
    ..enumerated = [
      'person',
      'vehicle',
      'other',
    ];
}
