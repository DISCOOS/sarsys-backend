import 'package:sarsys_app_server/controllers/eventsource/aggregate_controller.dart';
import 'package:sarsys_app_server/domain/subject/subject.dart';
import 'package:sarsys_app_server/sarsys_app_server.dart';
import 'package:sarsys_app_server/validation/validation.dart';

/// A ResourceController that handles
/// [/api/incidents/{uuid}/subjects](http://localhost/api/client.html#/Subject) requests
class SubjectController extends AggregateController<SubjectCommand, Subject> {
  SubjectController(SubjectRepository repository, JsonValidation validator)
      : super(repository, validator: validator, readOnly: const ['incident'], tag: 'Subjects');

  @override
  SubjectCommand onCreate(Map<String, dynamic> data) => RegisterSubject(data);

  @override
  SubjectCommand onUpdate(Map<String, dynamic> data) => UpdateSubject(data);

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
            "uuid": APISchemaObject.string()
              ..format = 'uuid'
              ..description = "Uuid of incident which this subject is affected by"
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
