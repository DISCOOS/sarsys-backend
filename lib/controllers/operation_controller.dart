import 'package:sarsys_app_server/domain/operation/repository.dart';

import '../controllers/crud_controller.dart';
import '../domain/operation/operation.dart' as sar;
import '../sarsys_app_server.dart';

/// A ResourceController that handles
/// [/api/app-config](http://localhost/api/client.html#/Operation) requests
class OperationController extends CRUDController<sar.OperationCommand, sar.Operation> {
  OperationController(OperationRepository repository) : super(repository);

  @override
  sar.OperationCommand create(Map<String, dynamic> data) => sar.CreateOperation(data);

  @override
  sar.OperationCommand update(Map<String, dynamic> data) => sar.UpdateOperation(data);

  //////////////////////////////////
  // Documentation
  //////////////////////////////////

  static const passCodesDescription = "Users with an admin role are allowed to get all operations. "
      "All other roles will get access to operations based on given passcodes. All available fields are "
      "only returned for operations with passcode which match the value given in header 'X-Passcode'. "
      "Rquests without header 'X-Passcode', or with an invalid passcode, will get operations containing "
      "fields [uuid] and [name] only. Brute-force attacks are banned for a lmitied time without any "
      "feedback. When banned, all operations will contain fields [uuid] and [name] only, regardless of "
      "the value in 'X-Passcode'.";

  @override
  String documentOperationDescription(APIDocumentContext context, Operation operation) {
    String desc = "${documentOperationSummary(context, operation)}. ";
    switch (operation.method) {
      case "GET":
        switch (operation.method) {
          case "GET":
            desc = "$desc $passCodesDescription";
            break;
        }
        return desc;

        break;
    }
    return desc;
  }

  @override
  APISchemaObject documentAggregate(APIDocumentContext context) => APISchemaObject.object(
        {
          "uuid": APISchemaObject.string(format: 'uuid')
            ..format = 'uuid'
            ..description = "Unique Operation id",
          "name": APISchemaObject.string()..description = "Name of operation scene",
          "type": APISchemaObject.string()
            ..description = "Operation type"
            ..enumerated = [
              'search',
              'rescue',
              'other',
            ],
          "incident": APISchemaObject.string()
            ..format = 'incident'
            ..description = "Unique incident id (required)",
          "status": APISchemaObject.string()
            ..description = "Operation status"
            ..enumerated = [
              'responded',
              'finished',
            ],
          "resolution": APISchemaObject.string()
            ..description = "Operation resolution"
            ..enumerated = [
              'unresolved',
              'cancelled',
              'resolved',
            ],
          "responded": APISchemaObject.string()
            ..description = "Timestamp when response occured in ISO8601 Date Time String Format"
            ..format = 'date-time',
          "onscene": APISchemaObject.string()
            ..description = "Timestamp when first responder was on scene in ISO8601 Date Time String Format"
            ..format = 'date-time',
          "finished": APISchemaObject.string()
            ..description = "Timestamp when Operation was finisehd in ISO8601 Date Time String Format"
            ..format = 'date-time',
          "reference": APISchemaObject.string()..description = "External reference from requesting authority",
          "justification": APISchemaObject.string()..description = "Justification for responding",
          "talkGroups": APISchemaObject.array(ofSchema: context.schema['TalkGroup'])
            ..description = "List of talk gropus in use",
          "ipp": context.schema['Location']..description = "Initial planning point",
          "meetup": context.schema['Location']..description = "On scene meeting point",
          "objectives": APISchemaObject.array(ofSchema: context.schema['Objective'])
            ..description = "List of Operation objectives",
          "passcodes": context.schema['PassCodes']..description = "Passcodes for Operation access rights",
        },
      )..required = [
          'uuid',
          'name',
          'type',
          'status',
          'responded',
          'onscene',
          'finished',
          'justification',
          'ipp',
          'meetup',
        ];

  @override
  Map<String, APISchemaObject> documentEntities(APIDocumentContext context) => {
        "Objective": documentObjective(context),
        "Location": documentLocation(context),
        "TalkGroup": documentTalkGroup(),
        "Point": documentPoint(),
        "Address": documentAddress(),
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

  APISchemaObject documentObjective(APIDocumentContext context) => APISchemaObject.object(
        {
          "name": APISchemaObject.array(ofSchema: context.schema['Point'])..description = "Objective name",
          "description": APISchemaObject.string()..description = "Objective description",
          "type": APISchemaObject.string()
            ..description = "Objective type"
            ..enumerated = [
              'locate',
              'rescue',
              'assist',
            ],
          "location": APISchemaObject.array(ofSchema: context.schema['Location'])
            ..description = "Rescue or assitance location",
          "resolution": APISchemaObject.string()
            ..description = "Objective resolution"
            ..enumerated = [
              'unresolved',
              'cancelled',
              'resolved',
            ],
        },
      )
        ..description = "Objective Schema"
        ..required = [
          'name',
          'type',
          'resolution',
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
            ..description = "Pass codes for authorizing access to Operation data"
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
}
