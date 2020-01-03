import 'package:sarsys_app_server/controllers/crud_controller.dart';
import 'package:sarsys_app_server/domain/incident/incident.dart';
import 'package:sarsys_app_server/sarsys_app_server.dart';

/// A ResourceController that handles
/// [/api/app-config](http://localhost/api/client.html#/Incident) [Request]s
class IncidentController extends CRUDController<IncidentCommand, Incident> {
  IncidentController(IncidentRepository repository) : super(repository);

  @override
  IncidentCommand create(Map<String, dynamic> data) => CreateIncident(data);

  @override
  IncidentCommand update(Map<String, dynamic> data) => UpdateIncident(data);

  //////////////////////////////////
  // Documentation
  //////////////////////////////////

  @override
  String documentOperationDescription(APIDocumentContext context, Operation operation) {
    String desc = "${documentOperationSummary(context, operation)}. ";
    switch (operation.method) {
      case "GET":
        desc += operation.pathVariables.isEmpty
            ? "The actual incidents returned by this operation depends on which scope the user have. "
            : "Admins will get all incidents, all other roles will get the incidents based on affiliation.";
        break;
      case "POST":
        desc += "The field [uuid] MUST BE unique for each incident. "
            "Use a [universally unique identifier]"
            "(https://en.wikipedia.org/wiki/Universally_unique_identifier).";
        break;
      case "PATCH":
        desc += "Only fields in request are updated. Existing values WILL BE overwritten, others remain unchanged.";
        break;
    }
    return desc;
  }

  @override
  APISchemaObject documentSchemaObject() => APISchemaObject.object(
        {
          "uuid": APISchemaObject.string(format: 'uuid')
            ..format = 'uuid'
            ..description = "Unique incident id",
          "name": APISchemaObject.boolean()..description = "Name of incident scene",
          "type": APISchemaObject.string()
            ..description = "Incident type"
            ..enumerated = [
              'lost',
              'distress',
              'other',
            ],
          "status": APISchemaObject.string()
            ..description = "Incident status"
            ..enumerated = [
              'registered',
              'handling',
              'closed',
            ],
          "resolution": APISchemaObject.string()
            ..description = "Incident resolution"
            ..enumerated = [
              'cancelled',
              'resolved',
            ],
          "occurred": APISchemaObject.string()
            ..description = "Date and time the incident occurred in ISO8601 Date Time String Format"
            ..format = 'date-time',
          "created": APISchemaObject.string()
            ..description = "Date and time the incident was registered in ISO8601 Date Time String Format"
            ..format = 'date-time',
          "changed": APISchemaObject.string()
            ..description = "Date and time the incident was last changed in ISO8601 Date Time String Format"
            ..format = 'date-time',
          "reference": APISchemaObject.string()..description = "External reference from requesting authority",
          "justification": APISchemaObject.string()..description = "Justification for registering the incident",
        },
      )..required = [
          'uuid',
          'name',
          'type',
          'status',
          'resolution',
          'occured',
          'created',
          'updated',
          'justification',
        ];
}
