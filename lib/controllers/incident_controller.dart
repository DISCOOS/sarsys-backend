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

  static const passCodesDescription = "User with admin role will get all incidents containing "
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
          "talkGroups": APISchemaObject.array(ofSchema: context.schema['TalkGroup'])
            ..description = "List of talk gropus in used",
          "ipp": context.schema['Location']..description = "Initial planning point",
          "meetup": context.schema['Location']..description = "On scene meeting point",
        },
      )..required = [
          'uuid',
          'name',
          'type',
          'status',
          'occured',
          'created',
          'updated',
          'justification',
          'ipp',
          'meetup',
        ];

  @override
  Map<String, APISchemaObject> documentEntities(APIDocumentContext context) => {
        "TalkGroup": documentTalkGroup(),
        "Location": documentLocation(context),
        "Point": documentPoint(),
        "Address": documentAddress(),
        "PassCodes": documentPassCodes(),
      };

  APISchemaObject documentTalkGroup() => APISchemaObject.object(
        {
          "name": APISchemaObject.boolean()..description = "Talkgroup identifier",
          "type": APISchemaObject.string()
            ..description = "Talkgroup type"
            ..enumerated = [
              'tetra',
              'marine',
              'analog',
            ],
        },
      )
        ..description = "TalkGroup Schema"
        ..required = [
          'name',
          'type',
        ];

  APISchemaObject documentLocation(APIDocumentContext context) => APISchemaObject.object(
        {
          "point": APISchemaObject.array(ofSchema: context.schema['Point'])..description = "Location position",
          "address": APISchemaObject.array(ofSchema: context.schema['Address'])..description = "Location address",
          "description": APISchemaObject.string()..description = "Location description",
        },
      )
        ..description = "Location Schema"
        ..required = [
          'point',
        ];

  APISchemaObject documentPoint() => APISchemaObject.object(
        {
          "lat": APISchemaObject.number()..description = "Latitude in decimal degrees",
          "lon": APISchemaObject.number()..description = "Longitude in decimal degrees",
          "alt": APISchemaObject.number()..description = "Altitude above sea level in meters",
          "acc": APISchemaObject.number()..description = "Accuracy in meters",
          "timestamp": APISchemaObject.string()
            ..description = "Timestamp in ISO8601 Date Time String Format"
            ..format = "date-time",
          "type": APISchemaObject.string()
            ..description = "Point type"
            ..enumerated = [
              'manual',
              'device',
              'personnel',
              'aggregated',
            ],
        },
      )
        ..description = "Point Schema"
        ..required = [
          'lat',
          'lon',
          'timestamp',
        ];

  APISchemaObject documentAddress() => APISchemaObject.object(
        {
          "lines": APISchemaObject.array(ofType: APIType.string)
            ..description = "Pass codes for authorizing access to incident data"
            ..type = APIType.string,
          "city": APISchemaObject.string()..description = "City name",
          "postalCode": APISchemaObject.string()..description = "Postal, state or zip code",
          "countryCode": APISchemaObject.string()..description = "ISO 3166 country code",
        },
      )
        ..description = "Point Schema"
        ..required = [
          'lat',
          'lon',
          'timestamp',
        ];

  // TODO: Use https://pub.dev/packages/password to hash pass codes in streams?
  APISchemaObject documentPassCodes() => APISchemaObject.object(
        {
          "commander": APISchemaObject.string()..description = "Passcode for access with Commander rights",
          "personnel": APISchemaObject.string()..description = "Passcode for access with Personnel rights",
        },
      )
        ..description = "Pass codes for access rights to spesific Incident instance"
        ..required = [
          'commander',
          'personnel',
        ];
}
