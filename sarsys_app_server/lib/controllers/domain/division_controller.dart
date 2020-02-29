import 'package:sarsys_app_server/controllers/event_source/aggregate_controller.dart';
import 'package:sarsys_domain/sarsys_domain.dart';
import 'package:sarsys_app_server/sarsys_app_server.dart';
import 'package:sarsys_app_server/validation/validation.dart';

/// A ResourceController that handles
/// [/api/incidents/{uuid}/Divisions](http://localhost/api/client.html#/Division) requests
class DivisionController extends AggregateController<DivisionCommand, Division> {
  DivisionController(DivisionRepository repository, JsonValidation validation)
      : super(repository, validation: validation, readOnly: const ['organisation'], tag: "Divisions");

  @override
  DivisionCommand onCreate(Map<String, dynamic> data) => CreateDivision(data);

  @override
  DivisionCommand onUpdate(Map<String, dynamic> data) => UpdateDivisionInformation(data);

  @override
  DivisionCommand onDelete(Map<String, dynamic> data) => DeleteDivision(data);

  //////////////////////////////////
  // Documentation
  //////////////////////////////////

  @override
  APISchemaObject documentAggregateRoot(APIDocumentContext context) => APISchemaObject.object({
        "uuid": context.schema['UUID']..description = "Unique division id",
        "organisation": APISchemaObject.object({
          "uuid": context.schema['UUID']..description = "Uuid of organisation which this division belongs to",
        })
          ..isReadOnly = true
          ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed,
        "name": APISchemaObject.string()..description = "Division name",
        "alias": APISchemaObject.string()..description = "Division alias",
        "departments": APISchemaObject.array(
          ofSchema: context.schema['UUID'],
        )..description = "List of unique department uuids",
      })
        ..description = "Division Schema (aggregate root)"
        ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
        ..required = [
          'uuid',
          'name',
        ];
}
