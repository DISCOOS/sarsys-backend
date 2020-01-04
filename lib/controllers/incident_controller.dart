import 'package:sarsys_app_server/controllers/crud_controller.dart';
import 'package:sarsys_app_server/domain/incident/aggregate.dart';
import 'package:sarsys_app_server/domain/incident/commands.dart';
import 'package:sarsys_app_server/domain/incident/repository.dart';
import 'package:sarsys_app_server/sarsys_app_server.dart';

/// A ResourceController that handles
/// [/api/app-config](http://localhost/api/client.html#/Incident) requests
class IncidentController extends CRUDController<IncidentCommand, Incident> {
  IncidentController(IncidentRepository repository) : super(repository);

  @override
  IncidentCommand create(Map<String, dynamic> data) => CreateIncident(data);

  @override
  IncidentCommand update(Map<String, dynamic> data) => UpdateIncident(data);

  //////////////////////////////////
  // Documentation
  //////////////////////////////////

  static const passCodesDescription = "Users with an admin role will get all incidents containing "
      "all available fields. All other roles will get incidents based on affiliation. "
      "Which fields each incident contains is based on given passcode. All available fields are "
      "only returned for incidents  with passcode which match the value given in header 'X-Passcode'. "
      "Rquests without header 'X-Passcode', or with an invalid passcode, will get incidents containing "
      "fields [uuid] and [name] only. Brute-force attacks are banned for a lmitied time without any "
      "feedback. When banned, all incidents will contain fields [uuid] and [name] only, regardless of "
      "the value in 'X-Passcode'.";

  @override
  String documentOperationDescription(APIDocumentContext context, Operation operation) {
    String desc = "${documentOperationSummary(context, operation)}. ";
    switch (operation.method) {
      case "GET":
        desc = "$desc $passCodesDescription";
        break;
    }
    return desc;
  }

  @override
  APISchemaObject documentAggregate(APIDocumentContext context) => APISchemaObject.object(
        {
          "uuid": APISchemaObject.string(format: 'uuid')
            ..format = 'uuid'
            ..description = "Unique incident id",
          "name": APISchemaObject.string()..description = "Name of incident scene",
          "summary": APISchemaObject.string()..description = "Situation summary",
          "type": APISchemaObject.string()
            ..description = "Incident type"
            ..enumerated = [
              'lost',
              'distress',
              'disaster',
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
              'unresolved',
              'cancelled',
              'duplicate',
              'resolved',
            ],
          "occurred": APISchemaObject.string()
            ..description = "Timestamp the incident occurred in ISO8601 Date Time String Format"
            ..format = 'date-time',
          "created": APISchemaObject.string()
            ..description = "Timestamp the the incident was registered in ISO8601 Date Time String Format"
            ..format = 'date-time',
          "changed": APISchemaObject.string()
            ..description = "Timestamp when the incident was last changed in ISO8601 Date Time String Format"
            ..format = 'date-time',
          "clues": APISchemaObject.array(ofSchema: context.schema['Clue'])
            ..description = "List of Clues for planning and response",
          "subjects": APISchemaObject.array(ofSchema: context.schema['Subject'])
            ..description = "List of Subjects involved in the incident",
          "passcodes": context.schema['PassCodes']..description = "Passcodes for Incident access rights",
        },
      )..required = [
          'uuid',
          'name',
          'summary',
          'type',
          'status',
          'resolution',
          'occured',
          'created',
          'updated',
        ];

  @override
  Map<String, APISchemaObject> documentEntities(APIDocumentContext context) => {
        "Clue": documentClue(context),
        "Subject": documentSubject(context),
      };

  APISchemaObject documentSubject(APIDocumentContext context) => APISchemaObject.object(
        {
          "name": APISchemaObject.string()..description = "Subject name",
          "situation": APISchemaObject.string()..description = "Subject situation",
          "type": APISchemaObject.string()
            ..description = "Subject type"
            ..enumerated = [
              'person',
              'vehicle',
              'other',
            ],
          "quality": APISchemaObject.string()
            ..description = "Clue quality assessment"
            ..enumerated = [
              'confirmed',
              'plausable',
              'possible',
              'unlikely',
              'rejected',
            ],
          "location": context.schema['Location']..description = "Rescue or assitance location",
        },
      )
        ..description = "Objective Schema"
        ..required = [
          'name',
          'type',
          'situation',
          'quality',
        ];

  APISchemaObject documentClue(APIDocumentContext context) => APISchemaObject.object(
        {
          "name": APISchemaObject.array(ofSchema: context.schema['Point'])..description = "Clue name",
          "description": APISchemaObject.string()..description = "Clue description",
          "type": APISchemaObject.string()
            ..description = "Clue type"
            ..enumerated = [
              'find',
              'condition',
              'observation',
              'circumstance',
            ],
          "quality": APISchemaObject.string()
            ..description = "Clue quality assessment"
            ..enumerated = [
              'confirmed',
              'plausable',
              'possible',
              'unlikely',
              'rejected',
            ],
          "location": APISchemaObject.array(ofSchema: context.schema['Location'])
            ..description = "Rescue or assitance location",
        },
      )
        ..description = "Objective Schema"
        ..required = [
          'name',
          'type',
          'quality',
        ];
}
