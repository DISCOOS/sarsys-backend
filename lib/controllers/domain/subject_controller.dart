import 'package:sarsys_app_server/controllers/aggregate_controller.dart';
import 'package:sarsys_app_server/domain/subject/subject.dart';
import 'package:sarsys_app_server/sarsys_app_server.dart';
import 'package:sarsys_app_server/validation/validation.dart';

/// A ResourceController that handles
/// [/api/incidents/{uuid}/subjects](http://localhost/api/client.html#/Subject) requests
class SubjectController extends AggregateController<SubjectCommand, Subject> {
  SubjectController(SubjectRepository repository, RequestValidator validator) : super(repository, validator: validator);

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
          "uuid": APISchemaObject.string()
            ..format = 'uuid'
            ..description = "Unique Subject id",
          // TODO: Subject - replace name with reference to PII
          "name": APISchemaObject.string()..description = "Subject name",
          "situation": APISchemaObject.string()..description = "Subject situation",
          "type": APISchemaObject.string()
            ..description = "Subject type"
            ..enumerated = [
              'person',
              'vehicle',
              'other',
            ],
          "location": context.schema['Location']..description = "Rescue or assitance location",
        },
      )
        ..description = "Objective Schema"
        ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
        ..required = [
          'name',
          'type',
          'situation',
          'location',
        ];
}
